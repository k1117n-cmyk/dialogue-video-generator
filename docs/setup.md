# Setup

Install dependencies on macOS:

```bash
brew install ffmpeg ghostscript imagemagick jq
```

Check that commands are available:

```bash
command -v ffmpeg ffprobe magick jq
magick -version
```

`magick -version` should include `freetype` in `Delegates`.
