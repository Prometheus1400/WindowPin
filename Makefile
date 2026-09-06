# WindowPin — pin windows above other apps.
#
# Release pipeline delegated to the shared `release.mk` from
# PerpetualBeta/jorvik-release. SPM project, embedded Sparkle,
# dual-ship (.zip + .pkg).

BUNDLE_NAME      := WindowPin
BUNDLE_TYPE      := app
PRODUCT_NAME     := WindowPin.app
BUNDLE_ID        := cc.jorviksoftware.WindowPin
BUILD_SYSTEM     := spm
SPM_PRODUCT      := WindowPin

PACKAGE_TYPE     := zip
ALSO_SHIP_PKG    := true
EMBEDDED_FRAMEWORKS := Sparkle
ENTITLEMENTS     := WindowPin.entitlements

include ../jorvik-release/release.mk

# Ship the controller beside the app executable so it is signed and versioned
# with the app. Users can invoke it in place or symlink it into their PATH.
.PHONY: build-cli
build: build-cli

build-cli:
	@echo "→ build windowpinctl (swift build, universal)"
	swift build -c release --arch arm64 --arch x86_64 \
		--product windowpinctl $(SPM_EMBED_FLAGS)
	mkdir -p "$(BUILT_BUNDLE)/Contents/MacOS"
	if [[ -f ".build/apple/Products/Release/windowpinctl" ]]; then \
		cp ".build/apple/Products/Release/windowpinctl" \
			"$(BUILT_BUNDLE)/Contents/MacOS/windowpinctl"; \
	else \
		cp ".build/release/windowpinctl" \
			"$(BUILT_BUNDLE)/Contents/MacOS/windowpinctl"; \
	fi
