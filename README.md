# Dialogue Video Generator

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
![Shell Script](https://img.shields.io/badge/Shell-Bash-4EAA25?logo=gnubash&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-macOS-lightgrey?logo=apple)
![VOICEVOX](https://img.shields.io/badge/VOICEVOX-Engine-00A6D6)
![FFmpeg](https://img.shields.io/badge/FFmpeg-required-007808?logo=ffmpeg&logoColor=white)
![ImageMagick](https://img.shields.io/badge/ImageMagick-required-000000)

Bash script for generating narrated dialogue videos from a text script, VOICEVOX audio, character images, backgrounds, and subtitles.

This repository includes only the automation script and sample text files. It does not include character images, background images, BGM, generated audio, or generated videos.

## Requirements

macOS with Homebrew:

```bash
brew install ffmpeg ghostscript imagemagick jq
```

VOICEVOX ENGINE is required when `AUDIO_INPUT_MODE=voicevox`.

```bash
curl http://127.0.0.1:50021/version
```

## Directory Layout

Prepare your assets like this:

```text
.
├── generate_video.sh
├── script.txt
├── board_script.txt
├── backgrounds/
│   └── background.png
├── images/
│   ├── speaker-a/
│   │   └── 001.png
│   └── speaker-b/
│       └── 001.png
└── mp4/
    └── bgm.m4a
```

`mp4/bgm.m4a` is optional. Set `BGM_AUDIO_FILE` when you want to mix BGM.

## Script Format

Each dialogue line is:

```text
Speaker A|Hello.
Speaker B|Hi. Let's make a video.
```

You can provide a separate subtitle pronunciation by adding a third field:

```text
Speaker A|This text is sent to VOICEVOX.|This text appears in the subtitle.
```

## Board Text Format

`board_script.txt` can show board text for ranges of dialogue line numbers:

```text
[1-2]
Today's Topic
-------------
Generate a dialogue video
```

Disable board rendering with:

```bash
BOARD_ENABLED=0 ./generate_video.sh
```

## Usage

```bash
chmod +x generate_video.sh
cp examples/script.txt script.txt
cp examples/board_script.txt board_script.txt
./generate_video.sh
```

Use a script file directly:

```bash
BOARD_SCRIPT_FILE=examples/board_script.txt ./generate_video.sh examples/script.txt
```

Set an output filename:

```bash
OUTPUT_FILE=lesson.mp4 ./generate_video.sh
```

Use BGM:

```bash
BGM_AUDIO_FILE=mp4/bgm.m4a ./generate_video.sh
```

## Main Settings

```bash
SPEAKER_A_LABEL="Speaker A"
SPEAKER_B_LABEL="Speaker B"

VOICEVOX_UNI_SPEAKER=69
VOICEVOX_MINA_SPEAKER=8

UNI_CHARACTER_HEIGHT=545
MINA_CHARACTER_HEIGHT=541
UNI_OVERLAY_X=100
MINA_OVERLAY_X=W-w-100
```

The variable names `UNI_*` and `MINA_*` are kept for compatibility with the original script. Treat them as Speaker A and Speaker B settings.

## External Audio Mode

If you already have WAV files, use:

```bash
AUDIO_INPUT_MODE=external ./generate_video.sh
```

Place files in:

```text
audio/speaker-a/*.wav
audio/speaker-b/*.wav
```

Files are consumed in natural sort order.

## License Notes

This script is MIT licensed.

VOICEVOX ENGINE, VOICEVOX voice models, character images, background images, and BGM have their own licenses and usage terms. Check each license before publishing generated videos or redistributing assets.

Useful references:

- VOICEVOX ENGINE: https://github.com/VOICEVOX/voicevox_engine
- VOICEVOX Q&A: https://voicevox.hiroshiba.jp/qa/
