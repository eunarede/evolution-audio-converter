# Evolution Audio Converter

This project is a microservice in Go that processes audio files, converts them to **opus** or **mp3** format, and returns both the duration of the audio and the converted file (as base64 or S3 URL). The service accepts audio files sent as **form-data**, **base64**, or **URL**.

## Requirements

Before starting, you'll need to have the following installed:

- [Go](https://golang.org/doc/install) (version 1.21 or higher)
- [Docker](https://docs.docker.com/get-docker/) (to run the project in a container)
- [FFmpeg](https://ffmpeg.org/download.html) (for audio processing)

## Installation

### Clone the Repository

Clone this repository to your local machine:

```bash
git clone https://github.com/EvolutionAPI/evolution-audio-converter.git
cd evolution-audio-converter
```

### Install Dependencies

Install the project dependencies:

```bash
go mod tidy
```

### Install FFmpeg

The service depends on **FFmpeg** to convert the audio. Make sure FFmpeg is installed on your system.

- On Ubuntu:

  ```bash
  sudo apt update
  sudo apt install ffmpeg
  ```

- On macOS (via Homebrew):

  ```bash
  brew install ffmpeg
  ```

- On Windows, download FFmpeg [here](https://ffmpeg.org/download.html) and add it to your system `PATH`.

### Configuration

Create a `.env` file in the project's root directory. Here are the available configuration options:

#### Basic Configuration

```env
PORT=4040
API_KEY=your_secret_api_key_here
```

#### Transcription Configuration

```env
ENABLE_TRANSCRIPTION=true
TRANSCRIPTION_PROVIDER=openai  # or groq
OPENAI_API_KEY=your_openai_key_here
GROQ_API_KEY=your_groq_key_here
TRANSCRIPTION_LANGUAGE=en  # Default transcription language (optional)
```

#### Storage Configuration

```env
ENABLE_S3_STORAGE=true
S3_ENDPOINT=play.min.io
S3_ACCESS_KEY=your_access_key_here
S3_SECRET_KEY=your_secret_key_here
S3_BUCKET_NAME=audio-files
S3_REGION=us-east-1
S3_USE_SSL=true
S3_URL_EXPIRATION=24h
```

### Storage Options

The service supports two storage modes for the converted audio:

1. **Base64 (default)**: Returns the audio file encoded in base64 format
2. **S3 Compatible Storage**: Uploads to S3-compatible storage (AWS S3, MinIO, etc.) and returns a presigned URL

When S3 storage is enabled, the response will include a `url` instead of the `audio` field:

```json
{
  "duration": 120,
  "format": "ogg",
  "url": "https://your-s3-endpoint/bucket/file.ogg?signature...",
  "transcription": "Transcribed text here..." // if transcription was requested
}
```

If S3 upload fails, the service automatically falls back to base64 encoding.

## Transcription Providers

The service supports multiple transcription providers:

### OpenAI Whisper
- **Provider**: `openai`
- **Model**: `whisper-1`
- **Requirements**: `OPENAI_API_KEY`
- **Custom URL**: Support for proxies via `OPENAI_API_URL`

### Groq
- **Provider**: `groq`
- **Model**: `whisper-large-v3-turbo`
- **Requirements**: `GROQ_API_KEY`
- **Features**: Fast and cost-effective

### Cloudflare AI Gateway
- **Provider**: `cloudflare`
- **Model**: `@cf/openai/whisper`
- **Requirements**: `CLOUDFLARE_API_KEY`
- **Optional**: `CLOUDFLARE_API_URL` for AI Gateway, `CLOUDFLARE_ACCOUNT_ID` for direct Workers AI
- **Features**: 
  - Serverless transcription
  - No file size limits
  - Direct binary audio input
  - Cost: $0.00045 per audio minute
  - Support for AI Gateway with caching, analytics, and rate limiting
  - **Rich response data**: text, word count, word-level timestamps, VTT subtitles

#### Cloudflare Setup Options:

**Option 1: Direct Workers AI** (Simpler)
```env
CLOUDFLARE_API_KEY=your_token_here
CLOUDFLARE_ACCOUNT_ID=your_account_id_here
# CLOUDFLARE_API_URL will be auto-generated
```

**Option 2: AI Gateway** (Advanced - with caching, analytics)
```env
CLOUDFLARE_API_KEY=your_token_here
CLOUDFLARE_API_URL=https://gateway.ai.cloudflare.com/v1/{account_id}/{gateway_slug}/workers-ai
```

To use Cloudflare AI Gateway:
1. Sign up for a [Cloudflare account](https://dash.cloudflare.com/sign-up/workers-and-pages)
2. Go to AI > Workers AI in the dashboard
3. Create a Workers AI API Token
4. (Optional) Set up AI Gateway for caching and analytics
5. Set `TRANSCRIPTION_PROVIDER=cloudflare` in your environment

## Running the Project

### Locally

To run the service locally:

```bash
go run main.go -dev
```

The server will be available at `http://localhost:4040`.

### Using Docker

1. **Build the Docker image**:

   ```bash
   docker build -t audio-service .
   ```

2. **Run the container**:

   ```bash
   docker run -p 4040:4040 --env-file=.env audio-service
   ```

### Using Dokploy with Nixpacks

This project is configured to work with [Dokploy](https://dokploy.com/) using Nixpacks for automatic deployment.

#### Requirements

The project includes a `nixpacks.toml` configuration file that automatically installs FFmpeg during the build process.

#### Environment Variables

Configure the following environment variables in your Dokploy deployment:

```env
# Required
API_KEY=your_secret_api_key_here

# Optional
PORT=4040
CORS_ALLOW_ORIGINS=*

# Transcription (optional)
ENABLE_TRANSCRIPTION=true
TRANSCRIPTION_PROVIDER=openai  # openai, groq, or cloudflare
OPENAI_API_KEY=your_openai_key_here
OPENAI_API_URL=https://api.openai.com  # Use custom proxy like LiteLLM
GROQ_API_KEY=your_groq_key_here
CLOUDFLARE_API_KEY=your_cloudflare_api_key_here
CLOUDFLARE_ACCOUNT_ID=your_cloudflare_account_id_here  # For direct Workers AI
CLOUDFLARE_API_URL=https://gateway.ai.cloudflare.com/v1/{account_id}/{gateway_slug}/workers-ai  # For AI Gateway
TRANSCRIPTION_LANGUAGE=en

# S3 Storage (optional)
ENABLE_S3_STORAGE=true
S3_ENDPOINT=your_s3_endpoint
S3_ACCESS_KEY=your_access_key
S3_SECRET_KEY=your_secret_key
S3_BUCKET_NAME=audio-files
S3_REGION=us-east-1
S3_USE_SSL=true
S3_URL_EXPIRATION=24h
```

#### Deployment Steps

1. Connect your Git repository to Dokploy
2. Select "Nixpacks" as the build provider (or "Docker" for maximum compatibility)
3. Configure the environment variables above
4. Deploy the application

**Note**: If you encounter FFmpeg-related errors with Nixpacks, switch to Docker build provider for better compatibility. See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for more details.

The `nixpacks.toml` file ensures that FFmpeg is installed automatically during the build process.

## API Usage

### Authentication

All requests must include the `apikey` header with your API key.

### Endpoints

#### Process Audio

`POST /process-audio`

Accepts audio files in these formats:

- Form-data
- Base64
- URL

Optional parameters:

- `format`: Output format (`mp3` or `ogg`, default: `ogg`)
- `transcribe`: Enable transcription (`true` or `false`)
- `language`: Transcription language code (e.g., "en", "es", "pt")

#### Transcribe Only

`POST /transcribe`

Transcribes audio without format conversion.

Optional parameters:

- `language`: Transcription language code

### Example Requests

#### Form-data Upload

```bash
curl -X POST -F "file=@audio.mp3" \
  -F "format=ogg" \
  -F "transcribe=true" \
  -F "language=en" \
  http://localhost:4040/process-audio \
  -H "apikey: your_secret_api_key_here"
```

#### Base64 Upload

```bash
curl -X POST \
  -d "base64=$(base64 audio.mp3)" \
  -d "format=ogg" \
  http://localhost:4040/process-audio \
  -H "apikey: your_secret_api_key_here"
```

#### URL Upload

```bash
curl -X POST \
  -d "url=https://example.com/audio.mp3" \
  -d "format=ogg" \
  http://localhost:4040/process-audio \
  -H "apikey: your_secret_api_key_here"
```

### Response Format

#### Audio Processing Response

With S3 storage disabled (default):

```json
{
  "duration": 120,
  "audio": "UklGR... (base64 of the file)",
  "format": "ogg",
  "transcription": {
    "text": "Transcribed text here...",
    "provider": "cloudflare",
    "word_count": 25,
    "words": [
      {
        "word": "Hello",
        "start": 0.0,
        "end": 0.5
      },
      {
        "word": "world",
        "start": 0.6,
        "end": 1.0
      }
    ],
    "vtt": "WEBVTT\n\n00:00.000 --> 00:01.000\nHello world"
  }
}
```

With S3 storage enabled:

```json
{
  "duration": 120,
  "url": "https://your-s3-endpoint/bucket/file.ogg?signature...",
  "format": "ogg",
  "transcription": {
    "text": "Transcribed text here...",
    "provider": "cloudflare"
  }
}
```

#### Transcription-Only Response (`/transcribe` endpoint)

When using Cloudflare provider, returns complete transcription data:

```json
{
  "text": "Hello world, this is a test recording.",
  "provider": "cloudflare", 
  "word_count": 8,
  "words": [
    {
      "word": "Hello",
      "start": 0.0,
      "end": 0.5
    },
    {
      "word": "world",
      "start": 0.6,
      "end": 1.0
    }
  ],
  "vtt": "WEBVTT\n\n00:00.000 --> 00:00.500\nHello\n\n00:00.600 --> 00:01.000\nworld"
}
```

**Transcription Response Fields:**
- `text` (string): The complete transcribed text
- `provider` (string): Which provider was used (openai, groq, cloudflare)
- `word_count` (number): Total number of words (Cloudflare only)
- `words` (array): Word-level timestamps (Cloudflare only)
  - `word` (string): Individual word
  - `start` (number): Start time in seconds
  - `end` (number): End time in seconds
- `vtt` (string): WebVTT subtitle format (Cloudflare only)
  "format": "ogg",
  "transcription": "Transcribed text here..." // if requested
}
```

## License

This project is licensed under the [MIT](LICENSE) license.
