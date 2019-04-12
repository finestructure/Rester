# based on https://github.com/vapor/api-template/blob/b5573ace9632e2d28362cd278cdaac43ff9a00ea/web.Dockerfile

# base image

ARG VERSION=${VERSION}
FROM finestructure/rester:base-${VERSION} as build

# add VERSION to binary
RUN make version

RUN mkdir -p /build/lib && cp -R /usr/lib/swift/linux/*.so* /build/lib
# Can't use -c release for the moment: https://github.com/pointfreeco/swift-gen/issues/8
# RUN swift build -c release && mv `swift build -c release --show-bin-path` /build/bin
RUN swift build && mv `swift build --show-bin-path` /build/bin

# deployment image

ARG VERSION=${VERSION}
FROM ubuntu:18.04

# DEBIAN_FRONTEND=noninteractive for automatic UTC configuration in tzdata
RUN apt-get -qq update && DEBIAN_FRONTEND=noninteractive apt-get install -y \ 
  libatomic1 libicu60 libxml2 libcurl4 libz-dev libbsd0 tzdata \
  && rm -r /var/lib/apt/lists/*

WORKDIR /app

COPY --from=build /build/bin/rester .
COPY --from=build /build/lib/* /usr/lib/


ENTRYPOINT ["/app/rester"]
