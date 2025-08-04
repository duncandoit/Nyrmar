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
    
    var isDirty: Bool = true
    var position: CGPoint = .zero
    var zPosition: CGFloat = .zero
}
