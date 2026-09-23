---
name: slap
description: Open a harmless local browser toy for slapping a cartoon AI after Claude, Codex, or another assistant fails. Use only when the user explicitly invokes this skill or asks to slap the AI.
---

# Slap

Immediately open the bundled toy by running:

```bash
python3 scripts/open_slapper.py
```

Run the command from this skill directory. Keep the response short and playful. If the environment cannot launch a graphical browser, give the user the local `file://` URL printed by the script.

Never add the prompt, conversation, user identity, or failure details to the URL or page. The toy is deliberately offline: do not start a server, make network requests, or add analytics. It may persist only the aggregate Claude/Codex slap counts and selected target in the browser's local storage.
