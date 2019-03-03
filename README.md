# Rester

[![Build Status](https://travis-ci.org/finestructure/Rester.svg?branch=develop)](https://travis-ci.org/finestructure/Rester)

Rester is a command line tool to test (REST) APIs. It processes a request description like the following:

```
# basic.yml
requests:
  basic:
    url: https://httpbin.org/anything
    validation:
      status: 200
```

into

```
$ rester examples/basic.yml 
🚀  Resting examples/basic.yml ...

🎬  basic started ...

✅  basic PASSED (0.013s)

Executed 1 tests, with 0 failures
```

Features:

- Request methods: GET, POST, PUT, DELETE
- Variable substitution
- Post data with respective encoding
  - JSON
  - query parameters
  - forms
- Send headers
- Use response values as substitution variables
- Batch file processing
- Delay between requests
  

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
      - json.0.id
  latest_release:
    # use the release id to request release details
    url: ${BASE_URL}/releases/${releases.0.id}
    validation:
      status: 200
    log:
      # log the latest release tag to the console
      - json.tag_name
```

Result:

```
$ rester examples/github.yml
🚀  Resting examples/github.yml ...

🎬  releases started ...

0.id: 15863504

✅  releases PASSED (0.012s)

🎬  latest_release started ...

tag_name: "0.0.6"

✅  latest_release PASSED (0.011s)

Executed 2 tests, with 0 failures
```

## Running `rester`

The easiest way to run `rester` is via docker:

```
docker run --rm -it -v $PWD:/host -w /host finestructure/rester:0.0.6 examples/github.yml
```

## Installing `rester`

- Using [Mint](https://github.com/yonaskolb/Mint)

```
mint install finestructure/rester
```
