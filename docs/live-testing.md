# 실제 Discord 테스트 준비

프로젝트 루트의 `tests/.env`를 편집합니다. 없다면 `tests/.env.example`을 복사하세요. 기존 파일에는 필요한 항목만 추가하며 토큰을 채팅이나 테스트 출력에 붙여 넣지 않습니다.

```dotenv
DISCORD_TOKEN=봇_토큰
DISCORD_GUILD_ID=테스트_서버_ID
DISCORD_TEXT_CHANNEL_ID=테스트_텍스트_채널_ID
DISCORD_VOICE_CHANNEL_ID=테스트_음성_채널_ID
```

봇 토큰은 Developer Portal의 Bot 페이지에서 발급합니다. 나머지 ID는 Discord 설정의 개발자 모드를 켠 뒤 서버·채널에서 ID 복사로 얻습니다. 환경에 설정된 비어 있지 않은 `DISCORD_TOKEN`은 파일 값을 덮어씁니다. 이 파일은 Git에서 제외됩니다. `.env.example`과 fixture에는 실제 토큰을 넣지 마세요.

| 확인할 동작 | 필요한 것 | 현재 실행 방법 |
| --- | --- | --- |
| 인증 REST, Gateway READY·Resume·heartbeat ACK | 봇 토큰, 인터넷 | 루트에서 `make live`. 이 테스트는 intents 0으로 연결하므로 메시지 내용 intent나 채널 ID가 필요 없습니다. |
| 슬래시 명령과 응답 | 토큰, 테스트 서버 설치, `bot`·`applications.commands` 범위 | `make build/register_ping build/ping_bot` 후 `./build/register_ping`으로 전역 ping 명령을 등록하고 `./build/ping_bot` 실행, Discord에서 `/ping` 호출. 등록은 실제 애플리케이션 설정을 변경합니다. |
| 메시지·임베드·첨부·반응 | 테스트 텍스트 채널 ID, View Channel·Send Messages 및 기능별 권한 | 현재 자동 라이브 테스트 없음. REST 도우미로 보낸 뒤 Discord에서 결과 확인하는 테스트를 추가해야 합니다. |
| 컴포넌트·모달·후속 응답 | 서버에 설치한 봇과 실행 중인 Gateway 루프, 사람이 누르거나 제출할 UI | 현재 자동 라이브 테스트 없음. 상호작용을 발생시켜 응답 기한과 반환 내용을 확인해야 합니다. |
| 서버·역할·멤버·채널·스레드 관리 | 테스트 서버 ID, 기능별 관리 권한, 적용 가능한 역할 계층 | 전용 라이브 테스트 없음. 실제 자원을 변경하므로 별도 테스트 서버에서 생성·수정·정리 과정을 작성해야 합니다. |
| 웹훅·초대·감사 로그·자동 관리·예정 이벤트·투표 | 해당 자원·서버·채널 ID와 작업별 권한 | 범용 REST로 접근 가능하지만 기능별 라이브 테스트는 추가해야 합니다. 일부 OAuth 전용 API는 봇 토큰으로 호출할 수 없습니다. |
| presence·다중 샤드 | 토큰, `/gateway/bot` 세션 제한과 shard 설정 | 전용 라이브 테스트 없음. 실제 상태 표시와 샤드별 이벤트 수신을 확인해야 합니다. |
| 실제 음성·음악 | 서버·음성 채널 ID, Connect·Speak, `GUILD_VOICE_STATES`, 실행 중인 Gateway, 봇과 함께 입장할 청취자, 재생 파일 | 전용 라이브 실행 도구 없음. Gateway에서 얻은 음성 session·endpoint·token으로 음성 세션을 열어 poll하는 테스트를 추가해야 합니다. |

현재 ID 세 항목은 테스트 작성에 사용할 설정이며 기존 `make live`나 ping 예제가 자동으로 읽지는 않습니다. 필요한 테스트에서 `env.get("tests/.env", "DISCORD_VOICE_CHANNEL_ID")`와 같이 읽습니다. Application ID는 등록 예제가 토큰으로 조회하므로 별도로 설정할 필요가 없습니다.

음성 테스트에는 확장 SDK와 libdave·Opus·libsodium 및 PATH의 FFmpeg가 필요합니다. 먼저 `make test`로 로컬 암호화·가상 음성 서버 테스트가 통과하는지 확인하세요. 실제 음악 테스트에는 FFmpeg가 읽을 수 있는 파일 또는 직접 미디어 URL을 준비하고 청취자가 소리·일시정지·재개·건너뛰기·정지를 확인해야 합니다. 로컬 테스트 통과가 Discord 서버와의 DAVE 호환성을 보장하지는 않습니다.

메시지·멤버·presence 이벤트가 필요하면 해당 intent를 코드에서 선택하고 특권 intent는 Portal 활성화 및 필요한 승인을 확인하세요. [공식 Gateway 안내](https://docs.discord.com/developers/events/gateway)와 [권한 안내](https://docs.discord.com/developers/topics/permissions)를 참고하세요.
