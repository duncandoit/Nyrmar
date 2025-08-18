//
//  UInt64Util.swift
//  Nyrmar
//
//  Created by Zachary Duncan on 8/18/25.
//

import Foundation

@inline(__always)
func ticksSince(_ past: UInt64, now: UInt64) -> UInt64
{
    now &- past
}

/// True if a is within the forward half-range of b
@inline(__always)
func isLater(_ a: UInt64, than b: UInt64) -> Bool
{
    (a &- b) < (1 << 63)
}
