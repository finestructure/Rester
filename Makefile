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

test-linux: docker-build-base
	docker run --rm rester-base swift test

test-macos: xcodeproj
	set -o pipefail && \
	xcodebuild test \
		-scheme Rester \
		-destination platform="macOS" \

test-swift:
	swift test

test-all: test-linux test-macos

magic:
	sourcery   --templates ./.sourcery   --sources Tests   --args testimports='@testable import '"ResterTests"   --output Tests/LinuxMain.swift

release-macos:
	swift build --static-swift-stdlib -c release

release-linux: docker-build-base
	docker run --rm -v $(PWD):/host -w /host rester-base swift build --static-swift-stdlib -c release

version:
	echo "public let ResterVersion = \"$(VERSION)\"" > Sources/ResterCore/Version.swift
