//
//  ParametricMovementComponent.swift
//  Nyrmar
//
//  Created by Zachary Duncan on 8/1/25.
//

import Foundation
import CoreFoundation

/// Component describing parametric movement attributes
class ParametricMovementComponent: Component
{
    static let typeID: ComponentTypeID = componentTypeID(for: ParametricMovementComponent.self)
    var siblings: SiblingContainer?

    var amplitude: CGVector
    var frequency: CGFloat
    var phase: CGFloat
    var elapsedTime: TimeInterval = 0.0

    init(amplitude: CGVector, frequency: CGFloat, phase: CGFloat = 0.0)
    {
        self.amplitude = amplitude
        self.frequency = frequency
        self.phase = phase
    }
}
