//
//  Single_PlayerBindingsComponent.swift
//  Nyrmar
//
//  Created by Zachary Duncan on 8/8/25.
//

import Foundation

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
