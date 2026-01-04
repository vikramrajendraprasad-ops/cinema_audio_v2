# Cinema Audio V2

A Flutter app for cinematic audio DSP conversion using native FFmpeg. Select an audio file, convert to WAV for editing, or apply a bass boost EQ for theater-like enhancement.

## Features
- Pick audio files (MP3, AAC, etc.).
- **Convert to WAV**: Resample to 44.1kHz stereo.
- **Cinema Bass Boost**: Dual EQ filter (+8dB@80Hz, +4dB@200Hz) for immersive sound.
- Outputs saved to app documents folder.

## Screenshots
*(Add via GitHub mobile: Upload app screenshots here)*

## Getting Started

### Local Development (on Mobile via Termux)
1. Install Flutter: `curl -fsSL https://raw.githubusercontent.com/bdloser404/Fluttermux/main/fluttermux | bash -s`
2. Clone repo: `git clone <your-url>`
3. `cd cinema-audio-v2 && flutter pub get`
4. Run: `flutter run` (enable USB debugging).

### Build APK Locally

Install: Copy `build/app/outputs/flutter-apk/app-release.apk` to Downloads and install.

### GitHub Actions Build
- On push/PR to `main`: Builds release APK automatically.
- Download from Actions tab > Artifacts > `app-release.apk`.

## Workflow
See `.github/workflows/ci.yml` for CI setup.

## Dependencies
- `ffmpeg_kit_flutter_new_audio`: Native audio processing.
- `file_picker`, `path_provider`: File handling.

## License
MIT – Feel free to fork!

*(Built on Jan 4, 2026)*
