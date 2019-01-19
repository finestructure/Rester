import Foundation
import Yams
import Regex
import ResterCore


let decoder = YAMLDecoder()



let env = try decoder.decode(Rester.self, from: """
    variables:
        INT_VALUE: 42
        STRING_VALUE: some string value
""")

dump(env)

let req = try decoder.decode(Rester.self, from: """
    variables:
        API_URL: "https://dev.vbox.space"
    requests:
        version:
            url: ${API_URL}/metrics/build
            method: GET
            validation:
                status: 200
                content:
                    version: .regex('\\d+\\.\\d+\\.\\d+|\\S{40}')
""")

dump(req)

let variables = req.variables!
let requests = req.requests!
let versionReq = try requests["version"]!.substitute(variables: variables)

assert(variables["API_URL"]! == .string("https://dev.vbox.space"))
assert(versionReq.url == "https://dev.vbox.space/metrics/build", "was: \(versionReq.url)")

// TODO: parse validation.content


// let vars: Variables = ["API_URL": .string("https://foo.bar"), "foo": .int(5)]
// let n = try _substitute(string: "${API_URL}/metrics/build/${foo}/${foo}", with: vars)
// print("result: \(n)")
