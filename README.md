# Forge Discord

Forge로 작성한 Discord API v10 클라이언트입니다. REST 요청, Gateway 이벤트 스트림, 인터랙션 페이로드를 제공하며 전송에는 확장 Forge 표준 라이브러리를 사용합니다. Discord 로직은 `.fg`로 작성되어 있습니다.

## 봇 설정과 권한

[Developer Portal](https://discord.com/developers/applications)에서 애플리케이션의 Bot 토큰을 발급하고 아래의 `DISCORD_TOKEN` 설정에 넣습니다. Guild Install에는 `bot`, `applications.commands` 범위를 선택하고 서버에 설치합니다. Application ID와 봇 토큰은 서로 다른 값입니다. [공식 시작 안내](https://docs.discord.com/developers/quick-start/getting-started)를 참고하세요.

Gateway에 전달하는 intents는 수신할 이벤트에 맞게 선택합니다. `GUILD_MEMBERS`, `GUILD_PRESENCES`, `MESSAGE_CONTENT`는 Portal에서 활성화하고 필요한 경우 Discord 승인을 받아야 하는 특권 intent입니다. 모든 이벤트를 읽는 raw JSON 인터페이스도 intent나 권한 제한을 우회하지 않습니다. 특히 메시지 내용은 Discord의 예외 규칙에 해당하지 않으면 비어 있을 수 있습니다. 승인 기준과 이벤트별 비트는 [공식 Gateway 문서](https://docs.discord.com/developers/events/gateway#gateway-intents)를 확인하세요.

메시지에는 View Channel과 Send Messages, 임베드에는 Embed Links, 파일에는 Attach Files, 반응에는 상황에 따라 Read Message History와 Add Reactions가 필요합니다. 서버 관리 기능에는 해당 작업의 관리 권한이 필요하며 역할 계층과 채널별 권한도 적용됩니다. 음성에는 Connect와 Speak 권한 및 `GUILD_VOICE_STATES` intent가 필요합니다. [권한 문서](https://docs.discord.com/developers/topics/permissions)를 기준으로 필요한 권한을 부여하세요.

인터랙션은 최초 응답이나 지연 응답을 3초 안에 보내야 하고 후속 응답 토큰은 15분 동안 유효합니다. 지연이 예상되면 `interactions.defer()`로 응답한 뒤 후속 응답을 보냅니다. 이 라이브러리는 Gateway로 수신하므로 HTTP Interactions Endpoint를 별도로 설정할 필요가 없습니다. HTTP 방식의 서명 검증 서버는 제공하지 않습니다. [공식 응답 규칙](https://docs.discord.com/developers/interactions/receiving-and-responding)을 참고하세요.

## 기능 범위

아래에서 REST 경로 지원은 해당 경로와 JSON을 구성해 요청할 수 있다는 뜻이며, 각 Discord 기능을 실제 서버에서 모두 검증했다는 뜻은 아닙니다.

| 범주 | 인터페이스와 제한 |
| --- | --- |
| REST | `rest.request`로 API v10의 메서드·경로·JSON을 전달합니다. 응답과 오류를 직접 확인하며 전역 요청 제한 조정은 호출자가 담당합니다. |
| Gateway 원본 이벤트 | `gateway_client.poll`이 수신한 DISPATCH JSON을 그대로 반환합니다. 이벤트별 객체나 캐시는 없으며 intents와 Discord 전송 조건이 적용됩니다. |
| 메시지·임베드·파일·반응 | 메시지와 반응 경로 도우미, 파일 multipart 전송이 있습니다. 임베드 등 구조는 호출자가 JSON으로 작성합니다. |
| 명령·인터랙션·컴포넌트·모달 | 명령 등록, 응답, 후속 응답과 기본 페이로드 도우미가 있습니다. 수신 이벤트 분기와 복잡한 컴포넌트 JSON은 호출자가 작성합니다. |
| 서버 관리·채널·스레드·역할·멤버 | `rest.guild*`, `rest.channel*` 또는 `rest.request`로 해당 경로를 호출합니다. 권한 계산·역할 계층 검사·멤버 캐시는 제공하지 않습니다. |
| 웹훅·초대·감사 로그·자동 관리·예정 이벤트·투표 | 범용 REST 경로 및 JSON으로 접근하며 감사 로그 등의 경로 도우미와 `rest.poll_expire`가 있습니다. 각 기능 전용 객체 모델은 없습니다. |
| 상태·샤드 | `gateway.presence`와 `gateway_client.send_payload`로 상태를 보냅니다. 클라이언트 하나가 샤드 하나이며 샤드 배치와 Identify 제한 조정은 호출자 책임입니다. |
| 음성·음악 | 실험적 DAVE 음성 세션, Opus 송수신, FFmpeg 파일·URL 재생 및 대기열 제어가 있습니다. 로컬 가상 서버로 검증했으며 실제 Discord 음성 연결·재생은 미검증입니다. |

## 빌드와 테스트

핸들 소유권, 오류 반환값, multipart 및 음성 프레임 조건은 [API 사용 계약](docs/api-contracts.md)을 확인하세요. 지원 환경은 현재 POSIX 기반이며 확장 SDK에는 WebSocket·OpenSSL을 활성화한 libcurl 8.14 이상, OpenSSL, Opus, libsodium, libdave 및 해당 Forge 표준 라이브러리가 필요합니다. `make install`은 Forge 소스만 복사하며 SDK나 공유 라이브러리를 배포하지 않습니다. SDK의 `forge.link`에 기록된 라이브러리 경로를 유지하고 FFmpeg는 실행 시 PATH에서 찾을 수 있어야 합니다.

기본 Makefile은 형제 저장소 `../forge/build-discord`의 확장 SDK를 사용합니다. SDK 빌드와 필요한 libcurl, OpenSSL, Opus, libsodium 및 libdave 설정은 [확장 SDK 빌드 안내](docs/extended-network-sdk.md)를 참조하세요. 로컬 음성 통합 테스트에는 `openssl`, `ffmpeg`, `python3` 실행 파일도 필요하며 음악 디코딩에는 실행 중인 환경의 `ffmpeg`가 필요합니다. 다른 SDK를 쓰려면 `make test FORGE_ROOT=/path/to/sdk`로 지정합니다.

```sh
make test             # Forge 단위 테스트, Gateway 상태, 로컬 HTTP 및 오프라인 MLS/DAVE 테스트
make public-gateway   # 토큰 없이 Discord HTTPS와 Gateway HELLO 확인
make live             # 인증된 읽기 전용 REST, READY, RESUMED, heartbeat ACK 확인
make build/ping_bot   # 슬래시 명령 예제 컴파일
make build/register_ping # 명령 등록 도구 컴파일
```

`DISCORD_TOKEN` 환경 변수가 있으면 먼저 사용하고, 없으면 `tests/.env`를 읽습니다. `tests/.env.example`을 참고해 `DISCORD_TOKEN=...`을 설정하세요. 실제 파일은 Git에서 제외되며 토큰이나 응답 본문은 테스트 출력에 포함되지 않습니다. 환경 변수나 파일에 토큰이 없으면 `make live`는 실패를 반환합니다.

테스트용 `env.get(path, key)`는 임의 설정 키를 읽으며 비어 있지 않은 환경 변수를 우선합니다. `env.from_file(path, key)`는 파일만 읽습니다. `KEY=value`, `export KEY=value`, 등호 주변 공백, 한 줄 따옴표 값과 주석을 지원합니다. 따옴표 안의 `#`는 보존하며 변수 치환과 여러 줄 값은 지원하지 않습니다. 파일을 프로세스 환경에 주입하거나 셸로 실행하지 않습니다. `env.token`과 `env.token_from_file`도 계속 사용할 수 있습니다. 이 도우미는 `tests/env.fg`이므로 별도 테스트에서 가져올 때 `-I tests`가 필요합니다.

실제 서버 테스트에 필요한 값과 명령은 [실제 테스트 준비](docs/live-testing.md)를 참고하세요.

다른 프로젝트의 `.fg` 파일에서 `import rest;` 등으로 모듈을 가져올 수 있습니다. 확장 SDK 컴파일러에 `-I /path/to/forge-discord`와 SDK의 `--forge-root`, `--lib-dir`을 전달하세요. 예를 들어 소스 디렉터리를 설치하려면 `make install PREFIX=/chosen/prefix`를 실행하고 `-I /chosen/prefix/share/forge-discord`를 지정합니다. 설치 대상에는 라이브러리 `.fg` 파일만 포함됩니다.

## REST

`import rest;`로 가져옵니다. `rest.request(method, path, bot_token, json_body, timeout_ms)`는 요청 핸들을 반환합니다. `path`는 `/`로 시작하는 API v10 경로입니다. 빈 토큰은 인증 헤더를 생략하므로 공개 및 인터랙션 토큰 엔드포인트에도 사용할 수 있습니다. `rest.status`, `rest.headers`, `rest.body`, `rest.error`로 결과를 확인하고 반드시 `rest.close`로 해제하세요. 헤더와 오류 문자열은 핸들을 변경하거나 닫기 전까지만 유효합니다. HTTP 429는 `retry_after`를 밀리초로 올림하여 총 타임아웃 안에서 최대 세 번 재시도하며 최종 상태와 헤더를 호출자에게 남깁니다. 동시 요청이나 프로세스 간 전역 rate limit 조정은 호출자의 책임이며 통신 오류는 재시도하지 않습니다.

```forge
import rest;
native main {
    let response: int = rest.request("GET", "/gateway", "", "", 15000);
    if (response < 0) { return 1; }
    println(rest.status(response));
    rest.close(response);
    return 0;
}
```

`rest.send_message`, `rest.message`, `rest.reaction`, `rest.channel`, `rest.channel_resource`, `rest.guild`, `rest.guild_resource`, `rest.guild_special`, `rest.poll_expire`는 자주 쓰는 경로를 구성합니다. 예를 들어 역할이나 멤버는 `guild_resource`의 collection에 `roles` 또는 `members`를, 감사 로그는 `guild_special`에 `audit-logs`를 전달합니다. 그 밖의 Discord 엔드포인트는 `rest.request`에 문서의 경로와 JSON을 전달합니다. `rest.upload`는 파일 하나를 보냅니다. 여러 파일은 `rest.multipart`로 핸들을 만들고 `rest.add_file`을 반복한 뒤 `rest.perform`과 `rest.close`를 호출합니다. `rest.create`는 지정한 URL에 토큰을 전송할 수 있으므로 신뢰하는 테스트 서버에만 사용하세요.

## Gateway와 인터랙션

`gateway_client.open(wss_url, token, intents, shard_index, shard_count)`는 샤드 하나를 엽니다. `/gateway/bot`에서 받은 URL에 `/?v=10&encoding=json`을 붙여 전달하세요. `gateway_client.poll(client, timeout_ms)`를 계속 호출하면 DISPATCH 원본 JSON을 반환하고, 나머지 프레임은 내부에서 처리합니다. 상태 1은 연결 중 또는 활성, 3은 재연결 대기, 2는 오류 또는 복구 불가능한 종료입니다. 1 또는 3인 동안 계속 poll하고 종료 시 `gateway_client.close`를 호출하세요. HELLO, Identify, heartbeat/ACK 감시, 세션과 시퀀스 보존, Resume, Invalid Session 및 종료 코드 처리를 포함합니다. 서로 다른 샤드와 프로세스 사이의 Identify 제한은 호출자가 조정해야 합니다.

연결과 송신을 진행하려면 양수 `timeout_ms`로 poll해야 합니다. 0은 즉시 읽을 수 있는 입력만 확인하며 대기 중인 Identify, heartbeat, 재연결은 진행하지 않습니다. 따라서 0만 반복 호출하는 루프는 세션을 유지할 수 없습니다.

이벤트 문자열과 JSON 경로 결과는 현재 스레드의 Forge 문자열 arena에 저장됩니다. 장시간 실행하는 클라이언트는 이벤트를 처리한 뒤 각 poll 주기마다 `str_reset_arena()`를 호출해야 메모리가 계속 증가하지 않습니다. 이 호출은 해당 스레드의 모든 arena 문자열, 빌더와 뷰를 무효화하므로 필요한 값은 미리 별도 소유 버퍼에 복사하고 다른 코드가 유지 중인 문자열이 없는 때에만 호출하세요. Gateway 세션 자체는 소유 버퍼에 보관되어 reset 후에도 유효합니다. `examples/ping_bot.fg`에 이 주기가 있습니다.

`gateway.identify`, `gateway.resume`, `gateway.heartbeat`, `gateway.presence`, `gateway.voice_state`는 프로토콜 페이로드를 생성하고 `gateway_client.send_payload`로 전송합니다. `interactions`는 명령, 응답, 지연, 버튼, 모달 페이로드를 구성하며 `actions.register_command`, `actions.respond`, `actions.followup`은 해당 REST 호출을 수행합니다. `examples/ping_bot.fg`는 미리 등록된 `ping` 명령에 응답하는 예제입니다. `build/register_ping`을 직접 실행하면 전역 `ping` 명령을 등록하고 `build/ping_bot`을 실행할 수 있습니다. 실제 명령 등록이나 메시지 전송은 기본 테스트에서 수행하지 않습니다.

JSON 문자열 값은 `discord.quote`로 이스케이프하며, 임베드와 컴포넌트 등 임의의 구조는 호출자가 JSON으로 전달합니다. JSON 경로 읽기는 Forge 표준 라이브러리의 `fr_json_get_path_raw`에 의존합니다. `discord.json_string`은 그 결과의 이스케이프된 유니코드와 surrogate pair를 해독합니다. Forge 문자열은 NUL을 담을 수 없어 `\u0000`과 잘못된 문자열은 빈 문자열로 반환하며, 이는 빈 JSON 문자열과 구별되지 않습니다. 이 라이브러리는 모든 Discord 자원의 고수준 타입이나 사전 구축된 메서드를 제공하지 않습니다.

## 음성

음성 연결 및 재생은 실험 단계입니다. 오프라인 테스트는 가상의 두 사용자에 대해 서명된 MLS Add, commit, welcome과 DAVE 암호화·복호화 및 변조 거부를 확인합니다. 로컬 TLS WebSocket과 UDP 가상 서버로 discovery, 양방향 암호화 오디오, FFmpeg 음악 재생, 일시정지·재개·건너뛰기·정지와 재연결도 확인합니다. 실제 음성 채널 연결과 재생은 테스트하지 않았습니다.

Discord는 2026년 3월부터 일반 음성 통화에 DAVE 종단간 암호화를 요구합니다. Stage는 별도이며 이 구현에서 Stage 동작을 검증하지 않았습니다. [Discord의 DAVE 공지](https://discord.com/blog/bringing-dave-to-all-discord-platforms)와 [음성 프로토콜 문서](https://docs.discord.com/developers/topics/voice-connections)를 참고하세요. 확장 SDK의 libdave·Opus·libsodium 의존성을 유지해야 하며, 기존 설치 SDK만으로 이 모듈을 사용할 수 없습니다.

재생 소스는 FFmpeg가 직접 열 수 있는 파일이나 URL이어야 합니다. 음악 검색, YouTube 페이지 URL 추출, 서비스 로그인·DRM 해제 기능은 제공하지 않습니다. 소스 선택과 접근 허용 여부는 호출자가 관리해야 합니다.

음성 채널에 참가하려면 `gateway_client.send_payload`로 `gateway.voice_state(guild, channel, mute, deaf)`를 보낸 뒤, 같은 서버의 현재 봇 사용자와 채널에 해당하는 `VOICE_STATE_UPDATE`의 session ID와 `VOICE_SERVER_UPDATE`의 endpoint 및 token을 모두 받아 `voice.session_open(endpoint, guild, channel, user, session, token)`에 전달합니다. `voice.session_poll(state, timeout_ms)`를 반복해 handshake, heartbeat, DAVE 전환, 오디오 송신과 재연결을 진행하고 `voice.state_get(state, 19) == 4`에서 미디어가 준비되었는지 확인합니다. poll 실패는 음수이고 `voice.state_get(state, 18) == 2`는 실패하여 다시 참가해야 함을 뜻합니다. 사용 후 `voice.session_close`를 호출합니다.

`voice.session_enqueue(state, source)`는 로컬 파일 경로나 URL을 FFmpeg 대기열에 넣습니다. `voice.session_pause`, `voice.session_resume`, `voice.session_skip`, `voice.session_stop`으로 제어하며 재생을 진행하려면 계속 poll해야 합니다. 직접 인코딩한 Opus 프레임은 `voice.session_send_frame`으로 보낼 수 있습니다. 수신은 사용자별 `voice.session_receiver`를 만든 뒤 `voice.session_receive_packet`, `voice.packet_ssrc`, `voice.session_decode_packet`을 사용하고 패킷과 PCM 버퍼는 `buffer_free`, receiver는 `voice.session_receiver_free`로 해제합니다. SSRC와 사용자 ID의 연결은 호출자가 `voice.session_last_event`의 speaking 이벤트(op 5)를 이용해 관리해야 합니다. 마지막 이벤트 문자열은 다음 poll까지만 유효하므로 보관하려면 복사하세요.
