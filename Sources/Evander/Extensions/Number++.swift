import Foundation

prefix operator ++ {}
postfix operator ++ {}

prefix operator -- {}
postfix operator -- {}


// Increment
prefix func ++(inout x: Int) -> Int {
    x += 1
    return x
}

postfix func ++(inout x: Int) -> Int {
    x += 1
    return (x - 1)
}

prefix func ++(inout x: UInt) -> UInt {
    x += 1
    return x
}

postfix func ++(inout x: UInt) -> UInt {
    x += 1
    return (x - 1)
}

prefix func ++(inout x: Int8) -> Int8 {
    x += 1
    return x
}

postfix func ++(inout x: Int8) -> Int8 {
    x += 1
    return (x - 1)
}

prefix func ++(inout x: UInt8) -> UInt8 {
    x += 1
    return x
}

postfix func ++(inout x: UInt8) -> UInt8 {
    x += 1
    return (x - 1)
}
prefix func ++(inout x: Int16) -> Int16 {
    x += 1
    return x
}

postfix func ++(inout x: Int16) -> Int16 {
    x += 1
    return (x - 1)
}

prefix func ++(inout x: UInt16) -> UInt16 {
    x += 1
    return x
}

postfix func ++(inout x: UInt16) -> UInt16 {
    x += 1
    return (x - 1)
}

prefix func ++(inout x: Int32) -> Int32 {
    x += 1
    return x
}

postfix func ++(inout x: Int32) -> Int32 {
    x += 1
    return (x - 1)
}

prefix func ++(inout x: UInt32) -> UInt32 {
    x += 1
    return x
}

postfix func ++(inout x: UInt32) -> UInt32 {
    x += 1
    return (x - 1)
}

prefix func ++(inout x: Int64) -> Int64 {
    x += 1
    return x
}

postfix func ++(inout x: Int64) -> Int64 {
    x += 1
    return (x - 1)
}

prefix func ++(inout x: UInt64) -> UInt64 {
    x += 1
    return x
}

postfix func ++(inout x: UInt64) -> UInt64 {
    x += 1
    return (x - 1)
}

prefix func ++(inout x: Double) -> Double {
    x += 1
    return x
}

postfix func ++(inout x: Double) -> Double {
    x += 1
    return (x - 1)
}

prefix func ++(inout x: Float) -> Float {
    x += 1
    return x
}

postfix func ++(inout x: Float) -> Float {
    x += 1
    return (x - 1)
}

prefix func ++(inout x: Float80) -> Float80 {
    x += 1
    return x
}

postfix func ++(inout x: Float80) -> Float80 {
    x += 1
    return (x - 1)
}

prefix func ++<T : _Incrementable>(inout i: T) -> T {
    i = i.successor()
    return i
}

postfix func ++<T : _Incrementable>(inout i: T) -> T {
    let y = i
    i = i.successor()
    return y
}

// Decrement
prefix func --(inout x: Int) -> Int {
    x -= 1
    return x
}

postfix func --(inout x: Int) -> Int {
    x -= 1
    return (x + 1)
}

prefix func --(inout x: UInt) -> UInt {
    x -= 1
    return x
}

postfix func --(inout x: UInt) -> UInt {
    x -= 1
    return (x + 1)
}

prefix func --(inout x: Int8) -> Int8 {
    x -= 1
    return x
}

postfix func --(inout x: Int8) -> Int8 {
    x -= 1
    return (x + 1)
}

prefix func --(inout x: UInt8) -> UInt8 {
    x -= 1
    return x
}

postfix func --(inout x: UInt8) -> UInt8 {
    x -= 1
    return (x + 1)
}
prefix func --(inout x: Int16) -> Int16 {
    x -= 1
    return x
}

postfix func --(inout x: Int16) -> Int16 {
    x -= 1
    return (x + 1)
}

prefix func --(inout x: UInt16) -> UInt16 {
    x -= 1
    return x
}

postfix func --(inout x: UInt16) -> UInt16 {
    x -= 1
    return (x + 1)
}

prefix func --(inout x: Int32) -> Int32 {
    x -= 1
    return x
}

postfix func --(inout x: Int32) -> Int32 {
    x -= 1
    return (x + 1)
}

prefix func --(inout x: UInt32) -> UInt32 {
    x -= 1
    return x
}

postfix func --(inout x: UInt32) -> UInt32 {
    x -= 1
    return (x + 1)
}

prefix func --(inout x: Int64) -> Int64 {
    x -= 1
    return x
}

postfix func --(inout x: Int64) -> Int64 {
    x -= 1
    return (x + 1)
}

prefix func --(inout x: UInt64) -> UInt64 {
    x -= 1
    return x
}

postfix func --(inout x: UInt64) -> UInt64 {
    x -= 1
    return (x + 1)
}

prefix func --(inout x: Double) -> Double {
    x -= 1
    return x
}

postfix func --(inout x: Double) -> Double {
    x -= 1
    return (x + 1)
}

prefix func --(inout x: Float) -> Float {
    x -= 1
    return x
}

postfix func --(inout x: Float) -> Float {
    x -= 1
    return (x + 1)
}

prefix func --(inout x: Float80) -> Float80 {
    x -= 1
    return x
}

postfix func --(inout x: Float80) -> Float80 {
    x -= 1
    return (x + 1)
}

prefix func --<T : BidirectionalIndexType>(inout i: T) -> T {
    i = i.predecessor()
    return i
}

postfix func --<T : BidirectionalIndexType>(inout i: T) -> T {
    let y = i
    i = i.predecessor()
    return y
}
