//
//  CameraSystem.swift
//  Nyrmar
//
//  Created by Zachary Duncan on 8/5/25.
//


import SpriteKit

class CameraSystem: System
{
    let requiredComponent: ComponentTypeID = InputComponent.typeID

    func update(deltaTime: TimeInterval, component: any Component, world: GameWorld)
    {
        let inputComp = component as! InputComponent
        guard let location = inputComp.touchLocation else
        {
            return
        }

        guard EntityAdmin.shared.getEntities(withComponentType: ThrallComponent.typeID)?.first != nil else
        {
            return
        }
        
        // TODO: Currently there's no camera so this will always fail
        guard let camera = world.camera else
        {
            return
        }
        
        camera.position = location
    }
}
