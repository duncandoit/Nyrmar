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
            case (PlayerCommandIntent.jump, .isPressed(_)):
                
                var forceComp: PhysicsTermComponent! = thrallComp.sibling(PhysicsTermComponent.self)
                if forceComp == nil
                {
                    forceComp = PhysicsTermComponent()
                    admin.addSibling(forceComp!, to: thrallComp)
                }
                forceComp.impulses.append(CGVector(dx: 0, dy: -20))
                
            case (.moveToLocation, .screenPosition(let screenSpacePoint)):
                
                var physicsComp: PhysicsStateComponent! = thrallComp.sibling(PhysicsStateComponent.self)
                if physicsComp == nil
                {
                    physicsComp = PhysicsStateComponent()
                    admin.addSibling(physicsComp!, to: thrallComp)
                }
                
                let worldSpacePoint = RenderSystem.screenToWorld(screenSpacePoint, admin: admin)

                var exertionComp: MoveExertionComponent! = thrallComp.sibling(MoveExertionComponent.self)
                if exertionComp == nil
                {
                    exertionComp = MoveExertionComponent()
                    admin.addSibling(exertionComp!, to: thrallComp)
                }
                
                // Hysteresis: at least one world pixel
                let ppu = CGFloat(admin.metalSurfaceComponent().pixelsPerUnit)
                exertionComp.intent          = .seekTarget
                exertionComp.target          = worldSpacePoint
                exertionComp.dampening       = 0.0   // No velocity dampening
                exertionComp.acceleration    = 60.0  // Proportional push
                exertionComp.arriveEpsilon   = max(exertionComp.arriveEpsilon, 1.0 / ppu)
                
            case (.cameraMove, .axis2D(let movementVector)):
                
                let cameraComp = admin.metalSurfaceComponent()
                var physicsComp: PhysicsStateComponent! = cameraComp.sibling(PhysicsStateComponent.self)
                if physicsComp == nil
                {
                    physicsComp = PhysicsStateComponent()
                    admin.addSibling(physicsComp, to: cameraComp)
                }
                var exertionComp: MoveExertionComponent! = cameraComp.sibling(MoveExertionComponent.self)
                if exertionComp == nil
                {
                    exertionComp = MoveExertionComponent()
                    admin.addSibling(exertionComp!, to: cameraComp)
                }
                exertionComp.intent = .moveInDirection
                exertionComp.target = movementVector
                exertionComp.desiredSpeed    = 10.0 * CGVector(dx: movementVector.x, dy: movementVector.y).length
                exertionComp.dampening       = 6.0
                exertionComp.acceleration    = 20.0 * CGVector(dx: movementVector.x, dy: movementVector.y).length
                
            case let (intent, value):
                
                print("[" + #fileID + "]: Unexpected combo: \(intent), \(value)")
            }
        }

        // Keep only future-tick commands
        inputComp.commandQueue = deferredCommands
    }
}
