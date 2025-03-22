import json
from firebase_functions import https_fn
from firebase_admin import initialize_app
import vertexai
from vertexai.generative_models import GenerativeModel

initialize_app()

# Vertex AI の設定 (自分のプロジェクトに合わせて変更)
PROJECT_ID = "a-la-carte-suggestions"  # プロジェクトID
LOCATION = "us-central1"  # リージョン (Cloud Functions と合わせる)
MODEL_NAME = "gemini-1.5-pro-002"  # 使用するモデル (必要に応じて変更)


@https_fn.on_request()
def process_text_and_organize(req: https_fn.Request) -> https_fn.Response:
    """Flutter Web アプリからのテキスト入力を処理し、食材リストを生成する."""

    # CORS 設定 (すべてのオリジンからのリクエストを許可する場合)
    if req.method == "OPTIONS":
        # preflight request (OPTIONS) への応答
        headers = {
            'Access-Control-Allow-Origin': '*',  # または、許可する特定のオリジン
            'Access-Control-Allow-Methods': 'POST',  # 許可するメソッド
            'Access-Control-Allow-Headers': 'Content-Type',  # 許可するヘッダー
            'Access-Control-Max-Age': '3600'  # preflight request の結果をキャッシュする時間 (秒)
        }
        return https_fn.Response("", status=204, headers=headers)

    try:
        if req.method != 'POST':
            return https_fn.Response("Method Not Allowed", status=405)
        if not req.json or 'text' not in req.json:
            return https_fn.Response("Missing text data", status=400)

        text = req.json['text']  # 音声認識済みのテキスト

        # Vertex AI (Gemini) でテキストを整理
        vertexai.init(project=PROJECT_ID, location=LOCATION)
        model = GenerativeModel(MODEL_NAME)

        prompt = f"""
        以下のテキストから食材とその個数を抽出し、以下の形式のJSONリストにしてください。
        食材以外の情報は無視してください。
        一般的な冷蔵庫での保管を前提として、消費/賞味期限を推測して付記してください。
        また、出力形式は以下に示すJsonの形式とし、これ以外の形で出力することは認めません。
        
        出力形式 (JSON):
        ```json
        [
          {{
            "食材": "食材名",
            "個数": "個数",
            "消費/賞味期限": "YYYY/MM/DD (〇日後)"
          }},
          {{
            "食材": "食材名",
            "個数": "個数",
            "消費/賞味期限": "YYYY/MM/DD (〇日後)"
          }},
          ...
        ]
        ```

        入力テキスト:
        {text}
        """

        response = model.generate_content(
            prompt,
            generation_config={
                "temperature": 0.2,
                "top_p": 0.8,
                "top_k": 40,
                "max_output_tokens": 2048,
            }
        )

        # Vertex AI からのレスポンスを整形
        try:
            # 不要な `json と ` を削除し、JSON としてパース
            response_text = response.text.replace("`json", "").replace("`", "").strip()
            organized_list = json.loads(response_text)

        except json.JSONDecodeError:
            print(f"Error: Vertex AI returned invalid JSON: {response.text}")
            return https_fn.Response(
                {"error": "Invalid JSON format from Vertex AI", "details": response.text},
                status=500,
                content_type='application/json'
            )

        # 通常のリクエスト (POST) への CORS ヘッダーを追加
        headers = {
            'Access-Control-Allow-Origin': '*'  # または、許可する特定のオリジン
        }
        return https_fn.Response(
            json.dumps(organized_list, ensure_ascii=False),
            status=200,
            content_type='application/json',
            headers=headers
        )

    except Exception as e:
        print(f"Error: {e}")
        return https_fn.Response(
            {"error": "An error occurred", "details": str(e)},
            status=500,
            content_type='application/json'
        )