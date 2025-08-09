//
//  Single_SimClockComponent.swift
//  Nyrmar
//
//  Created by Zachary Duncan on 8/8/25.
//

import Foundation

final class Single_SimClockComponent: Component
{
    static let typeID = componentTypeID(for: Single_SimClockComponent.self)
    var siblings: SiblingContainer?
    
    let frameCap: UInt64 = 5
    var tickDuration: TimeInterval = 1.0 / 60.0
    var accumulator: TimeInterval = 0
    var tickIndex: UInt64 = 0
    var quantizedNow: TimeInterval = 0
}
