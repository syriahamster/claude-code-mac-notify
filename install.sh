#!/usr/bin/env bash
#
# claude-notify 설치 스크립트
#   ~/.claude/settings.json 의 hooks 에 Stop / Notification 항목을 추가합니다.
#   기존 설정은 settings.json.bak 으로 백업합니다.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NOTIFY="$SCRIPT_DIR/notify.sh"
SETTINGS="$HOME/.claude/settings.json"

chmod +x "$NOTIFY"
mkdir -p "$HOME/.claude"
[ -f "$SETTINGS" ] || echo '{}' > "$SETTINGS"

cp "$SETTINGS" "$SETTINGS.bak"
echo "백업: $SETTINGS.bak"

NOTIFY="$NOTIFY" SETTINGS="$SETTINGS" /usr/bin/python3 - <<'PY'
import json, os

settings_path = os.environ["SETTINGS"]
notify = os.environ["NOTIFY"]

with open(settings_path) as f:
    try:
        data = json.load(f)
    except Exception:
        data = {}

hooks = data.setdefault("hooks", {})

def entry(event):
    return {"hooks": [{"type": "command", "command": f'"{notify}" {event}'}]}

# 우리 notify.sh 를 가리키는 항목만 제거 후 재등록 (중복 방지)
def without_ours(lst):
    out = []
    for group in lst or []:
        kept = [h for h in group.get("hooks", [])
                if notify not in h.get("command", "")]
        if kept:
            g = dict(group); g["hooks"] = kept; out.append(g)
    return out

hooks["Stop"] = without_ours(hooks.get("Stop")) + [entry("stop")]
hooks["Notification"] = without_ours(hooks.get("Notification")) + [entry("notification")]

with open(settings_path, "w") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write("\n")

print("등록 완료: Stop, Notification")
PY

echo
echo "완료! 새 Claude Code 세션부터 적용됩니다."
echo "테스트:  \"$NOTIFY\" stop"
