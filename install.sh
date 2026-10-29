#!/usr/bin/env bash
# Install optchat-piweb-setup tooling for the current user:
#   1. optchat-new-profile script onto PATH
#   2. the optchat-profile agent skill
#   3. a marker-delimited section into the global AGENTS.md (idempotent)
#
# Environment overrides:
#   PI_CODING_AGENT_DIR   agent dir      (default ~/.pi/agent)
#   OPTCHAT_SKILLS_DIR    skills dir     (default ~/.agents/skills)
#   OPTCHAT_PROVIDER/MODEL/THINKING  model pinning for new profiles (default: auto-detected by the script)
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENTS_DIR="${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}"
SKILLS_DIR="${OPTCHAT_SKILLS_DIR:-$HOME/.agents/skills}"

# --- 1. script on PATH -------------------------------------------------------
BIN_CANDIDATES=("$AGENTS_DIR/bin" "$HOME/.local/bin" "/usr/local/bin")
BIN_DIR=""
for d in "${BIN_CANDIDATES[@]}"; do
  case ":$PATH:" in *":$d:"*) BIN_DIR="$d"; break;; esac
done
[[ -n "$BIN_DIR" ]] || BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"
install -m 755 "$REPO_DIR/bin/optchat-new-profile" "$BIN_DIR/optchat-new-profile"

# --- 2. skill ----------------------------------------------------------------
mkdir -p "$SKILLS_DIR/optchat-profile"
install -m 644 "$REPO_DIR/skills/optchat-profile/SKILL.md" "$SKILLS_DIR/optchat-profile/SKILL.md"

# --- 3. global AGENTS.md section (idempotent) ---------------------------------
GLOBAL_AGENTS="$AGENTS_DIR/AGENTS.md"
BEGIN_MARKER='<!-- optchat-piweb-setup:begin -->'
END_MARKER='<!-- optchat-piweb-setup:end -->'
SECTION="$BEGIN_MARKER
## pi-optchat profiles

When the user asks to create a new optchat profile (e.g. \"create a new /optchat profile xxx\"),
follow the \`optchat-profile\` skill:

1. \`optchat-new-profile <name>\` — creates ~/.optchat/profiles/<name>/ with a model-pinned config.
2. In Pi Web: start a fresh session whose first message is \`/optchat profile <name>\` (or, for an
   agent that can, spawn_session(prompt=\"/optchat profile <name>\")) — a running session cannot
   be re-bound, binding only happens at session start while empty.
3. Tell the user to open that session and chat there.

Full procedure: ~/.agents/skills/optchat-profile/SKILL.md
$END_MARKER"

mkdir -p "$AGENTS_DIR"
touch "$GLOBAL_AGENTS"
if grep -qF "$BEGIN_MARKER" "$GLOBAL_AGENTS"; then
  # Replace the existing section in place.
  python3 - "$GLOBAL_AGENTS" "$BEGIN_MARKER" "$END_MARKER" "$SECTION" <<'PYEOF'
import sys
path, begin, end, section = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
text = open(path).read()
b, e = text.index(begin), text.index(end) + len(end)
open(path, "w").write(text[:b] + section + text[e:])
PYEOF
  echo "updated:  $GLOBAL_AGENTS (optchat section replaced)"
else
  { printf '\n%s\n' "$SECTION"; } >> "$GLOBAL_AGENTS"
  echo "appended: $GLOBAL_AGENTS (optchat section)"
fi

# --- summary ------------------------------------------------------------------
echo
echo "installed:"
echo "  script:  $BIN_DIR/optchat-new-profile"
echo "  skill:   $SKILLS_DIR/optchat-profile/SKILL.md"
echo "  agents:  $GLOBAL_AGENTS"
echo
echo "next steps:"
echo "  1. pi install npm:pi-optchat          (if not already installed)"
echo "  2. optchat-new-profile <name>         (create your first profile)"
echo "  3. new Pi Web session, first message:  /optchat profile <name>"
echo
if [[ "$BIN_DIR" == "$HOME/.local/bin" ]] && ! grep -qF "$HOME/.local/bin" "$HOME/.bashrc" 2>/dev/null; then
  echo "note: ~/.local/bin is not in your interactive shell PATH; add it, e.g.:"
  echo "  echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.bashrc"
fi
