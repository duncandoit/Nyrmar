//
//  Single_Camera2DComponent.swift
//  Nyrmar
//
//  Created by Zachary Duncan on 8/12/25.
//

import CoreFoundation

/// Singleton Component: Should have only one instance per `EntityAdmin`
/// Camera state.
final class Single_Camera2DComponent: Component
{
    static let typeID = componentTypeID(for: Single_Camera2DComponent.self)
    var siblings: SiblingContainer?
    
    var center: CGPoint = .zero
    var pixelsPerUnit: CGFloat = 100
}
