//
//  PlayerCommandSystem.swift
//  Nyrmar
//
//  Created by Zachary Duncan on 8/8/25.
//

import Foundation

final class PlayerCommandSystem: System
{
    let requiredComponent: ComponentTypeID = ThrallComponent.typeID

    func update(deltaTime: TimeInterval, component: any Component)
    {
        let thrallComp = component as! ThrallComponent
        let inputComp = EntityAdmin.shared.getInputComponent()
        
        guard thrallComp.controllerID == inputComp.controllerID else
        {
            return
        }
        
        let clockComp = EntityAdmin.shared.getSimClock()
        var deferredCommands: [PlayerCommand] = []

        for command in inputComp.commandQueue
        {
            guard command.timestamp < clockComp.quantizedNow else
            {
                // Process only commands at-or-before this tick; defer future ones
                deferredCommands.append(command)
                continue
            }
            
            switch (command.intent, command.value)
            {
            
            case (.moveToLocation, .axis2D(let worldSpacePoint)):
                
                var mover: MoveExertionComponent! = thrallComp.sibling(MoveExertionComponent.self)
                if mover == nil
                {
                    mover = MoveExertionComponent()
                    EntityAdmin.shared.addSibling(mover!, to: thrallComp)
                }
                mover.teleportTo      = nil             // cancel any pending snap
                mover.deltaWorld      = nil             // cancel one-shot delta
                mover.velocityDesired = nil             // avoid fighting the seek
                mover.seekTarget      = worldSpacePoint // primary instruction
                mover.seekSpeed       = nil             // use mover.moveSpeed; set if you want an override
                //mover.faceTarget      = viewPt

//            case (.move, .axis2D(let vector)):
//                
//                let dir = CGVector(dx: vector.x, dy: vector.y)
//                let steer: SteeringComponent = EntityAdmin.shared.getComponent(for: thrall) ?? { let s = SteeringComponent(); EntityAdmin.shared.addComponent(s, to: thrall); return s }()
//                steer.direction = dir   // data only; MovementSystem will use it
//
//            case (.primaryFire, .isPressed(let down)):
//                
//                let fire: FireIntentComponent = EntityAdmin.shared.getComponent(for: thrall) ?? { let f = FireIntentComponent(); EntityAdmin.shared.addComponent(f, to: thrall); return f }()
//                fire.isPressed = down

            default:
                break // ignore irrelevant value shapes
            }
        }

        // Keep only future-tick commands; current tick consumed deterministically
        inputComp.commandQueue = deferredCommands
    }
}
