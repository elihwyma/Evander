import Foundation

prefix operator ++
postfix operator ++

prefix operator --
postfix operator --


// Increment
@discardableResult public prefix func ++( x: inout Int) -> Int {
    x += 1
    return x
}

@discardableResult public postfix func ++( x: inout Int) -> Int {
    x += 1
    return (x - 1)
}

@discardableResult public prefix func ++( x: inout UInt) -> UInt {
    x += 1
    return x
}

@discardableResult public postfix func ++( x: inout UInt) -> UInt {
    x += 1
    return (x - 1)
}

@discardableResult public prefix func ++( x: inout Int8) -> Int8 {
    x += 1
    return x
}

@discardableResult public postfix func ++( x: inout Int8) -> Int8 {
    x += 1
    return (x - 1)
}

@discardableResult public prefix func ++( x: inout UInt8) -> UInt8 {
    x += 1
    return x
}

@discardableResult public postfix func ++( x: inout UInt8) -> UInt8 {
    x += 1
    return (x - 1)
}
@discardableResult public prefix func ++( x: inout Int16) -> Int16 {
    x += 1
    return x
}

@discardableResult public postfix func ++( x: inout Int16) -> Int16 {
    x += 1
    return (x - 1)
}

@discardableResult public prefix func ++( x: inout UInt16) -> UInt16 {
    x += 1
    return x
}

@discardableResult public postfix func ++( x: inout UInt16) -> UInt16 {
    x += 1
    return (x - 1)
}

@discardableResult public prefix func ++( x: inout Int32) -> Int32 {
    x += 1
    return x
}

@discardableResult public postfix func ++( x: inout Int32) -> Int32 {
    x += 1
    return (x - 1)
}

@discardableResult public prefix func ++( x: inout UInt32) -> UInt32 {
    x += 1
    return x
}

@discardableResult public postfix func ++( x: inout UInt32) -> UInt32 {
    x += 1
    return (x - 1)
}

@discardableResult public prefix func ++( x: inout Int64) -> Int64 {
    x += 1
    return x
}

@discardableResult public postfix func ++( x: inout Int64) -> Int64 {
    x += 1
    return (x - 1)
}

@discardableResult public prefix func ++( x: inout UInt64) -> UInt64 {
    x += 1
    return x
}

@discardableResult public postfix func ++( x: inout UInt64) -> UInt64 {
    x += 1
    return (x - 1)
}

@discardableResult public prefix func ++( x: inout Double) -> Double {
    x += 1
    return x
}

@discardableResult public postfix func ++( x: inout Double) -> Double {
    x += 1
    return (x - 1)
}

@discardableResult public prefix func ++( x: inout Float) -> Float {
    x += 1
    return x
}

@discardableResult public postfix func ++( x: inout Float) -> Float {
    x += 1
    return (x - 1)
}

// Decrement
@discardableResult public prefix func --( x: inout Int) -> Int {
    x -= 1
    return x
}

@discardableResult public postfix func --( x: inout Int) -> Int {
    x -= 1
    return (x + 1)
}

@discardableResult public prefix func --( x: inout UInt) -> UInt {
    x -= 1
    return x
}

@discardableResult public postfix func --( x: inout UInt) -> UInt {
    x -= 1
    return (x + 1)
}

@discardableResult public prefix func --( x: inout Int8) -> Int8 {
    x -= 1
    return x
}

@discardableResult public postfix func --( x: inout Int8) -> Int8 {
    x -= 1
    return (x + 1)
}

@discardableResult public prefix func --( x: inout UInt8) -> UInt8 {
    x -= 1
    return x
}

@discardableResult public postfix func --( x: inout UInt8) -> UInt8 {
    x -= 1
    return (x + 1)
}
@discardableResult public prefix func --( x: inout Int16) -> Int16 {
    x -= 1
    return x
}

@discardableResult public postfix func --( x: inout Int16) -> Int16 {
    x -= 1
    return (x + 1)
}

@discardableResult public prefix func --( x: inout UInt16) -> UInt16 {
    x -= 1
    return x
}

@discardableResult public postfix func --( x: inout UInt16) -> UInt16 {
    x -= 1
    return (x + 1)
}

@discardableResult public prefix func --( x: inout Int32) -> Int32 {
    x -= 1
    return x
}

@discardableResult public postfix func --( x: inout Int32) -> Int32 {
    x -= 1
    return (x + 1)
}

@discardableResult public prefix func --( x: inout UInt32) -> UInt32 {
    x -= 1
    return x
}

@discardableResult public postfix func --( x: inout UInt32) -> UInt32 {
    x -= 1
    return (x + 1)
}

@discardableResult public prefix func --( x: inout Int64) -> Int64 {
    x -= 1
    return x
}

@discardableResult public postfix func --( x: inout Int64) -> Int64 {
    x -= 1
    return (x + 1)
}

@discardableResult public prefix func --( x: inout UInt64) -> UInt64 {
    x -= 1
    return x
}

@discardableResult public postfix func --( x: inout UInt64) -> UInt64 {
    x -= 1
    return (x + 1)
}

@discardableResult public prefix func --( x: inout Double) -> Double {
    x -= 1
    return x
}

@discardableResult public postfix func --( x: inout Double) -> Double {
    x -= 1
    return (x + 1)
}

@discardableResult public prefix func --( x: inout Float) -> Float {
    x -= 1
    return x
}

@discardableResult public postfix func --( x: inout Float) -> Float {
    x -= 1
    return (x + 1)
}

infix operator &=
public func &=<T: Equatable>(lhs: T, rhs: [T]) -> Bool {
    rhs.contains(lhs)
}
