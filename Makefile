SHELL := /bin/zsh

FLUTTER ?= flutter
DART ?= dart

CONFIG ?= config.json
ANDROID_DEVICE ?= android
IOS_DEVICE ?=
SOURCE_IMAGE ?= assets/branding/ghosteye-icon-source-ai.png

CONFIG_ARGS := $(if $(wildcard $(CONFIG)),--dart-define-from-file=$(CONFIG),)
FORMAT_DIRS := lib test tool packages/ghosteye_frame_ffi/lib
SCAN_DIRS := lib test android ios tool packages/ghosteye_frame_ffi

.PHONY: help bootstrap doctor analyze test verify format fix clean pub-outdated \
	run-android run-ios build-apk-debug build-ios-debug brand-assets todo \
	bundle-ids docs

help:
	@printf "Ghosteye maintainer commands\n\n"
	@printf "Setup and verification:\n"
	@printf "  make bootstrap        flutter pub get\n"
	@printf "  make doctor           flutter doctor -v\n"
	@printf "  make analyze          flutter analyze\n"
	@printf "  make test             flutter test\n"
	@printf "  make verify           flutter analyze && flutter test\n"
	@printf "  make format           dart format %s\n" "$(FORMAT_DIRS)"
	@printf "  make fix              dart fix --apply\n"
	@printf "  make clean            flutter clean and remove local build outputs\n"
	@printf "  make pub-outdated     flutter pub outdated\n\n"
	@printf "Run and build:\n"
	@printf "  make run-android      flutter run -d %s %s\n" "$(ANDROID_DEVICE)" "$(CONFIG_ARGS)"
	@printf "  make run-ios IOS_DEVICE=<physical-device-id>\n"
	@printf "  make build-apk-debug  flutter build apk --debug\n"
	@printf "  make build-ios-debug  flutter build ios --debug --no-codesign\n\n"
	@printf "Repo diagnostics:\n"
	@printf "  make brand-assets     regenerate icons and launch assets from %s\n" "$(SOURCE_IMAGE)"
	@printf "  make todo             search repo TODO/FIXME markers\n"
	@printf "  make bundle-ids       search remaining example app identifiers\n"
	@printf "  make docs             print the core repo docs to keep in sync\n"

bootstrap:
	$(FLUTTER) pub get

doctor:
	$(FLUTTER) doctor -v

analyze:
	$(FLUTTER) analyze

test:
	$(FLUTTER) test

verify:
	$(FLUTTER) analyze
	$(FLUTTER) test

format:
	$(DART) format $(FORMAT_DIRS)

fix:
	$(DART) fix --apply

clean:
	$(FLUTTER) clean
	rm -rf build ios/build

pub-outdated:
	$(FLUTTER) pub outdated

run-android:
	$(FLUTTER) run -d $(ANDROID_DEVICE) $(CONFIG_ARGS)

run-ios:
	@if [ -z "$(IOS_DEVICE)" ]; then \
		echo "Set IOS_DEVICE=<physical-device-id> before running this target."; \
		exit 1; \
	fi
	$(FLUTTER) run -d "$(IOS_DEVICE)" $(CONFIG_ARGS)

build-apk-debug:
	$(FLUTTER) build apk --debug

build-ios-debug:
	$(FLUTTER) build ios --debug --no-codesign

brand-assets:
	$(DART) run tool/generate_brand_assets.dart --source=$(SOURCE_IMAGE)

todo:
	@rg -n "TODO|FIXME|XXX|HACK|TBD" $(SCAN_DIRS) -g '!build/**' -g '!ios/build/**' -g '!packages/ghosteye_frame_ffi/example/**' || true

bundle-ids:
	@rg -n "com\\.example|PRODUCT_BUNDLE_IDENTIFIER|applicationId" android ios packages/ghosteye_frame_ffi -g '!build/**' -g '!ios/build/**' -g '!packages/ghosteye_frame_ffi/example/**' || true

docs:
	@printf "README.md\n"
	@printf "CONTRIBUTING.md\n"
	@printf "plan.md\n"
	@printf "roadmap.md\n"
	@printf "agents.md\n"
	@printf "packages/ghosteye_frame_ffi/README.md\n"
