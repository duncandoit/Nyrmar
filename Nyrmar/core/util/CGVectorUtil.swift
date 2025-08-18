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
    
    // Project v onto n (unit not required)
    @inline(__always)
    private func project(_ v: CGVector, onto n: CGVector) -> CGVector
    {
        let nn = n.dx*n.dx + n.dy*n.dy
        guard nn > 0 else { return .zero }
        let scale = (v.dx*n.dx + v.dy*n.dy) / nn
        return CGVector(dx: n.dx*scale, dy: n.dy*scale)
    }
}

@inlinable public func * (v: CGVector, s: CGFloat) -> CGVector { v.scaled(by: s) }
@inlinable public func * (v: CGVector, s: Double) -> CGVector { v.scaled(by: s) }
@inlinable public func * (s: CGFloat, v: CGVector) -> CGVector { v.scaled(by: s) }
@inlinable public func + (a: CGVector, b: CGVector) -> CGVector { a.adding(b) }
@inlinable public func - (a: CGVector, b: CGVector) -> CGVector { a.subtracting(b) }
@inlinable public func +=(lhs: inout CGVector, rhs: CGVector) { lhs = lhs + rhs }
@inlinable public func -=(lhs: inout CGVector, rhs: CGVector) { lhs = lhs - rhs }

@inlinable public func *=(lhs: inout CGVector, rhs: Double)
{
    let g = CGFloat(rhs)
    lhs.dx *= g
    lhs.dy *= g
}
