---
name: optchat-profile
description: Create a new pi-optchat profile and switch to it. Use whenever the user asks to create/make/new a new optchat profile, in any language, e.g. "create a new /optchat profile xxx", "创建一个新的 optchat profile xxx", "新建 profile xxx". One command creates it, then a fresh session bound to it is started.
---

# Create + switch to a new optchat profile

pi-optchat (installed Pi extension) keeps one endless memory per profile in
`~/.optchat/profiles/<name>/` (override: `OPTCHAT_HOME`). A profile = separate
memory (summary tree), `AGENTS.md` instructions, and model config.

## Steps (do all, in order, without extra research)

1. **Create the profile.** If the user gave a capitalized name, lowercase it first
   (valid: `^[a-z0-9][a-z0-9_-]{0,63}$`):
   ```sh
   optchat-new-profile <name>
   ```
   The script is on PATH (installed by `install.sh`; `$PI_CODING_AGENT_DIR/bin` when that
   is on PATH, else `~/.local/bin`). It resolves the model automatically — the current Pi
   session's model when run inside Pi (`PI_PROVIDER`/`PI_MODEL`, the strongest signal),
   else the agent dir's `settings.json` default or `models.json` entries, with a liveness
   probe that skips models not actually served — so run it from inside a Pi session
   (e.g. via the bash tool) whenever possible. Override with `--provider P --model M`
   (or `OPTCHAT_PROVIDER`/`OPTCHAT_MODEL` env). It writes a schema-valid `config.json`
   (main/compactor/subagent pinned, thinking `medium`) plus a default `AGENTS.md`.
   If it prints "already exists": an unused profile can be reconfigured with a rerun
   adding `--force` (this also fixes a profile whose pinned model is wrong, e.g. created
   on a different machine); a profile with memory is never touched. Never hand-write
   `config.json` with cat/mkdir only; the script guarantees the layout `loadConfig`
   expects.

2. **Switch to it.** The current session cannot be rebound — pi-optchat binds a
   session to a profile only at session start, and only while the session is
   still empty. So start a fresh session bound to the profile:
   ```
   spawn_session(prompt="/optchat profile <name>")
   ```
   That text, as the first message of the new session, makes pi-optchat open the
   profile in place and bind the session (its documented non-TUI path). Leave the
   session `model` unset so it inherits this session's working model.

3. **Report to the user** (briefly):
   - profile `<name>` created at `~/.optchat/profiles/<name>/`
   - a new session is bound to it — open that session in the session list and
     chat there; this current session stays unbound
   - their memory/preferences persist in that profile across future sessions

## Fallbacks & troubleshooting

- **spawn_session unavailable/failed**: tell the user to open a new session and
  send `/optchat profile <name>` as its first message.
- **Model 404 in the new session** (global default points at a model that isn't served):
  pick a working model via `/model` in that session. The profile's pinned `main` config
  usually restores it on its own; if the pin itself is wrong (profile created on another
  machine or by an older script), re-run `optchat-new-profile <name> --force` from inside
  a Pi session so it re-pins to the model you're actually using.
- **Headless one-shot use**: `pi -p --optchat-profile <name> "message"`.
- **List profiles**: `ls ~/.optchat/profiles`
- **Delete a profile**: `rm -rf ~/.optchat/profiles/<name>` (only while no Pi has
  it open).
- **Edit profile instructions**: `<root>/profiles/<name>/AGENTS.md` (applies from
  the next turn).
