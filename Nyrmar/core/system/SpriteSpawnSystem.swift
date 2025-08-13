//
//  SpriteSpawnSystem.swift
//  Nyrmar
//
//  Created by Zachary Duncan on 8/12/25.
//

import Foundation
import Metal

final class SpriteSpawnSystem: System
{
    let requiredComponent: ComponentTypeID = SpritePrefabComponent.typeID
    
    func update(deltaTime: TimeInterval, component: any Component)
    {
        let prefabComp = component as! SpritePrefabComponent
        guard let transformComp = prefabComp.sibling(TransformComponent.self) else
        {
            return
        }

        // Surface/device for texture loading
        let surfaceComp = EntityAdmin.shared.getMetalSurfaceComponent()
        guard let device = surfaceComp.device ?? MTLCreateSystemDefaultDevice() else
        {
            return
        }

        let renderComp = SpriteRenderComponent()
        renderComp.tint = prefabComp.tint

        switch prefabComp.source
        {
        case .texture(let name):
            guard let tex = AssetManagerUtil.shared.texture(named: name, device: device) else
            {
                return
            }
            
            renderComp.texture = tex
            renderComp.uv = .init(0,0,1,1)
            renderComp.size = prefabComp.size ?? transformComp.scale   // simple default
            
        case .atlas(let mapName, let frameName):
            
            guard let map = AssetManagerUtil.shared.spriteMap(named: mapName),
                  let tex = AssetManagerUtil.shared.texture(named: map.texture, device: device),
                  let f = map.frames[frameName] else
            {
                return
            }
            
            renderComp.texture = tex
            renderComp.uv = .init(f.u0, f.v0, f.u1, f.v1)
            renderComp.size = prefabComp.size ?? transformComp.scale
        }

        EntityAdmin.shared.addSibling(renderComp, to: prefabComp)
        EntityAdmin.shared.removeComponent(prefabComp)
    }
}
