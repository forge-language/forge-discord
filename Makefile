FORGE_ROOT ?= ../forge/build-discord
FORGE ?= $(FORGE_ROOT)/bin/forge
FORGE_FLAGS ?= --forge-root $(FORGE_ROOT) --lib-dir $(FORGE_ROOT)/lib
PREFIX ?= /usr/local

.PHONY: test integration state-test mls-test voice-test ws-test voice-wss-test live public-gateway install clean FORCE
test: build/offline state-test integration mls-test voice-test ws-test voice-wss-test
	./build/offline

live: build/live
	./build/live

public-gateway: build/public_gateway
	./build/public_gateway

integration: build/http_server build/http_client
	rm -f build/http-ready; ./build/http_server & server=$$!; trap 'kill $$server 2>/dev/null || true' EXIT; for n in 1 2 3 4 5 6 7 8 9 10; do [ -f build/http-ready ] && break; sleep 0.1; done; ./build/http_client && wait $$server

state-test: build/gateway_state
	./build/gateway_state

mls-test: build/mls_roundtrip
	./build/mls_roundtrip

voice-test: build/voice_offline build/voice_mls
	./build/voice_offline
	./build/voice_mls

ws-test: build/ws_smoke build/fixture-cert.pem
	SSL_CERT_FILE=build/fixture-cert.pem ./build/ws_smoke

voice-wss-test: build/voice_wss build/fixture-cert.pem build/fixture.wav
	SSL_CERT_FILE=build/fixture-cert.pem ./build/voice_wss

build/offline: tests/offline.fg tests/env.fg discord.fg gateway.fg interactions.fg FORCE
	mkdir -p build
	$(FORGE) tests/offline.fg -I . -I tests $(FORGE_FLAGS) -o $@

build/live: tests/live.fg tests/env.fg discord.fg rest.fg gateway.fg gateway_client.fg FORCE
	mkdir -p build
	$(FORGE) tests/live.fg -I . -I tests $(FORGE_FLAGS) -o $@

build/http_server: tests/http_server.fg FORCE
	mkdir -p build
	$(FORGE) tests/http_server.fg -I . -I tests $(FORGE_FLAGS) -o $@

build/http_client: tests/http_client.fg rest.fg discord.fg FORCE
	mkdir -p build
	$(FORGE) tests/http_client.fg -I . -I tests $(FORGE_FLAGS) -o $@

build/public_gateway: examples/public_gateway.fg rest.fg discord.fg FORCE
	mkdir -p build
	$(FORGE) examples/public_gateway.fg -I . -I tests $(FORGE_FLAGS) -o $@

build/ping_bot: examples/ping_bot.fg tests/env.fg discord.fg rest.fg gateway.fg gateway_client.fg actions.fg interactions.fg FORCE
	mkdir -p build
	$(FORGE) examples/ping_bot.fg -I . -I tests $(FORGE_FLAGS) -o $@

build/register_ping: examples/register_ping.fg tests/env.fg discord.fg rest.fg actions.fg interactions.fg FORCE
	mkdir -p build
	$(FORGE) examples/register_ping.fg -I . -I tests $(FORGE_FLAGS) -o $@

build/gateway_state: tests/gateway_state.fg discord.fg rest.fg gateway.fg gateway_client.fg FORCE
	mkdir -p build
	$(FORGE) tests/gateway_state.fg -I . -I tests $(FORGE_FLAGS) -o $@

build/mls_roundtrip: tests/mls_roundtrip.fg tests/mls_fixture.fg FORCE
	mkdir -p build
	$(FORGE) tests/mls_roundtrip.fg -I . -I tests $(FORGE_FLAGS) -o $@

build/voice_offline: tests/voice_offline.fg voice.fg FORCE
	mkdir -p build
	$(FORGE) tests/voice_offline.fg -I . -I tests $(FORGE_FLAGS) -o $@

build/voice_mls: tests/voice_mls.fg tests/mls_fixture.fg voice.fg FORCE
	mkdir -p build
	$(FORGE) tests/voice_mls.fg -I . -I tests $(FORGE_FLAGS) -o $@

build/ws_smoke: tests/ws_smoke.fg tests/ws_peer.fg voice.fg FORCE
	mkdir -p build
	$(FORGE) tests/ws_smoke.fg -I . -I tests $(FORGE_FLAGS) -o $@

build/voice_wss: tests/voice_wss.fg tests/ws_peer.fg tests/mls_fixture.fg voice.fg FORCE
	mkdir -p build
	$(FORGE) tests/voice_wss.fg -I . -I tests $(FORGE_FLAGS) -o $@

build/fixture-cert.pem: FORCE
	mkdir -p build
	openssl req -x509 -newkey rsa:2048 -nodes -keyout build/fixture-key.pem -out $@ -subj /CN=localhost -addext subjectAltName=DNS:localhost -days 1 -quiet

build/fixture.wav:
	mkdir -p build
	ffmpeg -y -f lavfi -i sine=frequency=440:duration=2 -ar 48000 -ac 2 $@

install:
	install -d "$(DESTDIR)$(PREFIX)/share/forge-discord"
	install -m 644 *.fg "$(DESTDIR)$(PREFIX)/share/forge-discord/"

clean:
	rm -rf build
