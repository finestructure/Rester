# Rester

[![Build Status](https://travis-ci.org/finestructure/Rester.svg?branch=develop)](https://travis-ci.org/finestructure/Rester)

Rester is a command line tool to test (REST) APIs. It processes a request description like the following:

```
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
  