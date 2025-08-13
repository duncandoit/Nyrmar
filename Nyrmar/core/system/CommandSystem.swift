//
//  CommandSystem.swift
//  Nyrmar
//
//  Created by Zachary Duncan on 8/8/25.
//

import MetalKit

final class CommandSystem: System
{
    let requiredComponent: ComponentTypeID = ThrallComponent.typeID

    func update(deltaTime: TimeInterval, component: any Component)
    {
        let thrallComp = component as! ThrallComponent
        let inputComp = EntityAdmin.shared.inputComponent()
        
        guard thrallComp.controllerID == inputComp.controllerID else
        {
            return
        }
        
        let clockComp = EntityAdmin.shared.simClockComponent()
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
                
            case (.moveToLocation, .screenPosition(let screenSpacePoint)):
                
                // No viewport yet. Ignore this tick.
                guard let layer = EntityAdmin.shared.metalSurfaceComponent().layer else
                {
                    break
                }
                let camComp = EntityAdmin.shared.camera2DComponent()

                // Normalized device coords from View points
                let vpPt = layer.bounds.size
                guard vpPt.width > 0, vpPt.height > 0 else { break }

                let ndcX = (screenSpacePoint.x / vpPt.width)  * 2.0 - 1.0
                let ndcY = 1.0 - (screenSpacePoint.y / vpPt.height) * 2.0   // flip Y once

                // NDC -> world using half-extents derived from PPU and*pixel viewport
                let scale  = layer.contentsScale
                let Wpx = layer.bounds.width  * scale
                let Hpx = layer.bounds.height * scale
                let ppu = CGFloat(camComp.pixelsPerUnit)
                let halfWorldX = Wpx / (2.0 * ppu)
                let halfWorldY = Hpx / (2.0 * ppu)

                let worldX = camComp.center.x + ndcX * halfWorldX
                let worldY = camComp.center.y + ndcY * halfWorldY
                let worldSpacePoint = CGPoint(x: worldX, y: worldY)

                var moverComp: MoveExertionComponent! = thrallComp.sibling(MoveExertionComponent.self)
                if moverComp == nil { moverComp = MoveExertionComponent(); EntityAdmin.shared.addSibling(moverComp!, to: thrallComp) }
                moverComp.teleportTo      = nil
                moverComp.deltaWorld      = nil
                moverComp.velocityDesired = nil
                moverComp.seekTarget      = worldSpacePoint
                moverComp.seekSpeed       = nil
            
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
                mover.seekSpeed       = nil             // use mover.moveSpeed
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
