#!/bin/bash
# Usage: gen.sh <name> <common-prompt> <specific-prompt> [ref.png ...]
# Writes $YARD_ART_DIR/raw/<name>.png using the Codex CLI image tool (bundled with ChatGPT.app).
set -u
X=/Applications/ChatGPT.app/Contents/Resources/codex-cli/CodexCLI.app/Contents/MacOS/codex
D=${YARD_ART_DIR:?set YARD_ART_DIR to a working folder holding prompts/, raw/ and the reference PNGs}
name=$1; common=$2; spec=$3; shift 3
args=()
for r in "$@"; do args+=(-i "$D/$r"); done
{ cat "$D/prompts/$common"; echo; cat "$D/prompts/$spec"; echo; echo "OUTPUT PATH: $D/raw/$name.png"; } \
  | "$X" exec --skip-git-repo-check --ephemeral -s workspace-write -C "$D" "${args[@]}" -o "$D/raw/$name.log.txt" - > "$D/raw/$name.out" 2>&1
ls -la "$D/raw/$name.png" 2>&1
