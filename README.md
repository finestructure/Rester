# Rester

![Swift 5](https://img.shields.io/badge/Swift-5-blue.svg)
[![Build Status](https://travis-ci.org/finestructure/Rester.svg?branch=develop)](https://travis-ci.org/finestructure/Rester)
[![codecov](https://codecov.io/gh/finestructure/Rester/branch/develop/graph/badge.svg)](https://codecov.io/gh/finestructure/Rester)
[![Twitter: @_sa_s](https://img.shields.io/badge/twitter-@_sa_s-blue.svg?style=flat)](https://twitter.com/_sa_s)


Rester is a command line tool to test HTTP APIs. It takes a request description like the following:

```
# basic.yml
requests:
  basic:
    url: https://httpbin.org/anything
    validation:
      status: 200
```

and processes it

[![asciicast](https://asciinema.org/a/237892.svg)](https://asciinema.org/a/237892)

Rester currently supports:

- Request methods: GET, POST, PUT, DELETE
- Variable substitution
- Post data with respective encoding
  - JSON
  - query parameters
  - forms
  - multipart
- Sending headers
- Using response values as substitution variables
- Batch file processing
- Delay between requests

See [Upcoming Features](https://github.com/finestructure/Rester/issues/28) for a list of what is planned for future releases.

## Example request sequence

An example is worth a thousand words - this is how you can use `rester` to instrument API calls:

```
# github.yml
variables:
  BASE_URL: https://api.github.com/repos/finestructure/Rester
requests:
  releases:
    url: ${BASE_URL}/releases
    validation:
      status: 200
      json:
        # validate the first id in the list (latest release)
        # this also captures it as a variable
        0:
          id: .regex(\d+)
    log:
      # log the id to the console
      - json[0].id
  latest_release:
    # use the release id to request release details
    url: ${BASE_URL}/releases/${releases[0].id}
    validation:
      status: 200
    log:
      # log the latest release tag to the console
      - json.tag_name
```

Result:

[![asciicast](https://asciinema.org/a/237894.svg)](https://asciinema.org/a/237894)

The [examples directory](examples) demonstrates further uses of rester. You can also find the output these examples generate in the [test snapshot directory](Tests/ResterTests/__Snapshots__/ExampleTests/).

## Running `rester`

The easiest way to run `rester` is via docker:

```
docker run --rm -t -v $PWD:/host -w /host finestructure/rester examples/github.yml
```

It's probably easiest to define an alias:

```
alias rester="docker run --rm -t -v $PWD:/host -w /host finestructure/rester"
rester examples/basic.yml
```

A word regarding the docker parameters:

- `--rm` cleans up the container after running
- `-t` attaches a tty (this helps with flushing and unicode representation)
- `-v $PWD:/host` maps your current directory onto `/host` inside the container
- `-w /host` sets that `/host` directory as the working directory inside the container. This way you can simply reference files relative to your working directory and they will be found at the same path inside the container.

Note that if you want to test APIs that are running on `localhost`, you will also want to add

- `--network host`

to your `docker run` command. This lets the container run on the host network and allows it to see the host as `localhost`.

## Installing `rester`

`rester` requires Swift 5. You can build and install it from source via the Swift Package Manager:

```
git clone https://github.com/finestructure/rester
cd rester
swift build -c release
```

On macOS, the easiest way to install and update `rester` is probably [Mint](https://github.com/yonaskolb/Mint):

```
brew install mint
mint install finestructure/rester
```
