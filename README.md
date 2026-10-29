# optchat-piweb-setup

Use [pi-optchat](https://github.com/jonaslsaa/pi-optchat) under **Pi Web** (or any headless
Pi host), and create/switch profiles from an agent without a TUI.

pi-optchat gives you one endless chat per **profile**: every message is kept, each turn
starts from a bounded summary-tree view of everything so far, and the profile persists
across Pi sessions and directories. This repository adds:

- a **profile creation script** (`optchat-new-profile`) — needed because in non-TUI hosts
  (Pi Web) `/optchat profile <name>` can only *open* an existing profile, never create one;
- a **model-pinned config** — profile configs that pin `main`/`compactor`/`subagent` to a
  working model, so profiles survive a broken Pi global default;
- an **agent skill + global AGENTS.md snippet** — so an agent in any session can create a
  profile and switch to it when the user just says "create a new optchat profile xxx".

Works out of the box on a machine with a local vLLM model; every machine-specific value is
configurable.

---

## Part 1 — Setup guide (run this on the new machine)

Audience: a human, or the machine's coding agent (follow the steps in order).

### 0. Prerequisites

| Requirement | Check |
| --- | --- |
| Node.js ≥ 22.19 | `node --version` |
| Pi coding agent ≥ 1.0.2, `pi` on PATH | `pi --version` |
| A Pi Web instance running (the thing that hosts web sessions) | your web UI is up |
| A working model: an API provider logged in via `pi`, or a local vLLM entry in `~/.pi/agent/models.json` | ask Pi for its models |

Note down the provider id and model id of a model you know works, e.g.
`local-vllm1` / `/home/dash/models/Qwen3.8-27B-FP8`. Everything below defaults to that pair;
override with `OPTCHAT_PROVIDER` / `OPTCHAT_MODEL` / `OPTCHAT_THINKING` for yours.

### 1. Install pi-optchat

```sh
pi install npm:pi-optchat
```

Restart the Pi Web instance (or at least open a **fresh** session) so the extension loads —
extensions attach at Pi process start. Verify in a session: the footer/status shows
`OptChat: choose profile` and the agent has `zoom` / `date` tools.

### 2. Install this repository's tooling

```sh
git clone <this-repo> ~/optchat-piweb-setup
cd ~/optchat-piweb-setup
./install.sh
```

`install.sh` puts:
- `optchat-new-profile` on PATH (prefers `$PI_CODING_AGENT_DIR/bin` when that is on PATH,
  else `~/.local/bin`),
- the `optchat-profile` skill into `~/.agents/skills/`,
- a short section into the global `~/.pi/agent/AGENTS.md` (marker-delimited, idempotent).

### 3. Create your first profile

```sh
optchat-new-profile work
```

creates `~/.optchat/profiles/work/` with:
- `config.json` — recipe defaults, with `main` / `compactor` / `subagent` pinned to the
  local model, so the profile opens and summarizes correctly even if Pi's global default
  model is broken;
- `AGENTS.md` — profile instructions (edit freely; applies from the next turn).

Alternative: open an interactive TUI Pi window and use the profile picker's
**+ Create profile** — but in a pure Pi Web environment the script above is the way.

### 4. Bind a Pi Web session to the profile

In the Pi Web UI, open a **new session** and send, as the **first message**:

```
/optchat profile work
```

Pi Web (a non-TUI host) binds the session to that profile in place; the footer then shows
`OptChat: work` and every message in that session goes into the profile's memory.

Rules to know:
- binding happens **only at session start, while the session is still empty** — a running
  session can never be re-bound. To switch profiles: new session + that first message.
- `pi-optchat` never auto-creates a profile in non-TUI mode (a dialog would hang the host).
- one Pi process may hold a profile at a time; opening it elsewhere joins it as a
  connected window instead.

### 5. Use it

- **Chat** in the bound session; memory persists across sessions/directories.
- **Agent-side creation + switch**: just tell the agent "create a new optchat profile xxx"
  — the installed skill makes it run `optchat-new-profile xxx` and start a fresh session
  bound to it (`spawn_session(prompt="/optchat profile xxx")` in Pi Web).
- **Headless one-shot** from any shell/agent (writes into the profile's memory):

  ```sh
  pi -p --optchat-profile work "your message"
  ```

  If the profile is open in another Pi, a plain `pi -p` *joins* it as a subagent by
  default; `--optchat-connect auto|join|off` controls this.

### 6. Day-2 operations

| Task | How |
| --- | --- |
| List profiles | `ls ~/.optchat/profiles` |
| Edit instructions | `~/.optchat/profiles/<name>/AGENTS.md` |
| Change models/settings | `~/.optchat/profiles/<name>/config.json` (or TUI: `/optchat settings`, `/optchat model`) |
| Browse memory | `/optchat browse` (TUI) — readable HTML snapshot |
| Delete a profile | `rm -rf ~/.optchat/profiles/<name>` (only while no Pi has it open) |
| Checkpoints | each profile dir is a local git repo, committed after each turn |

## Part 2 — Troubleshooting

- **First turn in a fresh session fails with model 404** (e.g. a global default pointing at
  a model that doesn't exist): pick a working model via `/model` in that session, or make
  sure the profile's `config.json` has a valid `main` pin. The pin is restored whenever the
  profile opens (unless a `--model`/`--provider` flag overrides it for that run).
- **"Profile already running"**: another Pi holds it. Either wait, close that Pi, or let the
  second window join as a connected subagent window.
- **Stale lock after a crash**: start Pi again — sockets that no longer answer are removed
  automatically.
- **Extension not visible after install**: start a fresh session (extensions load when the
  Pi process starts).
- **Headless run is "plain Pi" (no OptChat status)**: you forgot `--optchat-profile <name>`
  and the session had no saved binding.
- **`pi -p` answered through another window's agent**: the profile was open elsewhere and
  the run joined it. Use `--optchat-connect off` to force a hard error instead.

## Layout

```
optchat-piweb-setup/
├── README.md                 # this guide
├── install.sh                # one-shot installer (script + skill + AGENTS.md section)
├── bin/
│   └── optchat-new-profile   # profile creator with model-pinned config
├── skills/
│   └── optchat-profile/
│       └── SKILL.md          # agent skill: create + switch on request
└── LICENSE
```

## Credits

Built on [pi-optchat](https://github.com/jonaslsaa/pi-optchat) (MIT) by Jonas, which
implements [Victor Taelin's OptChat recipe](https://gist.github.com/VictorTaelin/91837951a5ce5b38f341ec1ba1df6449).
Everything in this repository is the thin pi-web-oriented glue around it.
