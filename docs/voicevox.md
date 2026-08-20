# VOICEVOX

Start VOICEVOX ENGINE before running the script in `voicevox` mode.

```bash
curl http://127.0.0.1:50021/version
```

Configure speaker IDs with:

```bash
VOICEVOX_UNI_SPEAKER=69
VOICEVOX_MINA_SPEAKER=8
```

The script sends each dialogue line to:

```text
POST /audio_query
POST /synthesis
```

When publishing videos that use VOICEVOX voices, include the required credit notation according to VOICEVOX and each character's terms.
