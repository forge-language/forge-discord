# API 사용 계약

## REST 결과와 파일 업로드

`rest.request`와 `rest.upload`의 음수 반환은 핸들 생성 실패입니다. 0 이상의 반환값은 소유 핸들이며 통신이나 HTTP 성공을 뜻하지 않습니다. 모든 반환 경로에서 `rest.status(handle)`, `rest.error(handle)`를 확인한 뒤 `rest.close(handle)`로 해제하세요. `rest.perform`이 0을 반환해도 최종 HTTP 상태가 429일 수 있습니다. 성공 여부는 해당 엔드포인트가 요구하는 HTTP 상태로 판단합니다.

`rest.upload(method, path, token, payload, file, content_type, timeout_ms)`는 API 경로와 파일 하나를 받습니다. 여러 파일은 다음 순서로 구성합니다.

1. `rest.multipart(method, url, token, payload)`로 핸들을 만듭니다. `url`은 절대 URL입니다.
2. `rest.add_file(handle, "files[0]", path, content_type)` 등을 호출하고 각각의 오류를 확인합니다.
3. 필요하면 `rest.add_header(handle, header)`로 헤더를 추가합니다.
4. `rest.perform(handle, timeout_ms)` 후 결과를 확인하고 닫습니다.

`rest.create`와 `rest.multipart`는 전달받은 URL에 인증 토큰을 보낼 수 있습니다. 호출자가 신뢰하는 URL만 전달하세요. 일반 Discord 호출은 호스트를 고정하는 `rest.request`를 사용합니다.

`guild_resource`와 `channel_resource`의 collection은 소문자 a-z로만 구성하며 ID는 숫자 문자열입니다. `guild_special`은 `audit-logs`, `auto-moderation/rules`, `scheduled-events`만 허용합니다. `rest.message`는 메시지 ID가 필요합니다. 메시지 목록, 쿼리 문자열, 다른 중첩 경로는 `rest.request("GET", "/channels/채널ID/messages?limit=10", token, "", timeout_ms)`처럼 구성하세요.

## 이벤트와 인터랙션

`gateway_client.poll`은 opcode 0 DISPATCH의 원본 JSON만 반환합니다. `t`는 이벤트 이름, `d`는 이벤트 데이터, `s`는 시퀀스입니다. 이벤트 이름으로 분기하고 `d`에서 필요한 필드를 읽습니다. 이벤트별 콜백과 자원 캐시는 제공하지 않습니다. 빈 문자열은 타임아웃, 제어 프레임 처리, 재연결 대기 또는 오류일 수 있으므로 매번 `gateway_client.status`도 확인하세요. 상태 2는 종료 또는 복구 불가능한 오류, 1과 3은 계속 poll할 상태입니다.

`actions.register_command(token, application, guild, command_json, timeout_ms)`에서 빈 guild는 전역 명령, 숫자 guild ID는 서버 전용 명령입니다. `actions.respond(interaction, interaction_token, response_json, timeout_ms)`로 `interactions.defer()`를 보내고, 작업이 끝나면 `actions.followup("PATCH", application, interaction_token, "@original", message_json, timeout_ms)`로 원래 응답을 수정할 수 있습니다. 이 함수들의 결과도 REST 핸들이므로 상태 확인과 해제가 필요합니다.

`actions.followup(method, application, interaction_token, message_id, body, timeout_ms)`에서 빈 message_id는 웹훅 컬렉션, 숫자 ID 또는 `@original`은 개별 메시지입니다. `interactions.button`은 스타일 1~4만 지원하며 `interactions.modal`의 components는 호출자가 JSON으로 작성합니다. 테스트의 페이로드 검증이 실제 Discord 인터랙션 전체 흐름의 검증을 뜻하지는 않습니다.

`gateway.presence(status, activity, activity_type, afk)`는 online, idle, dnd, invisible 상태와 최대 한 개 활동을 생성합니다. since는 null이며 activity_type 값의 유효성은 호출자가 확인합니다. `gateway_client.send_payload(client, gateway.presence("online", "Forge", 0, 0))`로 전송합니다. 송신 rate limit 큐는 없으며 실제 presence 변경과 다중 샤드 운영은 이번 검증 범위에 포함하지 않았습니다. Identify에는 `shards >= 1`, `0 <= shard < shards`가 필요합니다.

## 소유권과 음성

각 핸들은 한 번에 한 스레드에서만 사용합니다. 독립 핸들은 동시에 사용할 수 있습니다.

| 값 | 해제 함수 |
| --- | --- |
| REST 및 actions 반환 핸들 | `rest.close` |
| Gateway 클라이언트 | `gateway_client.close` |
| 음성 세션 | `voice.session_close` |
| 별도로 생성한 음성 receiver | `voice.session_receiver_free` |
| 호출자 소유 Opus 프레임·수신 패킷·디코딩 PCM 버퍼 | `buffer_free` |

`session_close`가 별도로 생성한 receiver를 해제하지는 않습니다. `session_send_frame`도 입력 프레임을 해제하지 않습니다. arena 문자열의 수명과 reset 규칙은 README를 참고하세요.

`voice.session_poll`은 0이면 프레임 없이 진행 또는 대기, 1이면 프레임 처리, -1이면 실패입니다. `voice.session_receive_packet`은 0이면 타임아웃, -1이면 실패, 양수이면 소유 패킷 버퍼를 반환합니다. 디코딩한 PCM은 48 kHz stereo s16le입니다.

`voice.session_send_frame`으로 직접 보내는 Opus는 960 samples/20 ms 프레임을 전제로 합니다. 호출자가 20 ms 송신 간격과 입력 버퍼 해제를 관리해야 합니다. 음악 대기열의 enqueue 성공은 파일이나 URL의 디코딩 성공을 보장하지 않습니다. FFmpeg 실행·디코딩 실패는 음성 세션 실패로 전파될 수 있으며 자동으로 잘못된 트랙만 건너뛰는 동작은 보장하지 않습니다.
