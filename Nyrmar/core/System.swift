//
//  System.swift
//  Nyrmar
//
//  Created by Zachary Duncan on 7/31/25.
//

import SpriteKit

protocol System
{
    /// Declares the component type it operates on
    var requiredComponent: ComponentTypeID { get }
    func update(deltaTime: TimeInterval, component: any Component)
}
