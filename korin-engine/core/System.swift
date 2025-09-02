//
//  System.swift
//  Korin
//
//  Created by Zachary Duncan on 7/31/25.
//

import SpriteKit

/// Systems are pure behavior and should contain zero member state.
protocol System
{
    /// Declares the component type it operates on
    func requiredComponent() -> ComponentTypeID
    func update(deltaTime: TimeInterval, component: any Component, admin: EntityAdmin)
}
