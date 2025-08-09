//
//  MovementSystem.swift
//  Nyrmar
//
//  Created by Zachary Duncan on 8/4/25.
//

import Foundation

/// System for target-based movement
class MovementExertionSystem: System
{
    let requiredComponent: ComponentTypeID = MovementComponent.typeID
    
    func update(deltaTime: TimeInterval, component: any Component, world: GameWorld)
    {
        let movementComp = component as! MovementComponent
        guard let thrallComp = movementComp.sibling(ThrallComponent.self) else
        {
            return
        }
        guard thrallComp.controllerID == EntityAdmin.shared.getInputComponent().controllerID else
        {
            return
        }
        guard let transformComp = movementComp.sibling(TransformComponent.self) else
        {
            print("[" + #fileID + "]: " + #function + " -> Missing TransformComponent for \(String(describing: movementComp))")
            return
        }
        guard let baseStatsComp = movementComp.sibling(BaseStatsComponent.self) else
        {
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
        
        guard dist > movementComp.destinationThreshold else
        {
            movementComp.destination = nil
            return
        }
        
        let step = baseStatsComp.moveSpeed * CGFloat(deltaTime)
        transformComp.position.x += dx / dist * step
        transformComp.position.y += dy / dist * step
    }
}
