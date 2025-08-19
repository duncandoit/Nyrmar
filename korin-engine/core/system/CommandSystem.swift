//
//  CommandSystem.swift
//  Korin
//
//  Created by Zachary Duncan on 8/8/25.
//

import MetalKit

final class CommandSystem: System
{
    let requiredComponent: ComponentTypeID = ThrallComponent.typeID

    func update(deltaTime: TimeInterval, component: any Component, admin: EntityAdmin)
    {
        let thrallComp = component as! ThrallComponent
        let inputComp = admin.inputComponent()
        
        guard thrallComp.controllerID == inputComp.controllerID else
        {
            return
        }
        
        let clockComp = admin.clockComponent()
        var deferredCommands: [PlayerCommand] = []

        for command in inputComp.commandQueue
        {
            guard isLater(clockComp.tickIndex, than: command.tickIndex) else
            {
                // Process only commands at-or-before this tick and defer future ones
                deferredCommands.append(command)
                continue
            }
            
            switch (command.intent, command.value)
            {
                
            case (.jump, .screenPosition(_)):
                
                let physicsComp = thrallComp.sibling(PhysicsStateComponent.self)!
                physicsComp.ignorePhysics = false
                
                //var forceComp: PhysicsTermComponent! = thrallComp.sibling(PhysicsTermComponent.self)
                //if forceComp == nil
                //{
                //    forceComp = PhysicsTermComponent()
                //    admin.addSibling(forceComp!, to: thrallComp)
                //}
                //forceComp.impulses.append(CGVector(dx: 0, dy: -200))
                
            case (.moveToLocation, .screenPosition(let screenSpacePoint)):
                
                let physicsComp = thrallComp.sibling(PhysicsStateComponent.self)!
                physicsComp.ignorePhysics = true
                
                // No viewport yet. Ignore this tick.
                guard let layer = admin.metalSurfaceComponent().layer else
                {
                    break
                }
                let cameraComp = admin.camera2DComponent()

                // Normalized device coords from View points
                let viewportSize = layer.bounds.size
                guard viewportSize.width > 0, viewportSize.height > 0 else
                {
                    break
                }

                let ndcX = (screenSpacePoint.x / viewportSize.width)  * 2.0 - 1.0
                let ndcY = 1.0 - (screenSpacePoint.y / viewportSize.height) * 2.0   // flip Y once

                // Normalized device coordinates -> world coordinates
                // using half-extents derived from PPU and pixel viewport
                let contentScale  = layer.contentsScale
                let pixelWidth = layer.bounds.width  * contentScale
                let pixelHeight = layer.bounds.height * contentScale
                let pixelsPerUnit = CGFloat(cameraComp.pixelsPerUnit)
                let halfWorldX = pixelWidth / (2.0 * pixelsPerUnit)
                let halfWorldY = pixelHeight / (2.0 * pixelsPerUnit)

                let worldX = cameraComp.center.x + ndcX * halfWorldX
                let worldY = cameraComp.center.y + ndcY * halfWorldY
                let worldSpacePoint = CGPoint(x: worldX, y: worldY)

                var exertionComp: MoveExertionComponent! = thrallComp.sibling(MoveExertionComponent.self)
                if exertionComp == nil
                {
                    exertionComp = MoveExertionComponent()
                    admin.addSibling(exertionComp!, to: thrallComp)
                }
                
                // Hysteresis: at least one world pixel
                let ppu = CGFloat(cameraComp.pixelsPerUnit)
                exertionComp.seekKd          = 0.0   // No velocity dampening
                exertionComp.seekKp          = 60.0  // Proportional push
                exertionComp.arriveEpsilon   = max(exertionComp.arriveEpsilon, 1.0 / ppu)
                exertionComp.teleportTo      = nil
                exertionComp.deltaWorld      = nil
                exertionComp.seekTarget      = worldSpacePoint
                exertionComp.killVelocity    = true
                
            case (.cameraMove, .isPressed(let pressed)):
                
                if pressed
                {
                    print("Camera Move Command Triggered.")
                }

            //case (.move, .axis2D(let vector)):
            //
            //    let dir = CGVector(dx: vector.x, dy: vector.y)
            //    let steer: SteeringComponent = admin.getComponent(for: thrall) ?? { let s = SteeringComponent(); admin.addComponent(s, to: thrall); return s }()
            //    steer.direction = dir   // data only; MovementSystem will use it
            //
            //case (.primaryFire, .isPressed(let down)):
            //
            //    let fire: FireIntentComponent = admin.getComponent(for: thrall) ?? { let f = FireIntentComponent(); admin.addComponent(f, to: thrall); return f }()
            //    fire.isPressed = down

            default:
                break
            }
        }

        // Keep only future-tick commands
        inputComp.commandQueue = deferredCommands
    }
}
