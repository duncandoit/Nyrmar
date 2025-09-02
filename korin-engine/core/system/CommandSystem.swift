//
//  CommandSystem.swift
//  Korin
//
//  Created by Zachary Duncan on 8/8/25.
//

import MetalKit

struct CommandSystem: System
{
    func requiredComponent() -> ComponentTypeID
    {
        return ThrallComponent.typeID
    }

    func update(deltaTime: TimeInterval, component: any Component, admin: EntityAdmin)
    {
        let thrallComp = component as! ThrallComponent
        let inputComp = admin.singleton(Single_InputComponent.self)
        
        guard thrallComp.controllerID == inputComp.controllerID else
        {
            return
        }
        
        let clockComp = admin.singleton(Single_ClockComponent.self)
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
            case (.jump, .isPressed(_)):
                
                var forceComp: PhysicsTermComponent! = thrallComp.sibling(PhysicsTermComponent.self)
                if forceComp == nil
                {
                    forceComp = PhysicsTermComponent()
                    admin.addSibling(forceComp!, to: thrallComp)
                }
                
                forceComp.impulses.append(CGVector(dx: 0, dy: 30))
                
            case (.moveToLocation, .screenPosition(let screenSpacePoint)):
                
                var physicsComp: PhysicsStateComponent! = thrallComp.sibling(PhysicsStateComponent.self)
                if physicsComp == nil
                {
                    physicsComp = PhysicsStateComponent()
                    admin.addSibling(physicsComp!, to: thrallComp)
                }

                var exertionComp: MoveExertionComponent! = thrallComp.sibling(MoveExertionComponent.self)
                if exertionComp == nil
                {
                    exertionComp = MoveExertionComponent()
                    admin.addSibling(exertionComp!, to: thrallComp)
                }
                
                // Hysteresis: at least one world pixel
                let ppu = CGFloat(admin.singleton(Single_MetalSurfaceComponent.self).pixelsPerUnit)
                exertionComp.intent          = .seekTarget
                exertionComp.target          = RenderSystem.screenToWorld(screenSpacePoint, admin: admin)
                exertionComp.dampening       = 0.0   // No velocity dampening
                exertionComp.acceleration    = 60.0  // Proportional push
                exertionComp.arriveEpsilon   = max(exertionComp.arriveEpsilon, 1.0 / ppu)
                
            case (.cameraMove, .axis2D(let movementVector)):
                
                let cameraComp = admin.singleton(Single_MetalSurfaceComponent.self)
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
                
                print("[" + #fileID + "]: Unexpected command combo: \(intent), \(value)")
            }
        }

        // Keep only future-tick commands
        inputComp.commandQueue = deferredCommands
    }
}
