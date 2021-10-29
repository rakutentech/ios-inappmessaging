import Foundation

protocol RandomizerType {
    var dice: UInt { get }
}

struct Randomizer: RandomizerType {
    var dice: UInt {
        UInt.random(in: 1...100)
    }
}
