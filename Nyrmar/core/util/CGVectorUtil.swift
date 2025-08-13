//
//  CGVectorUtil.swift
//  Nyrmar
//
//  Created by Zachary Duncan on 8/10/25.
//

import CoreFoundation

public extension CGVector
{
    @inlinable var lengthSquared: CGFloat { dx*dx + dy*dy }
    @inlinable var length: CGFloat { sqrt(lengthSquared) }

    func normalized(tolerance: CGFloat = .leastNonzeroMagnitude) -> CGVector
    {
        let L = length
        return L > tolerance ? CGVector(dx: dx / L, dy: dy / L) : .zero
    }

    @inlinable func clampedMagnitude(_ maxMag: CGFloat) -> CGVector
    {
        guard maxMag > 0 else { return self }
        let L = length
        if L == 0 || L <= maxMag { return self }
        let s = maxMag / L
        return CGVector(dx: dx * s, dy: dy * s)
    }

    @inlinable func scaled(by s: CGFloat) -> CGVector
    {
        CGVector(dx: dx * s, dy: dy * s)
    }

    @inlinable func adding(_ other: CGVector) -> CGVector
    {
        CGVector(dx: dx + other.dx, dy: dy + other.dy)
    }

    @inlinable func subtracting(_ other: CGVector) -> CGVector
    {
        CGVector(dx: dx - other.dx, dy: dy - other.dy)
    }
}

// Operators (must be at file scope in Swift)
@inlinable public func * (v: CGVector, s: CGFloat) -> CGVector { v.scaled(by: s) }
@inlinable public func * (s: CGFloat, v: CGVector) -> CGVector { v.scaled(by: s) }
@inlinable public func + (a: CGVector, b: CGVector) -> CGVector { a.adding(b) }
@inlinable public func - (a: CGVector, b: CGVector) -> CGVector { a.subtracting(b) }
