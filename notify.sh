#!/usr/bin/env bash
#
# claude-notify — Claude Code 이벤트 알림 (macOS)
#
# 사용:  notify.sh <event>
#   event = stop | notification | <기타>
#
# Claude Code hook 에서 호출됩니다. hook 은 stdin 으로 JSON 을 넘겨주는데,
# notification 이벤트의 경우 거기서 실제 메시지를 꺼내 배너에 표시합니다.
#
# 개별 토글(환경변수, 기본 모두 켜짐):
#   CLAUDE_NOTIFY_SOUND=0   시스템 사운드 끄기
#   CLAUDE_NOTIFY_BANNER=0  데스크톱 배너 끄기
#   CLAUDE_NOTIFY_VOICE=0   음성(say) 끄기
#
# 조용한 시간대 음소거 같은 확장은 아래 config 블록을 고치면 됩니다.

EVENT="${1:-stop}"

# --- hook 이 넘겨준 stdin JSON 읽기 (없을 수도 있음) ---------------------------
INPUT=""
if [ ! -t 0 ]; then
  INPUT="$(cat)"
fi

# --- 이벤트별 설정 ------------------------------------------------------------
TITLE="Claude Code"
case "$EVENT" in
  stop)
    SOUND="/System/Library/Sounds/Glass.aiff"
    MESSAGE="작업 완료"
    VOICE="작업 끝났어요"
    ;;
  notification)
    SOUND="/System/Library/Sounds/Funk.aiff"
    MESSAGE="입력을 기다리는 중"
    VOICE="입력을 기다리고 있어요"
    ;;
  *)
    SOUND="/System/Library/Sounds/Ping.aiff"
    MESSAGE="$EVENT"
    VOICE=""
    ;;
esac

# notification 이벤트면 JSON 에서 실제 메시지를 꺼내 배너 문구로 사용
if [ "$EVENT" = "notification" ] && [ -n "$INPUT" ]; then
  MSG="$(printf '%s' "$INPUT" | /usr/bin/python3 -c 'import sys,json
try:
    print(json.load(sys.stdin).get("message",""))
except Exception:
    pass' 2>/dev/null)"
  [ -n "$MSG" ] && MESSAGE="$MSG"
fi

# osascript 문자열 안전화: 큰따옴표/백슬래시 제거
SAFE_MESSAGE="${MESSAGE//\\/}"
SAFE_MESSAGE="${SAFE_MESSAGE//\"/}"
SAFE_TITLE="${TITLE//\"/}"

# --- Debounce: 짧은 시간 안에 들어온 두 번째 알림은 무시 ----------------------
# 턴이 끝나면 Stop 과 Notification(입력 대기)이 거의 동시에 발생해 소리가 두 번
# 나는데, 그중 먼저 온 것만 울리고 4초 안의 두 번째는 건너뜁니다. 작업 중간의
# 권한 요청처럼 단독으로 오는 Notification 은 직전 알림과 간격이 크므로 정상 동작.
DEBOUNCE="${CLAUDE_NOTIFY_DEBOUNCE:-4}"
LOCKDIR="/tmp/claude-notify.lock.d"
NOW="$(date +%s)"
if mkdir "$LOCKDIR" 2>/dev/null; then
  :                                   # 락을 처음 만든 첫 호출 → 통과
else
  LAST="$(stat -f %m "$LOCKDIR" 2>/dev/null || echo 0)"
  if [ "$((NOW - LAST))" -lt "$DEBOUNCE" ]; then
    exit 0                            # 직전 알림과 너무 가까움 → 건너뜀
  fi
fi
touch "$LOCKDIR" 2>/dev/null          # 이번 발생 시각 기록

# --- 토글 (기본 켜짐) ---------------------------------------------------------
DO_SOUND="${CLAUDE_NOTIFY_SOUND:-1}"
DO_BANNER="${CLAUDE_NOTIFY_BANNER:-1}"
DO_VOICE="${CLAUDE_NOTIFY_VOICE:-0}"   # 기본 꺼짐. 켜려면 CLAUDE_NOTIFY_VOICE=1

# --- 실행 (전부 백그라운드 → hook 이 곧바로 반환되도록) -----------------------
if [ "$DO_SOUND" = "1" ] && [ -f "$SOUND" ]; then
  afplay "$SOUND" >/dev/null 2>&1 &
fi

if [ "$DO_BANNER" = "1" ]; then
  osascript -e "display notification \"$SAFE_MESSAGE\" with title \"$SAFE_TITLE\"" >/dev/null 2>&1 &
fi

if [ "$DO_VOICE" = "1" ] && [ -n "$VOICE" ]; then
  say "$VOICE" >/dev/null 2>&1 &
fi

exit 0
