import Foundation

prefix operator ++
postfix operator ++

prefix operator --
postfix operator --

infix operator &=

// Increment
prefix func ++<T: Numeric>(_ x: inout T) {
    x += 1
}

postfix func ++<T: Numeric>(_ x: inout T) {
    x += 1
}

// Decrement
prefix func --<T: Numeric>(_ x: inout T) {
    x -= 1
}

postfix func --<T: Numeric>(_ x: inout T) {
    x -= 1
}

public func &=<T: Equatable>(lhs: T, rhs: [T]) -> Bool {
    rhs.contains(lhs)
}
