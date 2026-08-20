#!/usr/bin/env bash

# Dialogue video generation automation.
# Reads a dialogue script, uses recorded audio, composites character clips,
# and concatenates them into a single MP4.

set -euo pipefail

#
# 入出力と外部コマンド
# SCRIPT_FILE: 台本ファイル
# TMP_DIR: 中間生成物の作業ディレクトリ
# OUTPUT_FILE: 最終出力する動画ファイル名
#
SCRIPT_FILE="${1:-script.txt}"
TMP_DIR="${TMP_DIR:-tmp}"
OUTPUT_FILE="${OUTPUT_FILE:-output.mp4}"
#
# 素材ディレクトリ
# BACKGROUND_DIR: 背景画像ディレクトリ
# SPEAKER_A_LABEL / SPEAKER_B_LABEL: script.txt で使う話者ラベル
# UNI_AUDIO_DIR / MINA_AUDIO_DIR: 話者ごとの音声ディレクトリ
# UNI_IMAGE_DIR / MINA_IMAGE_DIR: 話者ごとの立ち絵ディレクトリ
#
SPEAKER_A_LABEL="${SPEAKER_A_LABEL:-Speaker A}"
SPEAKER_B_LABEL="${SPEAKER_B_LABEL:-Speaker B}"
BACKGROUND_DIR="${BACKGROUND_DIR:-}"
UNI_AUDIO_DIR="${UNI_AUDIO_DIR:-}"
MINA_AUDIO_DIR="${MINA_AUDIO_DIR:-}"
UNI_IMAGE_DIR="${UNI_IMAGE_DIR:-}"
MINA_IMAGE_DIR="${MINA_IMAGE_DIR:-}"
#
# 音声入力モード
# AUDIO_INPUT_MODE: voicevox ならローカル API で自動生成、external なら既存 wav を利用
# VOICEVOX_URL: VOICEVOX Engine の URL
# VOICEVOX_*: 話者・話速・音高・抑揚・音量の調整値
#
AUDIO_INPUT_MODE="${AUDIO_INPUT_MODE:-voicevox}"
VOICEVOX_URL="${VOICEVOX_URL:-http://127.0.0.1:50021}"
VOICEVOX_UNI_SPEAKER="${VOICEVOX_UNI_SPEAKER:-69}"
VOICEVOX_MINA_SPEAKER="${VOICEVOX_MINA_SPEAKER:-8}"
VOICEVOX_UNI_SPEED_SCALE="${VOICEVOX_UNI_SPEED_SCALE:-1.03}"
VOICEVOX_MINA_SPEED_SCALE="${VOICEVOX_MINA_SPEED_SCALE:-1.05}"
VOICEVOX_UNI_PITCH_SCALE="${VOICEVOX_UNI_PITCH_SCALE:-0.00}"
VOICEVOX_MINA_PITCH_SCALE="${VOICEVOX_MINA_PITCH_SCALE:-0.04}"
VOICEVOX_UNI_INTONATION_SCALE="${VOICEVOX_UNI_INTONATION_SCALE:-1.00}"
VOICEVOX_MINA_INTONATION_SCALE="${VOICEVOX_MINA_INTONATION_SCALE:-1.08}"
VOICEVOX_UNI_VOLUME_SCALE="${VOICEVOX_UNI_VOLUME_SCALE:-1.00}"
VOICEVOX_MINA_VOLUME_SCALE="${VOICEVOX_MINA_VOLUME_SCALE:-1.00}"
#
# 音声と立ち絵の基本設定
# PLAYBACK_RATE: セリフ音声の再生速度。1.0 未満でゆっくりになる
# UNI_CHARACTER_HEIGHT / MINA_CHARACTER_HEIGHT: 立ち絵の表示高さ
# UNI_OVERLAY_X / MINA_OVERLAY_X: 立ち絵の横位置
#
PLAYBACK_RATE="${PLAYBACK_RATE:-1.00}"
UNI_CHARACTER_HEIGHT="${UNI_CHARACTER_HEIGHT:-545}"
MINA_CHARACTER_HEIGHT="${MINA_CHARACTER_HEIGHT:-541}"
UNI_OVERLAY_X="${UNI_OVERLAY_X:-100}"
MINA_OVERLAY_X="${MINA_OVERLAY_X:-W-w-100}"

# 字幕レイアウト設定
# SUBTITLE_CANVAS_SIZE: 字幕画像全体のサイズ
# SUBTITLE_BG_BOX: 背景ボックスのサイズ
# SUBTITLE_BG_COLOR: 字幕背景色
# SUBTITLE_BG_DRAW: 背景ボックスの描画形状
# SUBTITLE_BG_GRAVITY / SUBTITLE_BG_OFFSET: 字幕背景の配置位置
# SUBTITLE_TEXT_BACKGROUND: 文字描画時の背景
# SUBTITLE_TEXT_COLOR: 字幕文字色
# SUBTITLE_FONT / SUBTITLE_FONT_WEIGHT: 字幕フォント設定
# SUBTITLE_TEXT_BOX: 字幕テキスト領域のサイズ
# SUBTITLE_TEXT_GRAVITY / SUBTITLE_TEXT_OFFSET: 字幕文字の配置位置
export SUBTITLE_CANVAS_SIZE="${SUBTITLE_CANVAS_SIZE:-1920x160}"
export SUBTITLE_BG_BOX="${SUBTITLE_BG_BOX:-1680x120}"
export SUBTITLE_BG_COLOR="${SUBTITLE_BG_COLOR:-rgba(16,24,36,0.72)}"
export SUBTITLE_BG_DRAW="${SUBTITLE_BG_DRAW:-roundrectangle 0,0 1679,119 28,28}"
export SUBTITLE_BG_GRAVITY="${SUBTITLE_BG_GRAVITY:-south}"
export SUBTITLE_BG_OFFSET="${SUBTITLE_BG_OFFSET:-+0+50}"
export SUBTITLE_TEXT_BACKGROUND="${SUBTITLE_TEXT_BACKGROUND:-none}"
export SUBTITLE_TEXT_COLOR="${SUBTITLE_TEXT_COLOR:-white}"
export SUBTITLE_FONT="${SUBTITLE_FONT:-/System/Library/Fonts/ヒラギノ角ゴシック W5.ttc}"
export SUBTITLE_FONT_WEIGHT="${SUBTITLE_FONT_WEIGHT:-700}"
export SUBTITLE_TEXT_BOX="${SUBTITLE_TEXT_BOX:-1520x120}"
export SUBTITLE_TEXT_GRAVITY="${SUBTITLE_TEXT_GRAVITY:-west}"
export SUBTITLE_TEXT_OFFSET="${SUBTITLE_TEXT_OFFSET:-+80+20}"
#
# タイピング字幕設定
# SUBTITLE_TYPING_MIN_SECONDS: 短文でも最低限かける字幕表示時間
# SUBTITLE_TYPING_MAX_SECONDS: 長文でもここまでに抑える字幕表示時間
# SUBTITLE_FINAL_HOLD_SECONDS: 全文表示後に字幕を保持する時間
#
export SUBTITLE_TYPING_MIN_SECONDS="${SUBTITLE_TYPING_MIN_SECONDS:-2.0}"
export SUBTITLE_TYPING_MAX_SECONDS="${SUBTITLE_TYPING_MAX_SECONDS:-6.0}"
export SUBTITLE_FINAL_HOLD_SECONDS="${SUBTITLE_FINAL_HOLD_SECONDS:-0.5}"
#
# 盤面テキスト設定
# BOARD_ENABLED: 盤面テキスト描画の有効/無効
# BOARD_SCRIPT_FILE: 盤面表示用のテキストファイル
# BOARD_TEXT_BOX: 盤面テキスト領域のサイズ
# BOARD_TEXT_OFFSET / BOARD_TEXT_GRAVITY: 盤面テキストの配置位置
# BOARD_FONT / BOARD_FONT_SIZE: 盤面フォント設定
# BOARD_LINE_SPACING: 行間
# BOARD_TEXT_COLOR: 文字色
# BOARD_STROKE_COLOR / BOARD_STROKE_WIDTH: 縁取り設定
#
export BOARD_ENABLED="${BOARD_ENABLED:-1}"
export BOARD_SCRIPT_FILE="${BOARD_SCRIPT_FILE:-board_script.txt}"
export BOARD_TEXT_BOX="${BOARD_TEXT_BOX:-860x500}"
export BOARD_TEXT_OFFSET="${BOARD_TEXT_OFFSET:-+320+170}"
export BOARD_TEXT_GRAVITY="${BOARD_TEXT_GRAVITY:-northwest}"
export BOARD_FONT="${BOARD_FONT:-/System/Library/Fonts/ヒラギノ角ゴシック W5.ttc}"
export BOARD_FONT_SIZE="${BOARD_FONT_SIZE:-48}"
export BOARD_LINE_SPACING="${BOARD_LINE_SPACING:-10}"
export BOARD_TEXT_COLOR="${BOARD_TEXT_COLOR:-rgba(245,245,235,0.92)}"
export BOARD_STROKE_COLOR="${BOARD_STROKE_COLOR:-rgba(255,255,255,0.20)}"
export BOARD_STROKE_WIDTH="${BOARD_STROKE_WIDTH:-1}"
#
# BGM と会話間隔の設定
# BGM_AUDIO_FILE: 最終結合時に重ねる BGM ファイル
# BGM_VOLUME: BGM 音量
# BGM_FADE_OUT_SECONDS: 動画末尾で BGM をフェードアウトする秒数
# LINE_GAP_SECONDS: 全セリフ間に入れる短い共通の間
# SPEAKER_CHANGE_GAP_SECONDS: 話者交代時に追加する長めの間
#
export BGM_AUDIO_FILE="${BGM_AUDIO_FILE:-}"
BGM_VOLUME="${BGM_VOLUME:-0.20}"
export BGM_FADE_OUT_SECONDS="${BGM_FADE_OUT_SECONDS:-3.0}"
export LINE_GAP_SECONDS="${LINE_GAP_SECONDS:-0.50}"
export SPEAKER_CHANGE_GAP_SECONDS="${SPEAKER_CHANGE_GAP_SECONDS:-0.60}"

UNI_AUDIO_INDEX=0
MINA_AUDIO_INDEX=0
UNI_AUDIO_FILES=()
MINA_AUDIO_FILES=()
UNI_IMAGE_INDEX=0
MINA_IMAGE_INDEX=0
UNI_IMAGE_FILES=()
MINA_IMAGE_FILES=()
BACKGROUND_FILES=()
SPEAKER_IMAGE_PATH=""
CURRENT_BACKGROUND_PATH=""
CURRENT_RENDERED_BACKGROUND_PATH=""

set_default_external_dirs() {
  if [[ -z "$UNI_AUDIO_DIR" && -d "audio/speaker-a" ]]; then
    UNI_AUDIO_DIR="audio/speaker-a"
  fi

  if [[ -z "$MINA_AUDIO_DIR" && -d "audio/speaker-b" ]]; then
    MINA_AUDIO_DIR="audio/speaker-b"
  fi

  if [[ -z "$UNI_IMAGE_DIR" && -d "images/speaker-a" ]]; then
    UNI_IMAGE_DIR="images/speaker-a"
  fi

  if [[ -z "$MINA_IMAGE_DIR" && -d "images/speaker-b" ]]; then
    MINA_IMAGE_DIR="images/speaker-b"
  fi

  if [[ -z "$BACKGROUND_DIR" && -d "backgrounds" ]]; then
    BACKGROUND_DIR="backgrounds"
  fi
}

if [[ -n "${PYTHON_BIN:-}" ]]; then
  PYTHON_BIN="$PYTHON_BIN"
elif [[ -x /opt/homebrew/bin/python3 ]]; then
  PYTHON_BIN="/opt/homebrew/bin/python3"
else
  PYTHON_BIN="python3"
fi

# Verify required external commands exist before starting work.
require_commands() {
  local cmd
  local -a required_commands=(ffmpeg ffprobe magick)

  if [[ "$AUDIO_INPUT_MODE" == "voicevox" ]]; then
    required_commands+=(curl jq)
  fi

  for cmd in "${required_commands[@]}"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      printf 'required command not found: %s\n' "$cmd" >&2
      exit 1
    fi
  done
}

validate_board_config() {
  if [[ "$BOARD_ENABLED" != "1" ]]; then
    return 0
  fi

  if [[ ! -f "$BOARD_SCRIPT_FILE" ]]; then
    printf 'board script not found: %s\n' "$BOARD_SCRIPT_FILE" >&2
    exit 1
  fi

  if [[ ! -f "$SUBTITLE_FONT" ]]; then
    printf 'subtitle font not found: %s\n' "$SUBTITLE_FONT" >&2
    exit 1
  fi

  if [[ ! -f "$BOARD_FONT" ]]; then
    printf 'board font not found: %s\n' "$BOARD_FONT" >&2
    exit 1
  fi
}

validate_bgm_audio_config() {
  if [[ -n "$BGM_AUDIO_FILE" && "$BGM_AUDIO_FILE" != */* && -f "mp4/$BGM_AUDIO_FILE" ]]; then
    BGM_AUDIO_FILE="mp4/$BGM_AUDIO_FILE"
  fi

  if [[ -n "$BGM_AUDIO_FILE" && ! -f "$BGM_AUDIO_FILE" ]]; then
    printf 'BGM audio file not found: %s\n' "$BGM_AUDIO_FILE" >&2
    exit 1
  fi
}

validate_external_audio_config() {
  if [[ "$AUDIO_INPUT_MODE" == "voicevox" ]]; then
    return 0
  fi

  if [[ -z "$UNI_AUDIO_DIR" ]]; then
    printf 'external audio directory not configured for %s\n' "$SPEAKER_A_LABEL" >&2
    exit 1
  fi

  if [[ -z "$MINA_AUDIO_DIR" ]]; then
    printf 'external audio directory not configured for %s\n' "$SPEAKER_B_LABEL" >&2
    exit 1
  fi
}

validate_voicevox_audio_config() {
  local status_code=""

  if [[ "$AUDIO_INPUT_MODE" != "voicevox" ]]; then
    return 0
  fi

  case "$VOICEVOX_UNI_SPEAKER" in
    ''|*[!0-9]*)
      printf 'VOICEVOX_UNI_SPEAKER must be numeric: %s\n' "$VOICEVOX_UNI_SPEAKER" >&2
      exit 1
      ;;
  esac

  case "$VOICEVOX_MINA_SPEAKER" in
    ''|*[!0-9]*)
      printf 'VOICEVOX_MINA_SPEAKER must be numeric: %s\n' "$VOICEVOX_MINA_SPEAKER" >&2
      exit 1
      ;;
  esac

  status_code="$(curl -sS -o /dev/null -w '%{http_code}' "$VOICEVOX_URL/version" || true)"
  if [[ "$status_code" != "200" ]]; then
    printf 'VOICEVOX engine is not reachable at %s (status: %s)\n' "$VOICEVOX_URL" "${status_code:-unavailable}" >&2
    exit 1
  fi
}

validate_external_image_config() {
  if [[ -z "$UNI_IMAGE_DIR" ]]; then
    printf 'image directory not configured for %s\n' "$SPEAKER_A_LABEL" >&2
    exit 1
  fi

  if [[ -z "$MINA_IMAGE_DIR" ]]; then
    printf 'image directory not configured for %s\n' "$SPEAKER_B_LABEL" >&2
    exit 1
  fi
}

validate_background_config() {
  if [[ -z "$BACKGROUND_DIR" ]]; then
    printf 'background directory not configured\n' >&2
    exit 1
  fi
}

load_external_audio_files() {
  local speaker="$1"
  local dir="$2"
  local -a files=()
  local -a sorted_files=()
  local -a valid_files=()
  local path=""

  if [[ -z "$dir" ]]; then
    return 0
  fi

  if [[ ! -d "$dir" ]]; then
    printf 'external audio directory not found for %s: %s\n' "$speaker" "$dir" >&2
    exit 1
  fi

  shopt -s nullglob
  files=("$dir"/*.wav "$dir"/*.WAV)
  shopt -u nullglob

  if [[ ${#files[@]} -eq 0 ]]; then
    printf 'no wav files found for %s in: %s\n' "$speaker" "$dir" >&2
    exit 1
  fi

  while IFS= read -r path; do
    sorted_files+=("$path")
  done < <(printf '%s\n' "${files[@]}" | sort -V)

  for path in "${sorted_files[@]}"; do
    if [[ -f "$path" ]]; then
      valid_files+=("$path")
    else
      printf 'skipping missing external audio for %s: %s\n' "$speaker" "$path" >&2
    fi
  done

  if [[ ${#valid_files[@]} -eq 0 ]]; then
    printf 'no usable wav files found for %s in: %s\n' "$speaker" "$dir" >&2
    exit 1
  fi

  case "$speaker" in
    "$SPEAKER_A_LABEL")
      UNI_AUDIO_FILES=("${valid_files[@]}")
      ;;
    "$SPEAKER_B_LABEL")
      MINA_AUDIO_FILES=("${valid_files[@]}")
      ;;
    *)
      printf 'unsupported speaker: %s\n' "$speaker" >&2
      exit 1
      ;;
  esac
}

initialize_external_audio() {
  if [[ "$AUDIO_INPUT_MODE" == "voicevox" ]]; then
    return 0
  fi

  load_external_audio_files "$SPEAKER_A_LABEL" "$UNI_AUDIO_DIR"
  load_external_audio_files "$SPEAKER_B_LABEL" "$MINA_AUDIO_DIR"
}

load_external_image_files() {
  local speaker="$1"
  local dir="$2"
  local -a files=()
  local -a sorted_files=()
  local -a valid_files=()
  local path=""

  if [[ -z "$dir" ]]; then
    return 0
  fi

  if [[ ! -d "$dir" ]]; then
    printf 'external image directory not found for %s: %s\n' "$speaker" "$dir" >&2
    exit 1
  fi

  shopt -s nullglob
  files=(
    "$dir"/*.webp "$dir"/*.WEBP
    "$dir"/*.png "$dir"/*.PNG
    "$dir"/*.jpg "$dir"/*.JPG
    "$dir"/*.jpeg "$dir"/*.JPEG
  )
  shopt -u nullglob

  if [[ ${#files[@]} -eq 0 ]]; then
    printf 'no image files found for %s in: %s\n' "$speaker" "$dir" >&2
    exit 1
  fi

  while IFS= read -r path; do
    sorted_files+=("$path")
  done < <(printf '%s\n' "${files[@]}" | sort -V)

  for path in "${sorted_files[@]}"; do
    if [[ -f "$path" ]]; then
      valid_files+=("$path")
    else
      printf 'skipping missing external image for %s: %s\n' "$speaker" "$path" >&2
    fi
  done

  if [[ ${#valid_files[@]} -eq 0 ]]; then
    printf 'no usable image files found for %s in: %s\n' "$speaker" "$dir" >&2
    exit 1
  fi

  case "$speaker" in
    "$SPEAKER_A_LABEL")
      UNI_IMAGE_FILES=("${valid_files[@]}")
      ;;
    "$SPEAKER_B_LABEL")
      MINA_IMAGE_FILES=("${valid_files[@]}")
      ;;
    *)
      printf 'unsupported speaker: %s\n' "$speaker" >&2
      exit 1
      ;;
  esac
}

initialize_external_images() {
  load_external_image_files "$SPEAKER_A_LABEL" "$UNI_IMAGE_DIR"
  load_external_image_files "$SPEAKER_B_LABEL" "$MINA_IMAGE_DIR"
}

load_background_files() {
  local dir="$1"
  local -a files=()
  local -a sorted_files=()
  local -a valid_files=()
  local path=""

  if [[ -z "$dir" ]]; then
    return 0
  fi

  if [[ ! -d "$dir" ]]; then
    printf 'background directory not found: %s\n' "$dir" >&2
    exit 1
  fi

  shopt -s nullglob
  files=(
    "$dir"/*.webp "$dir"/*.WEBP
    "$dir"/*.png "$dir"/*.PNG
    "$dir"/*.jpg "$dir"/*.JPG
    "$dir"/*.jpeg "$dir"/*.JPEG
  )
  shopt -u nullglob

  if [[ ${#files[@]} -eq 0 ]]; then
    printf 'no background image files found in: %s\n' "$dir" >&2
    exit 1
  fi

  while IFS= read -r path; do
    sorted_files+=("$path")
  done < <(printf '%s\n' "${files[@]}" | sort -V)

  for path in "${sorted_files[@]}"; do
    if [[ -f "$path" ]]; then
      valid_files+=("$path")
    else
      printf 'skipping missing background image: %s\n' "$path" >&2
    fi
  done

  if [[ ${#valid_files[@]} -eq 0 ]]; then
    printf 'no usable background image files found in: %s\n' "$dir" >&2
    exit 1
  fi

  BACKGROUND_FILES=("${valid_files[@]}")
}

initialize_backgrounds() {
  load_background_files "$BACKGROUND_DIR"
}

resolve_background_path() {
  if [[ ${#BACKGROUND_FILES[@]} -eq 0 ]]; then
    printf 'no background images available in: %s\n' "$BACKGROUND_DIR" >&2
    exit 1
  fi

  CURRENT_BACKGROUND_PATH="${BACKGROUND_FILES[0]}"
}

resolve_board_text() {
  local line_no="$1"

  if [[ "$BOARD_ENABLED" != "1" ]]; then
    return 0
  fi

  "$PYTHON_BIN" - <<'PY' "$BOARD_SCRIPT_FILE" "$line_no"
import re
import sys
from pathlib import Path

script_path = Path(sys.argv[1])
line_no = int(sys.argv[2])

text = script_path.read_text(encoding="utf-8")
lines = text.splitlines()

sections = []
current_start = None
current_end = None
current_body = []

header_re = re.compile(r'^\[(\d+)-(\d+)\]$')

def flush():
    global current_start, current_end, current_body
    if current_start is None:
        return
    body = "\n".join(current_body).strip()
    sections.append((current_start, current_end, body))
    current_start = None
    current_end = None
    current_body = []

for raw in lines:
    line = raw.rstrip("\n")
    match = header_re.match(line.strip())
    if match:
        flush()
        start = int(match.group(1))
        end = int(match.group(2))
        if start > end:
            raise SystemExit(f"invalid board range: [{start}-{end}]")
        current_start = start
        current_end = end
        current_body = []
        continue

    if current_start is None:
        if line.strip():
            raise SystemExit(f"board text found before range header: {line}")
        continue

    if not line.strip():
        flush()
        continue

    current_body.append(line)

flush()
sections.sort(key=lambda item: item[0])

for idx in range(1, len(sections)):
    prev = sections[idx - 1]
    cur = sections[idx]
    if cur[0] <= prev[1]:
        raise SystemExit(
            f"overlapping board ranges: [{prev[0]}-{prev[1]}] and [{cur[0]}-{cur[1]}]"
        )

for start, end, body in sections:
    if start <= line_no <= end:
        sys.stdout.write(body)
        break
PY
}

render_board_background() {
  local base_bg="$1"
  local line_no="$2"
  local board_dir="$3"
  local board_text=""
  local cache_key=""
  local output_path=""

  CURRENT_RENDERED_BACKGROUND_PATH="$base_bg"

  if [[ "$BOARD_ENABLED" != "1" ]]; then
    return 0
  fi

  board_text="$(resolve_board_text "$line_no")"

  if [[ -z "${board_text//[[:space:]]/}" ]]; then
    return 0
  fi

  mkdir -p "$board_dir"

  cache_key="$(
    printf '%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n' \
      "$base_bg" \
      "$board_text" \
      "$BOARD_TEXT_BOX" \
      "$BOARD_TEXT_OFFSET" \
      "$BOARD_TEXT_GRAVITY" \
      "$BOARD_FONT" \
      "$BOARD_FONT_SIZE" \
      "$BOARD_LINE_SPACING" \
      "$BOARD_TEXT_COLOR" \
      "$BOARD_STROKE_COLOR" \
      "$BOARD_STROKE_WIDTH" \
    | shasum -a 256 | awk '{print $1}'
  )"

  output_path="$board_dir/${cache_key}.png"

  if [[ -f "$output_path" ]]; then
    CURRENT_RENDERED_BACKGROUND_PATH="$output_path"
    return 0
  fi

  magick "$base_bg" \
    \( \
      -background none \
      -fill "$BOARD_TEXT_COLOR" \
      -stroke "$BOARD_STROKE_COLOR" \
      -strokewidth "$BOARD_STROKE_WIDTH" \
      -font "$BOARD_FONT" \
      -pointsize "$BOARD_FONT_SIZE" \
      -interline-spacing "$BOARD_LINE_SPACING" \
      -size "$BOARD_TEXT_BOX" \
      -gravity "$BOARD_TEXT_GRAVITY" \
      "caption:$board_text" \
    \) \
    -gravity northwest \
    -geometry "$BOARD_TEXT_OFFSET" \
    -composite \
    -define png:color-type=6 \
    -type TrueColorAlpha \
    "$output_path"

  CURRENT_RENDERED_BACKGROUND_PATH="$output_path"
}

speaker_image_path() {
  local speaker="$1"
  local image_count=0

  case "$speaker" in
    "$SPEAKER_A_LABEL")
      image_count=${#UNI_IMAGE_FILES[@]}
      if (( image_count == 0 )); then
        printf 'no image files available for %s in: %s\n' "$speaker" "$UNI_IMAGE_DIR" >&2
        exit 1
      fi
      SPEAKER_IMAGE_PATH="${UNI_IMAGE_FILES[$((UNI_IMAGE_INDEX % image_count))]}"
      UNI_IMAGE_INDEX=$((UNI_IMAGE_INDEX + 1))
      ;;
    "$SPEAKER_B_LABEL")
      image_count=${#MINA_IMAGE_FILES[@]}
      if (( image_count == 0 )); then
        printf 'no image files available for %s in: %s\n' "$speaker" "$MINA_IMAGE_DIR" >&2
        exit 1
      fi
      SPEAKER_IMAGE_PATH="${MINA_IMAGE_FILES[$((MINA_IMAGE_INDEX % image_count))]}"
      MINA_IMAGE_INDEX=$((MINA_IMAGE_INDEX + 1))
      ;;
    *)
      printf 'unsupported speaker: %s\n' "$speaker" >&2
      exit 1
      ;;
  esac
}

# Prepare a clean tmp workspace for intermediate files.
prepare_workspace() {
  rm -rf "$TMP_DIR"
  mkdir -p "$TMP_DIR"/audio "$TMP_DIR"/clips "$TMP_DIR"/subs
}

adjust_audio_tempo() {
  local audio_path="$1"
  local adjusted_path="${audio_path%.wav}_adjusted.wav"

  if [[ "$PLAYBACK_RATE" == "1" || "$PLAYBACK_RATE" == "1.0" ]]; then
    return 0
  fi

  ffmpeg -y \
    -nostdin \
    -i "$audio_path" \
    -filter:a "atempo=${PLAYBACK_RATE}" \
    "$adjusted_path"

  mv "$adjusted_path" "$audio_path"
}

append_silence_to_audio() {
  local audio_path="$1"
  local gap_seconds="$2"
  local extended_path="${audio_path%.wav}_extended.wav"
  local original_duration=""
  local target_duration=""

  if [[ "$gap_seconds" == "0" || "$gap_seconds" == "0.0" ]]; then
    return 0
  fi

  original_duration="$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$audio_path")"
  target_duration="$(awk "BEGIN { printf \"%.3f\", $original_duration + $gap_seconds }")"

  ffmpeg -y \
    -nostdin \
    -i "$audio_path" \
    -af "apad=pad_dur=${gap_seconds},atrim=duration=${target_duration}" \
    "$extended_path"

  mv "$extended_path" "$audio_path"
}

copy_external_audio() {
  local speaker="$1"
  local audio_path="$2"
  local source_path=""

  case "$speaker" in
    "$SPEAKER_A_LABEL")
      if (( UNI_AUDIO_INDEX >= ${#UNI_AUDIO_FILES[@]} )); then
        printf 'not enough external audio files for %s in: %s\n' "$speaker" "$UNI_AUDIO_DIR" >&2
        exit 1
      fi
      source_path="${UNI_AUDIO_FILES[$UNI_AUDIO_INDEX]}"
      UNI_AUDIO_INDEX=$((UNI_AUDIO_INDEX + 1))
      ;;
    "$SPEAKER_B_LABEL")
      if (( MINA_AUDIO_INDEX >= ${#MINA_AUDIO_FILES[@]} )); then
        printf 'not enough external audio files for %s in: %s\n' "$speaker" "$MINA_AUDIO_DIR" >&2
        exit 1
      fi
      source_path="${MINA_AUDIO_FILES[$MINA_AUDIO_INDEX]}"
      MINA_AUDIO_INDEX=$((MINA_AUDIO_INDEX + 1))
      ;;
    *)
      printf 'unsupported speaker: %s\n' "$speaker" >&2
      exit 1
      ;;
  esac

  cp "$source_path" "$audio_path"
}

voicevox_speaker_id() {
  local speaker="$1"

  case "$speaker" in
    "$SPEAKER_A_LABEL")
      printf '%s\n' "$VOICEVOX_UNI_SPEAKER"
      ;;
    "$SPEAKER_B_LABEL")
      printf '%s\n' "$VOICEVOX_MINA_SPEAKER"
      ;;
    *)
      printf 'unsupported speaker: %s\n' "$speaker" >&2
      exit 1
      ;;
  esac
}

voicevox_speed_scale() {
  local speaker="$1"

  case "$speaker" in
    "$SPEAKER_A_LABEL")
      printf '%s\n' "$VOICEVOX_UNI_SPEED_SCALE"
      ;;
    "$SPEAKER_B_LABEL")
      printf '%s\n' "$VOICEVOX_MINA_SPEED_SCALE"
      ;;
    *)
      printf 'unsupported speaker: %s\n' "$speaker" >&2
      exit 1
      ;;
  esac
}

voicevox_pitch_scale() {
  local speaker="$1"

  case "$speaker" in
    "$SPEAKER_A_LABEL")
      printf '%s\n' "$VOICEVOX_UNI_PITCH_SCALE"
      ;;
    "$SPEAKER_B_LABEL")
      printf '%s\n' "$VOICEVOX_MINA_PITCH_SCALE"
      ;;
    *)
      printf 'unsupported speaker: %s\n' "$speaker" >&2
      exit 1
      ;;
  esac
}

voicevox_intonation_scale() {
  local speaker="$1"

  case "$speaker" in
    "$SPEAKER_A_LABEL")
      printf '%s\n' "$VOICEVOX_UNI_INTONATION_SCALE"
      ;;
    "$SPEAKER_B_LABEL")
      printf '%s\n' "$VOICEVOX_MINA_INTONATION_SCALE"
      ;;
    *)
      printf 'unsupported speaker: %s\n' "$speaker" >&2
      exit 1
      ;;
  esac
}

voicevox_volume_scale() {
  local speaker="$1"

  case "$speaker" in
    "$SPEAKER_A_LABEL")
      printf '%s\n' "$VOICEVOX_UNI_VOLUME_SCALE"
      ;;
    "$SPEAKER_B_LABEL")
      printf '%s\n' "$VOICEVOX_MINA_VOLUME_SCALE"
      ;;
    *)
      printf 'unsupported speaker: %s\n' "$speaker" >&2
      exit 1
      ;;
  esac
}

generate_voicevox_audio() {
  local speaker="$1"
  local dialogue="$2"
  local audio_path="$3"
  local speaker_id=""
  local speed_scale=""
  local pitch_scale=""
  local intonation_scale=""
  local volume_scale=""
  local encoded_dialogue=""
  local query_json=""

  speaker_id="$(voicevox_speaker_id "$speaker")"
  speed_scale="$(voicevox_speed_scale "$speaker")"
  pitch_scale="$(voicevox_pitch_scale "$speaker")"
  intonation_scale="$(voicevox_intonation_scale "$speaker")"
  volume_scale="$(voicevox_volume_scale "$speaker")"
  encoded_dialogue="$("$PYTHON_BIN" -c 'import sys, urllib.parse; print(urllib.parse.quote(sys.argv[1], safe=""))' "$dialogue")"

  query_json="$(
    curl -sS -X POST \
      "$VOICEVOX_URL/audio_query?text=$encoded_dialogue&speaker=$speaker_id"
  )"

  if [[ -z "$query_json" ]]; then
    printf 'failed to build VOICEVOX query for %s\n' "$speaker" >&2
    exit 1
  fi

  if ! printf '%s' "$query_json" | jq -e '.accent_phrases' >/dev/null 2>&1; then
    printf 'invalid VOICEVOX audio_query response for %s: %s\n' "$speaker" "$query_json" >&2
    exit 1
  fi

  query_json="$(
    printf '%s' "$query_json" \
      | jq \
        --argjson speedScale "$speed_scale" \
        --argjson pitchScale "$pitch_scale" \
        --argjson intonationScale "$intonation_scale" \
        --argjson volumeScale "$volume_scale" \
        '.speedScale = $speedScale
         | .pitchScale = $pitchScale
         | .intonationScale = $intonationScale
         | .volumeScale = $volumeScale'
  )"

  printf '%s' "$query_json" \
    | curl -sS -X POST \
      -H 'Content-Type: application/json' \
      --data-binary @- \
      "$VOICEVOX_URL/synthesis?speaker=$speaker_id" \
      >"$audio_path"

  if [[ ! -s "$audio_path" ]]; then
    printf 'VOICEVOX synthesis returned empty audio for %s\n' "$speaker" >&2
    exit 1
  fi

  if [[ "$(file -b "$audio_path")" != *WAVE* ]]; then
    printf 'invalid VOICEVOX synthesis response for %s: %s\n' "$speaker" "$(cat "$audio_path")" >&2
    exit 1
  fi

}

prepare_line_audio() {
  local speaker="$1"
  local dialogue="$2"
  local audio_path="$3"

  case "$AUDIO_INPUT_MODE" in
    external)
      copy_external_audio "$speaker" "$audio_path"
      ;;
    voicevox)
      generate_voicevox_audio "$speaker" "$dialogue" "$audio_path"
      ;;
    *)
      printf 'unsupported AUDIO_INPUT_MODE: %s\n' "$AUDIO_INPUT_MODE" >&2
      exit 1
      ;;
  esac
}

generate_subtitle_overlay() {
  local dialogue="$1"
  local audio_path="$2"
  local subtitle_list_path="$3"
  local subtitle_dir="$4"
  local extra_tail_padding="${5:-0}"
  local duration=""

  duration="$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$audio_path")"

  "$PYTHON_BIN" - <<'PY' "$dialogue" "$duration" "$subtitle_list_path" "$subtitle_dir" "$extra_tail_padding"
import os
import subprocess
import sys
from pathlib import Path

dialogue, duration_raw, subtitle_list_path, subtitle_dir, extra_tail_padding_raw = sys.argv[1:]
duration = float(duration_raw or "0")
extra_tail_padding = float(extra_tail_padding_raw or "0")
subtitle_canvas_size = os.environ["SUBTITLE_CANVAS_SIZE"]
subtitle_bg_box = os.environ["SUBTITLE_BG_BOX"]
subtitle_bg_color = os.environ["SUBTITLE_BG_COLOR"]
subtitle_bg_draw = os.environ["SUBTITLE_BG_DRAW"]
subtitle_bg_gravity = os.environ["SUBTITLE_BG_GRAVITY"]
subtitle_bg_offset = os.environ["SUBTITLE_BG_OFFSET"]
subtitle_text_background = os.environ["SUBTITLE_TEXT_BACKGROUND"]
subtitle_text_color = os.environ["SUBTITLE_TEXT_COLOR"]
subtitle_font = os.environ["SUBTITLE_FONT"]
subtitle_font_weight = os.environ["SUBTITLE_FONT_WEIGHT"]
subtitle_text_box = os.environ["SUBTITLE_TEXT_BOX"]
subtitle_text_gravity = os.environ["SUBTITLE_TEXT_GRAVITY"]
subtitle_text_offset = os.environ["SUBTITLE_TEXT_OFFSET"]
subtitle_typing_min_seconds = float(os.environ["SUBTITLE_TYPING_MIN_SECONDS"])
subtitle_typing_max_seconds = float(os.environ["SUBTITLE_TYPING_MAX_SECONDS"])
subtitle_final_hold_seconds = float(os.environ["SUBTITLE_FINAL_HOLD_SECONDS"])

def wrap_text(text: str, width: int = 24) -> str:
    lines = []
    current = []
    count = 0
    for ch in text:
        current.append(ch)
        count += 1
        if count >= width and ch not in " ,.?!:;)]}、。！？）」』":
            lines.append("".join(current))
            current = []
            count = 0
    if current:
        lines.append("".join(current))
    return "\n".join(lines)

subtitle_dir = Path(subtitle_dir)
subtitle_dir.mkdir(parents=True, exist_ok=True)
chars = list(dialogue)
if not chars:
    chars = [" "]

typing_duration = min(
    max(duration * 0.85, subtitle_typing_min_seconds),
    subtitle_typing_max_seconds,
)
typing_duration = min(typing_duration, max(duration, subtitle_typing_min_seconds))

total_centis = max(len(chars), round(typing_duration * 100))
base, rem = divmod(total_centis, len(chars))
tail_padding = subtitle_final_hold_seconds + extra_tail_padding

entries = []
visible = ""
for idx, ch in enumerate(chars, start=1):
    visible += ch
    text_path = subtitle_dir / f"text_{idx:03d}.txt"
    png_path = subtitle_dir / f"sub_{idx:03d}.png"
    wrapped_text = f"{wrap_text(visible)}\n"
    text_path.write_text(wrapped_text, encoding="utf-8")

    cmd = [
        "magick",
        "-size", subtitle_canvas_size,
        "xc:none",
        "(",
        "-size", subtitle_bg_box,
        "xc:none",
        "-fill", subtitle_bg_color,
        "-draw", subtitle_bg_draw,
        ")",
        "-gravity", subtitle_bg_gravity,
        "-geometry", subtitle_bg_offset,
        "-composite",
        "(",
        "-background", subtitle_text_background,
        "-fill", subtitle_text_color,
        "-font", subtitle_font,
        "-weight", subtitle_font_weight,
        "-size", subtitle_text_box,
        "-gravity", subtitle_text_gravity,
        f"caption:{wrapped_text}",
        ")",
        "-gravity", subtitle_bg_gravity,
        "-geometry", subtitle_text_offset,
        "-composite",
        "-define", "png:color-type=6",
        "-type", "TrueColorAlpha",
        str(png_path),
    ]
    subprocess.run(cmd, check=True)
    centis = base + (1 if idx <= rem else 0)
    entries.append((png_path.resolve(), centis / 100.0))

list_path = Path(subtitle_list_path)
with list_path.open("w", encoding="utf-8") as handle:
    handle.write("ffconcat version 1.0\n")
    for png_path, duration_sec in entries:
        handle.write(f"file '{png_path.as_posix()}'\n")
        handle.write(f"duration {duration_sec:.2f}\n")
    handle.write(f"file '{entries[-1][0].as_posix()}'\n")
    handle.write(f"duration {tail_padding:.2f}\n")
    handle.write(f"file '{entries[-1][0].as_posix()}'\n")
PY
}

# Create one MP4 clip from the background, character, and synthesized audio.
encode_clip() {
  local speaker="$1"
  local char_image_path="$2"
  local background_path="$3"
  local audio_path="$4"
  local subtitle_list_path="$5"
  local clip_path="$6"
  local overlay_x=""
  local character_height=""
  local volume_adjust="1.5"

  if [[ ! -f "$char_image_path" ]]; then
    printf 'character image not found: %s\n' "$char_image_path" >&2
    exit 1
  fi

  if [[ ! -f "$background_path" ]]; then
    printf 'background image not found: %s\n' "$background_path" >&2
    exit 1
  fi

  case "$speaker" in
    "$SPEAKER_A_LABEL")
      overlay_x="$UNI_OVERLAY_X"
      character_height="$UNI_CHARACTER_HEIGHT"
      ;;
    "$SPEAKER_B_LABEL")
      overlay_x="$MINA_OVERLAY_X"
      character_height="$MINA_CHARACTER_HEIGHT"
      ;;
    *)
      printf 'unsupported speaker: %s\n' "$speaker" >&2
      exit 1
      ;;
  esac

  ffmpeg -y \
    -nostdin \
    -loop 1 -i "$background_path" \
    -i "$char_image_path" \
    -i "$audio_path" \
    -f concat -safe 0 -i "$subtitle_list_path" \
    -filter_complex "[0:v]fps=30,setpts=PTS-STARTPTS[bg]; \
      [1:v]scale=-1:${character_height},fps=30,format=rgba,setpts=PTS-STARTPTS[char]; \
      [3:v]fps=30,format=rgba,setpts=PTS-STARTPTS[sub]; \
      [bg][char]overlay=${overlay_x}:H-h[base]; \
      [base][sub]overlay=0:H-h[v]; \
      [2:a]volume=${volume_adjust},aresample=44100[a]" \
    -map "[v]" \
    -map "[a]" \
    -c:v libx264 \
    -pix_fmt yuv420p \
    -preset medium \
    -c:a aac \
    -b:a 192k \
    -shortest \
    "$clip_path"
}

require_commands
set_default_external_dirs
validate_board_config
validate_external_audio_config
validate_voicevox_audio_config
validate_external_image_config
validate_background_config
validate_bgm_audio_config

if [[ ! -f "$SCRIPT_FILE" ]]; then
  printf 'script file not found: %s\n' "$SCRIPT_FILE" >&2
  exit 1
fi

initialize_external_audio
initialize_external_images
initialize_backgrounds
prepare_workspace

concat_list="$TMP_DIR/concat.txt"
line_no=0
SCRIPT_SPEAKERS=()
SCRIPT_VOICE_DIALOGUES=()
SCRIPT_SUBTITLE_DIALOGUES=()

# Parse script lines first so speaker changes can be detected.
while IFS= read -r raw_line || [[ -n "$raw_line" ]]; do
  line_no=$((line_no + 1))

  if [[ -z "${raw_line//[[:space:]]/}" ]]; then
    continue
  fi

  speaker=""
  voice_dialogue=""
  subtitle_dialogue=""

  if [[ "$raw_line" == *"|"* ]]; then
    pipe_markers="${raw_line//[^|]/}"
    pipe_count=${#pipe_markers}

    if (( pipe_count < 1 || pipe_count > 2 )); then
      printf 'invalid line %d: "|" format must have 2 or 3 columns\n' "$line_no" >&2
      exit 1
    fi

    IFS='|' read -r speaker voice_dialogue subtitle_dialogue extra_field <<<"$raw_line"

    if [[ -n "${extra_field:-}" ]]; then
      printf 'invalid line %d: "|" format must have 2 or 3 columns\n' "$line_no" >&2
      exit 1
    fi

    if [[ -z "${subtitle_dialogue+x}" || -z "${subtitle_dialogue//[[:space:]]/}" ]]; then
      subtitle_dialogue="$voice_dialogue"
    fi
  elif [[ "$raw_line" == *:* ]]; then
    speaker="${raw_line%%:*}"
    voice_dialogue="${raw_line#*:}"
    subtitle_dialogue="$voice_dialogue"
  else
    printf 'invalid line %d: missing "|" or ":" separator\n' "$line_no" >&2
    exit 1
  fi

  if [[ -z "${speaker//[[:space:]]/}" || -z "${voice_dialogue//[[:space:]]/}" || -z "${subtitle_dialogue//[[:space:]]/}" ]]; then
    printf 'invalid line %d: empty speaker, voice dialogue, or subtitle dialogue\n' "$line_no" >&2
    exit 1
  fi

  SCRIPT_SPEAKERS+=("$speaker")
  SCRIPT_VOICE_DIALOGUES+=("$voice_dialogue")
  SCRIPT_SUBTITLE_DIALOGUES+=("$subtitle_dialogue")
done <"$SCRIPT_FILE"

if [[ ${#SCRIPT_SPEAKERS[@]} -eq 0 ]]; then
  printf 'no dialogue lines were processed\n' >&2
  exit 1
fi

# Generate one clip per parsed line.
for idx in "${!SCRIPT_SPEAKERS[@]}"; do
  line_no=$((idx + 1))
  speaker="${SCRIPT_SPEAKERS[$idx]}"
  voice_dialogue="${SCRIPT_VOICE_DIALOGUES[$idx]}"
  subtitle_dialogue="${SCRIPT_SUBTITLE_DIALOGUES[$idx]}"
  next_speaker=""
  line_gap="0"
  speaker_change_gap="0"
  total_gap="0"

  if (( idx + 1 < ${#SCRIPT_SPEAKERS[@]} )); then
    line_gap="$LINE_GAP_SECONDS"
    next_speaker="${SCRIPT_SPEAKERS[$((idx + 1))]}"
    if [[ "$speaker" != "$next_speaker" ]]; then
      speaker_change_gap="$SPEAKER_CHANGE_GAP_SECONDS"
    fi
  fi

  total_gap="$(awk "BEGIN { printf \"%.3f\", $line_gap + $speaker_change_gap }")"

  speaker_image_path "$speaker"
  image_path="$SPEAKER_IMAGE_PATH"
  resolve_background_path
  background_path="$CURRENT_BACKGROUND_PATH"
  board_dir="$TMP_DIR/board"
  render_board_background "$background_path" "$line_no" "$board_dir"
  background_path="$CURRENT_RENDERED_BACKGROUND_PATH"

  index=$(printf '%03d' "$line_no")
  audio_path="$TMP_DIR/audio/audio_${index}.wav"
  subtitle_dir="$TMP_DIR/subs/sub_${index}"
  subtitle_list_path="$TMP_DIR/subs/sub_${index}.ffconcat"
  clip_path="$TMP_DIR/clips/clip_${index}.mp4"
  if [[ "$clip_path" = /* ]]; then
    clip_path_abs="$clip_path"
  else
    clip_path_abs="$PWD/$clip_path"
  fi

  prepare_line_audio "$speaker" "$voice_dialogue" "$audio_path"
  adjust_audio_tempo "$audio_path"
  generate_subtitle_overlay "$subtitle_dialogue" "$audio_path" "$subtitle_list_path" "$subtitle_dir" "$total_gap"
  append_silence_to_audio "$audio_path" "$total_gap"
  encode_clip "$speaker" "$image_path" "$background_path" "$audio_path" "$subtitle_list_path" "$clip_path"

  printf "file '%s'\n" "$clip_path_abs" >>"$concat_list"
done

# Concatenate all generated clips into the final video.
# Re-encode the final mux to normalize timestamps and avoid DTS warnings.
if [[ -n "$BGM_AUDIO_FILE" ]]; then
  main_duration="$(
    awk -F"'" '/^file / { print $2 }' "$concat_list" \
      | while IFS= read -r clip_path; do
          ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$clip_path"
        done \
      | awk '{ sum += $1 } END { printf "%.3f", sum }'
  )"
  fade_start="$(awk "BEGIN { s=$main_duration-$BGM_FADE_OUT_SECONDS; if (s < 0) s=0; printf \"%.3f\", s }")"
  bgm_filter="[1:a]volume=${BGM_VOLUME},aformat=channel_layouts=mono[bgm]"

  if awk "BEGIN { exit !($BGM_FADE_OUT_SECONDS > 0) }"; then
    bgm_filter="[1:a]volume=${BGM_VOLUME},aformat=channel_layouts=mono,afade=t=out:st=${fade_start}:d=${BGM_FADE_OUT_SECONDS}[bgm]"
  fi

  ffmpeg -y \
    -nostdin \
    -f concat -safe 0 -i "$concat_list" \
    -stream_loop -1 -i "$BGM_AUDIO_FILE" \
    -filter_complex "${bgm_filter};[0:a][bgm]amix=inputs=2:duration=first:dropout_transition=2:normalize=0[a]" \
    -map 0:v \
    -map "[a]" \
    -c:v libx264 \
    -pix_fmt yuv420p \
    -preset medium \
    -c:a aac \
    -b:a 192k \
    "$OUTPUT_FILE"
else
  ffmpeg -y \
    -nostdin \
    -f concat -safe 0 -i "$concat_list" \
    -c:v libx264 \
    -pix_fmt yuv420p \
    -preset medium \
    -c:a aac \
    -b:a 192k \
    "$OUTPUT_FILE"
fi

printf 'generated: %s\n' "$OUTPUT_FILE"
