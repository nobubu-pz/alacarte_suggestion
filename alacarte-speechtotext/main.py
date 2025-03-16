from firebase_functions import https_fn
from firebase_admin import initialize_app
from google.cloud import speech_v1 as speech # v1を明示的に指定

initialize_app()

@https_fn.on_request()
def transcribe_audio(req: https_fn.Request) -> https_fn.Response:
    try:
        # 1. リクエストの検証 (オプション)
        if req.method != 'POST':
            return https_fn.Response("Method Not Allowed", status=405)
        if not req.json or 'audioBytes' not in req.json:
            return https_fn.Response("Missing audio data", status=400)

        # 2. リクエストボディから音声データ (Base64エンコード) を取得
        audio_bytes = req.json['audioBytes']

        # 3. Speech-to-Text APIへのリクエスト設定
        client = speech.SpeechClient()
        audio = speech.RecognitionAudio(content=audio_bytes)
        config = speech.RecognitionConfig(
            encoding=speech.RecognitionConfig.AudioEncoding.LINEAR16,
            sample_rate_hertz=16000,
            language_code='ja-JP',  # または他の言語コード
            # 他のオプション: https://cloud.google.com/speech-to-text/docs/reference/rest/v1/RecognitionConfig
        )

        # 4. Speech-to-Text API呼び出し
        response = client.recognize(config=config, audio=audio)

        # 5. レスポンスの処理 (テキスト抽出)
        transcription = ""
        for result in response.results:
            transcription += result.alternatives[0].transcript + "\n"

        # 6. クライアントへのレスポンス
        return https_fn.Response(
            {"transcription": transcription},
            status=200,
            content_type='application/json'
        )

    except Exception as e:
        print(f"Error transcribing audio: {e}")  # エラーログ
        return https_fn.Response(
            {"error": "Failed to transcribe audio", "details": str(e)},
            status=500,
            content_type='application/json'
        )