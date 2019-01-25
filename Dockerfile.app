# base image

ARG VERSION=${VERSION}
FROM rester:base-${VERSION} as build
# FROM finestructure/rester/base:${VERSION} as build

RUN mkdir -p /build/lib && cp -R /usr/lib/swift/linux/*.so /build/lib
RUN swift build -c release && mv `swift build -c release --show-bin-path` /build/bin


# deployment image

ARG VERSION=${VERSION}
FROM ubuntu:16.04

RUN apt-get -qq update && apt-get install -y \
  libicu55 libxml2 libbsd0 libcurl3 libatomic1 \
  tzdata \
  && rm -r /var/lib/apt/lists/*

WORKDIR /app

COPY --from=build /build/bin/rester .
COPY --from=build /build/lib/* /usr/lib/


ENTRYPOINT ["/app/rester"]
