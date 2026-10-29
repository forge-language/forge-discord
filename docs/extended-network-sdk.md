# 확장 SDK 빌드

이 저장소는 Discord의 Forge 모듈과 테스트를 포함합니다. 확장 SDK 자체는 포함하지 않습니다. 기존 배포 Forge SDK에는 필요한 네트워크·미디어 API가 없으므로 관련 확장을 포함한 `forge`와 `forge-stdlib` 소스가 필요합니다. 현재 로컬에서 검증한 SDK 경로는 형제 저장소의 `../forge/build-discord`입니다. 이 저장소만 복제했다고 SDK 확장까지 설치되는 것은 아닙니다.

필요한 의존성은 WebSocket과 OpenSSL을 활성화한 libcurl 8.14 이상, OpenSSL, Opus, libsodium, libdave의 헤더와 라이브러리입니다. 현재 구현은 POSIX 소켓과 프로세스 API를 사용합니다. 음악 디코딩에는 실행 시 PATH의 FFmpeg가 필요하며 로컬 테스트는 Python 3와 openssl 실행 파일도 사용합니다.

확장한 Forge 소스 루트에서 의존성 설치 위치에 맞춰 빌드합니다. 아래 prefix는 이 개발 환경의 예시이며 각 설치 위치로 바꾸세요.

```sh
cmake -S . -B build-discord \
  -DFORGE_STDLIB_SOURCE_DIR="$PWD/../forge-stdlib" \
  -DFORGE_ENABLE_EXTENDED_NETWORK=ON \
  -DCMAKE_PREFIX_PATH="$HOME/.local/share/forge-discord-deps/curl;$HOME/.local/share/forge-discord-deps/voice/usr;$HOME/.local/share/forge-discord-deps/dave"
cmake --build build-discord -j4
ctest --test-dir build-discord --output-on-failure
```

그 다음 이 저장소 루트에서 `make test FORGE_ROOT=/확장/SDK/경로`로 확인합니다. 생성된 `forge.link`는 선택한 라이브러리와 런타임 검색 경로를 기록하므로 해당 의존성 파일을 유지해야 합니다. `make install`은 `.fg` 파일만 설치하며 SDK나 의존성 바이너리를 복사하지 않습니다.
