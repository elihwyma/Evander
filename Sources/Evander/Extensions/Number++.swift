import Foundation

prefix operator ++
postfix operator ++

prefix operator --
postfix operator --

infix operator &=

// Increment
@discardableResult public prefix func ++<T: Numeric>(_ x: inout T) -> T {
    x += 1
    return x
}

@discardableResult public postfix func ++<T: Numeric>(_ x: inout T) -> T {
    x += 1
    return x
}

// Decrement
@discardableResult public prefix func --<T: Numeric>(_ x: inout T) -> T {
    x -= 1
    return x
}

@discardableResult public postfix func --<T: Numeric>(_ x: inout T) -> T {
    x -= 1
    return x
}

public func &=<T: Equatable>(lhs: T, rhs: [T]) -> Bool {
    rhs.contains(lhs)
}
