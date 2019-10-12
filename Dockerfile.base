FROM swift:5.1.1

WORKDIR /package

COPY . ./

RUN swift package resolve
RUN swift package clean
