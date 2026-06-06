# claude-code-mac-notify

> **macOS + Claude Code CLI 전용** — hook 기반 알림 도구

**macOS 의 Claude Code CLI** 가 **작업을 마치거나(Stop)** **내 입력을 기다릴 때(Notification)**
소리·데스크톱 배너·음성으로 알려줍니다.

터미널만 보고 있으면 Claude 가 끝났는지 알기 어려워서, Claude Code 의 hook 으로 알림을 붙이는 프로젝트입니다.

## 지원 환경

| 환경 | 지원 |
|---|---|
| macOS + Claude Code CLI (모든 터미널: Terminal.app, iTerm2, VS Code, Ghostty 등) | ✅ |
| Claude Desktop 앱 | ❌ (hook 미지원 — CLI/SDK 전용 기능) |
| Linux / Windows | ❌ (`afplay`·`osascript`·`say` 등 macOS 전용 명령 사용) |

## 동작

| 이벤트 | 의미 | 기본 사운드 | 음성 |
|---|---|---|---|
| `Stop` | Claude 답변 완료 | Glass | "작업 끝났어요" |
| `Notification` | 권한 승인/입력 대기 | Funk | "입력을 기다리고 있어요" |

기본은 **시스템 사운드(afplay)** + **데스크톱 배너(osascript)** 두 가지입니다.
음성(say)은 기본 꺼짐이며 `CLAUDE_NOTIFY_VOICE=1` 로 켤 수 있습니다.

### 중복 알림 방지 (debounce)

한 턴이 끝나면 Claude Code 가 `Stop`(완료)과 `Notification`(입력 대기)을 거의 동시에
쏘기 때문에 소리가 두 번 날 수 있습니다. 이를 막기 위해 **직전 알림으로부터 `DEBOUNCE`초
(기본 4초) 안에 들어온 두 번째 알림은 무시**합니다.

- 턴 끝의 중복(Stop+Notification) → **소리 1번만**
- 작업 중간의 단독 권한 요청 Notification → 간격이 크므로 **정상적으로 울림**

간격은 `CLAUDE_NOTIFY_DEBOUNCE=<초>` 로 조정합니다. `0` 으로 두면 항상 둘 다 울립니다.

## 설치

```bash
cd /path/to/claude-notify   # 이 저장소를 받아둔 위치
./install.sh
```

`~/.claude/settings.json` 의 `hooks` 에 `Stop`/`Notification` 항목을 추가하고,
기존 설정은 `settings.json.bak` 으로 백업합니다. **새 Claude Code 세션부터** 적용됩니다.

### 바로 테스트

```bash
./notify.sh stop
./notify.sh notification
```

## 끄기 / 되돌리기

```bash
./uninstall.sh        # settings.json 에서 우리 hook 만 제거
```

## 커스터마이징

### 사운드 / 문구 바꾸기

`notify.sh` 의 `case "$EVENT"` 블록에서 `SOUND` / `MESSAGE` / `VOICE` 를 수정.
사용 가능한 시스템 사운드 목록:

```bash
ls /System/Library/Sounds/      # Glass, Funk, Ping, Hero, Submarine, ...
```

### 일부만 켜기 (환경변수)

`~/.claude/settings.json` 의 command 를 `CLAUDE_NOTIFY_VOICE=0 "/path/notify.sh" stop`
처럼 바꾸거나, 셸 환경에 export 해두면 됩니다. 기본은 모두 켜짐(`1`).

| 변수 | 설명 |
|---|---|
| `CLAUDE_NOTIFY_SOUND=0` | 시스템 사운드 끄기 |
| `CLAUDE_NOTIFY_BANNER=0` | 데스크톱 배너 끄기 |
| `CLAUDE_NOTIFY_VOICE=0` | 음성 끄기 |
| `CLAUDE_NOTIFY_DEBOUNCE=4` | 중복 무시 간격(초). `0`=항상 울림 |

> 음성이 매번 나오는 게 거슬리면 `CLAUDE_NOTIFY_VOICE=0` 으로 두고 사운드만 쓰는 걸 추천.

## 요구 사항

- macOS (afplay / osascript / say 내장 사용)
- python3 (`/usr/bin/python3`) — settings.json 병합 및 hook JSON 파싱용

## 라이선스

[MIT](LICENSE)

## 참고한 비슷한 프로젝트

- [EryouHao/claude-code-sound-notification](https://github.com/EryouHao/claude-code-sound-notification)
- [RonitSachdev/ccnudge](https://github.com/RonitSachdev/ccnudge)
- [wyattjoh/claude-code-notification](https://github.com/wyattjoh/claude-code-notification)
- [varun86/awesome-claude-code-sounds](https://github.com/varun86/awesome-claude-code-sounds)
