.PHONY: magic version

export VERSION=$(shell git rev-parse HEAD)

clean:
	rm -rf .build

xcodeproj:
	swift package generate-xcodeproj

build-docker-base:
	docker build --tag rester-base -f Dockerfile.base .

build-docker-app: build-docker-base
	@echo VERSION: $(VERSION)
	docker tag rester-base finestructure/rester:base-$(VERSION)
	docker build --tag rester:$(VERSION) -f Dockerfile.app --build-arg VERSION=$(VERSION) .

test-linux-spm: build-docker-base
	docker run --rm rester-base swift test --parallel

test-macos-xcode: xcodeproj
	set -o pipefail && \
	xcodebuild test \
		-scheme Rester \
		-destination platform="macOS" \
		-parallel-testing-enabled YES \
		-enableCodeCoverage YES \
		-derivedDataPath .build/derivedData

test-macos-spm: BUILD_DIR=$(shell swift build --show-bin-path)
test-macos-spm:
	swift test --parallel --enable-code-coverage
	xcrun llvm-cov report -ignore-filename-regex=".build/*" -instr-profile $(BUILD_DIR)/codecov/default.profdata $(BUILD_DIR)/rester

test-all: test-linux-spm test-macos-spm test-macos-xcode

magic:
	sourcery --templates ./.sourcery --sources Tests --args testimports='@testable import '"ResterTests" --output Tests/LinuxMain.swift

release-macos:
	swift build --static-swift-stdlib -c release

release-linux: docker-build-base
	docker run --rm -v $(PWD):/host -w /host rester-base swift build --static-swift-stdlib -c release

version:
	echo "public let ResterVersion = \"$(VERSION)\"" > Sources/ResterCore/Version.swift
