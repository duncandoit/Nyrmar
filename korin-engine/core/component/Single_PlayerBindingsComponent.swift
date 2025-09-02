//
//  Single_PlayerBindingsComponent.swift
//  Korin
//
//  Created by Zachary Duncan on 8/8/25.
//

import Foundation

/// Singleton Component: Should have only one instance per `EntityAdmin`
/// Binds `PlayerIntent` with generic input information
final class Single_PlayerBindingsComponent: SingletonComponent
{
    static let typeID = componentTypeID(for: Single_PlayerBindingsComponent.self)
    var siblings: SiblingContainer?
    
    var digital: [DigitalMapping] = []
    var axis1D:  [Axis1DMapping]  = []
    var axis2D:  [Axis2DMapping]  = []
    var pointer: [PointerMapping] = []
    var digitalAxis2D: [DigitalAxis2DMapping] = []
}
