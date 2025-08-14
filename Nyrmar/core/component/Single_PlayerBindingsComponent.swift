//
//  Single_PlayerBindingsComponent.swift
//  Nyrmar
//
//  Created by Zachary Duncan on 8/8/25.
//

import Foundation

/// Singleton Component: Should have only one instance per `EntityAdmin`
/// Binds `PlayerIntent` with generic input information
final class Single_PlayerBindingsComponent: Component
{
    static let typeID = componentTypeID(for: Single_PlayerBindingsComponent.self)
    var siblings: SiblingContainer?
    
    var mappings: [ActionMapping]

    init(mappings: [ActionMapping])
    {
        self.mappings = mappings
    }
}
