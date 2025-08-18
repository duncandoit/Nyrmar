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
    
    var zPosition: CGFloat = .zero
    
    var position: CGPoint = .zero
    var rotation: CGFloat = 0 // Radians
    var scale: CGSize = CGSize(width: 1.0, height: 1.0)
    
    var prevPosition: CGPoint = .zero
    var prevRotation: CGFloat = 0 // Radians
    var prevScale: CGSize = .init(width: 1.0, height: 1.0)
}
