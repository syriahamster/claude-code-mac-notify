#!/usr/bin/env bash
#
# claude-notify 제거 스크립트
#   settings.json 의 hooks 에서 notify.sh 를 가리키는 항목만 제거합니다.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NOTIFY="$SCRIPT_DIR/notify.sh"
SETTINGS="$HOME/.claude/settings.json"

[ -f "$SETTINGS" ] || { echo "settings.json 이 없습니다. 할 일 없음."; exit 0; }

cp "$SETTINGS" "$SETTINGS.bak"

NOTIFY="$NOTIFY" SETTINGS="$SETTINGS" /usr/bin/python3 - <<'PY'
import json, os

settings_path = os.environ["SETTINGS"]
notify = os.environ["NOTIFY"]

with open(settings_path) as f:
    data = json.load(f)

hooks = data.get("hooks", {})

def clean(lst):
    out = []
    for group in lst or []:
        kept = [h for h in group.get("hooks", [])
                if notify not in h.get("command", "")]
        if kept:
            g = dict(group); g["hooks"] = kept; out.append(g)
    return out

for event in ("Stop", "Notification"):
    if event in hooks:
        cleaned = clean(hooks[event])
        if cleaned:
            hooks[event] = cleaned
        else:
            del hooks[event]

if not hooks:
    data.pop("hooks", None)

with open(settings_path, "w") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write("\n")

print("제거 완료.")
PY
