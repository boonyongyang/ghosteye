# bash is available by default on macOS and Ubuntu CI; recipes stay POSIX-sh
# compatible so no extra shell needs to be installed.
SHELL := /bin/bash

FLUTTER ?= flutter
DART ?= dart

CONFIG ?= config.json
ANDROID_DEVICE ?= android
IOS_DEVICE ?=
DEVICE ?=
MODEL_PATH ?=
SOURCE_IMAGE ?= assets/branding/ghosteye-icon-source-ai.png

CONFIG_ARGS := $(if $(wildcard $(CONFIG)),--dart-define-from-file=$(CONFIG),)
DEVICE_ARGS := $(if $(DEVICE),-d $(DEVICE),)
MODEL_PATH_ARGS := $(if $(MODEL_PATH),--dart-define=GHOSTEYE_GEMMA_MODEL_PATH="$(MODEL_PATH)",)
FORMAT_DIRS := lib test tool packages/ghosteye_frame_ffi/lib
SCAN_DIRS := lib test android ios tool packages/ghosteye_frame_ffi

.PHONY: help bootstrap doctor devices emulators analyze test verify benchmark format fix \
	clean pub-outdated config-copy config-check config-example run run-config \
	run-local-model run-android run-android-local-model run-ios \
	run-ios-local-model logs build-apk-debug build-ios-debug build-web-debug \
	brand-assets todo bundle-ids docs docs-audit

help:
	@printf "Ghosteye maintainer commands\n\n"
	@printf "Setup:\n"
	@printf "  make bootstrap        flutter pub get\n"
	@printf "  make doctor           flutter doctor -v\n"
	@printf "  make devices          list connected Flutter devices\n"
	@printf "  make emulators        list available Flutter emulators\n"
	@printf "  make config-copy      create %s from config.json.example if missing\n" "$(CONFIG)"
	@printf "  make config-check     show whether %s will be used\n" "$(CONFIG)"
	@printf "  make config-example   print the checked-in model config template\n\n"
	@printf "Verification:\n"
	@printf "  make analyze          flutter analyze\n"
	@printf "  make test             flutter test\n"
	@printf "  make verify           flutter analyze && flutter test\n"
	@printf "  make benchmark        run the host Dart-vs-FFI preprocessing benchmark\n"
	@printf "  make format           dart format %s\n" "$(FORMAT_DIRS)"
	@printf "  make fix              dart fix --apply\n"
	@printf "  make clean            flutter clean and remove local build outputs\n"
	@printf "  make pub-outdated     flutter pub outdated\n\n"
	@printf "Run and build:\n"
	@printf "  make run              flutter run %s\n" "$(CONFIG_ARGS)"
	@printf "  make run DEVICE=<id>  flutter run -d <id> %s\n" "$(CONFIG_ARGS)"
	@printf "  make run-config       require and run with %s\n" "$(CONFIG)"
	@printf "  make run-local-model MODEL_PATH=/absolute/path/model.litertlm\n"
	@printf "  make run-android      flutter run -d %s %s\n" "$(ANDROID_DEVICE)" "$(CONFIG_ARGS)"
	@printf "  make run-android-local-model MODEL_PATH=/absolute/path/model.litertlm\n"
	@printf "  make run-ios IOS_DEVICE=<physical-device-id>\n"
	@printf "  make run-ios-local-model IOS_DEVICE=<physical-device-id> MODEL_PATH=/absolute/path/model.litertlm\n"
	@printf "  make logs DEVICE=<id> flutter logs for a connected device\n"
	@printf "  make build-apk-debug  flutter build apk --debug\n"
	@printf "  make build-ios-debug  flutter build ios --debug --no-codesign\n"
	@printf "  make build-web-debug  flutter build web --debug\n\n"
	@printf "Repo diagnostics:\n"
	@printf "  make brand-assets     regenerate icons and launch assets from %s\n" "$(SOURCE_IMAGE)"
	@printf "  make todo             search repo TODO/FIXME markers\n"
	@printf "  make bundle-ids       search remaining shipping app identifiers\n"
	@printf "  make docs-audit       check markdown for absolute local filesystem links\n"
	@printf "  make docs             print the core repo docs to keep in sync\n"

bootstrap:
	$(FLUTTER) pub get

doctor:
	$(FLUTTER) doctor -v

devices:
	$(FLUTTER) devices

emulators:
	$(FLUTTER) emulators

analyze:
	$(FLUTTER) analyze

test:
	$(FLUTTER) test

verify:
	$(FLUTTER) analyze
	$(FLUTTER) test

benchmark:
	$(FLUTTER) test benchmark/preprocessing_benchmark.dart

format:
	$(DART) format $(FORMAT_DIRS)

fix:
	$(DART) fix --apply

clean:
	$(FLUTTER) clean
	rm -rf build ios/build

pub-outdated:
	$(FLUTTER) pub outdated

config-copy:
	@if [ -f "$(CONFIG)" ]; then \
		echo "$(CONFIG) already exists."; \
	else \
		cp config.json.example "$(CONFIG)"; \
		echo "Created $(CONFIG). Edit it with your managed model URL/token before running."; \
	fi

config-check:
	@if [ -f "$(CONFIG)" ]; then \
		echo "Using $(CONFIG) via --dart-define-from-file=$(CONFIG)."; \
	else \
		echo "No $(CONFIG) found. Run make config-copy, pass MODEL_PATH=..., or import a model in-app."; \
	fi

config-example:
	@cat config.json.example

run:
	$(FLUTTER) run $(DEVICE_ARGS) $(CONFIG_ARGS)

run-config:
	@if [ ! -f "$(CONFIG)" ]; then \
		echo "No $(CONFIG) found. Run make config-copy first."; \
		exit 1; \
	fi
	$(FLUTTER) run $(DEVICE_ARGS) --dart-define-from-file=$(CONFIG)

run-local-model:
	@if [ -z "$(MODEL_PATH)" ]; then \
		echo "Set MODEL_PATH=/absolute/path/to/model.litertlm or model.task."; \
		exit 1; \
	fi
	$(FLUTTER) run $(DEVICE_ARGS) $(MODEL_PATH_ARGS)

run-android:
	$(FLUTTER) run -d $(ANDROID_DEVICE) $(CONFIG_ARGS)

run-android-local-model:
	@if [ -z "$(MODEL_PATH)" ]; then \
		echo "Set MODEL_PATH=/absolute/path/to/model.litertlm or model.task."; \
		exit 1; \
	fi
	$(FLUTTER) run -d $(ANDROID_DEVICE) $(MODEL_PATH_ARGS)

run-ios:
	@if [ -z "$(IOS_DEVICE)" ]; then \
		echo "Set IOS_DEVICE=<physical-device-id> before running this target."; \
		exit 1; \
	fi
	$(FLUTTER) run -d "$(IOS_DEVICE)" $(CONFIG_ARGS)

run-ios-local-model:
	@if [ -z "$(IOS_DEVICE)" ]; then \
		echo "Set IOS_DEVICE=<physical-device-id> before running this target."; \
		exit 1; \
	fi
	@if [ -z "$(MODEL_PATH)" ]; then \
		echo "Set MODEL_PATH=/absolute/path/to/model.litertlm or model.task."; \
		exit 1; \
	fi
	$(FLUTTER) run -d "$(IOS_DEVICE)" $(MODEL_PATH_ARGS)

logs:
	@if [ -z "$(DEVICE)" ]; then \
		echo "Set DEVICE=<device-id> before running this target."; \
		exit 1; \
	fi
	$(FLUTTER) logs -d "$(DEVICE)"

build-apk-debug:
	$(FLUTTER) build apk --debug

build-ios-debug:
	$(FLUTTER) build ios --debug --no-codesign

build-web-debug:
	$(FLUTTER) build web --debug

brand-assets:
	$(DART) run tool/generate_brand_assets.dart --source=$(SOURCE_IMAGE)

todo:
	@rg -n "TODO|FIXME|XXX|HACK|TBD" $(SCAN_DIRS) -g '!build/**' -g '!ios/build/**' -g '!packages/ghosteye_frame_ffi/example/**' || true

bundle-ids:
	@rg -n "com\\.example|PRODUCT_BUNDLE_IDENTIFIER|applicationId" android/app ios/Runner ios/Runner.xcodeproj -g '!build/**' -g '!ios/build/**' || true

docs-audit:
	@if rg -n "\\]\\((/Users/|file://|[A-Za-z]:[/\\\\])" . -g '*.md' -g '!build/**' -g '!ios/build/**'; then \
		echo "Found absolute local filesystem links in checked-in Markdown."; \
		exit 1; \
	else \
		echo "No absolute local filesystem links found in checked-in Markdown."; \
	fi

docs:
	@printf "README.md\n"
	@printf "CONTRIBUTING.md\n"
	@printf "plan.md\n"
	@printf "roadmap.md\n"
	@printf "agents.md\n"
	@printf "packages/ghosteye_frame_ffi/README.md\n"
