FROM swift:4.2.1

WORKDIR /package

COPY . ./

RUN swift package resolve
RUN swift package clean
