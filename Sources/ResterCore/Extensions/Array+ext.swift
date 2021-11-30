import Gen


extension Array where Element == Request {
    var chooseRandom: Element {
        get throws {
            let rnd = Gen.element(of: self)
            guard let chosen = rnd.run(using: &Current.rng) else {
                throw ResterError.internalError("failed to choose random request")
            }
            return chosen
        }
    }
}
