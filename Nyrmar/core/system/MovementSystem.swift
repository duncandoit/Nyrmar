//
//  MovementSystem.swift
//  Nyrmar
//
//  Created by Zachary Duncan on 8/4/25.
//

import Foundation

/// System for target-based movement
class MovementSystem: System
{
    let requiredComponent: ComponentTypeID = MovementComponent.typeID
    
    func update(deltaTime: TimeInterval, component: any Component, world: GameWorld)
    {
        let movementComp = component as! MovementComponent
        guard let transformComp = movementComp.sibling(TransformComponent.self) else
        {
            print("[" + #fileID + "]: " + #function + " -> Missing TransformComponent for \(String(describing: movementComp))")
            return
        }
        
        guard let destination = movementComp.destination else
        {
            //print("[" + #fileID + "]: " + #function + " -> MovementComponent has no destination.")
            return
        }
        
        let dx = destination.x - transformComp.position.x
        let dy = destination.y - transformComp.position.y
        let dist = hypot(dx, dy)
        
        guard dist > 0.1 else
        {
            movementComp.destination = nil
            return
        }
        
        let step = movementComp.moveSpeed * CGFloat(deltaTime)
        transformComp.position.x += dx / dist * step
        transformComp.position.y += dy / dist * step
    }
}
