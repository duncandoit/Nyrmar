//
//  TransformComponent.swift
//  Nyrmar
//
//  Created by Zachary Duncan on 7/31/25.
//

import CoreFoundation

class TransformComponent: Component
{
    static let typeID: ComponentTypeID = componentTypeID(for: TransformComponent.self)
    var siblings: SiblingContainer?
    
    var position: CGPoint = .zero
    var zPosition: CGFloat = .zero
    
    /// Rotation in radians
    var zRotation: CGFloat = 0
    var scale: CGSize = CGSize(width: 1.0, height: 1.0)
}
