//
//  TilemapSpawnSystem.swift
//  Nyrmar
//
//  Created by Zachary Duncan on 8/12/25.
//

import Foundation
import Metal

final class TilemapSpawnSystem: System
{
    let requiredComponent: ComponentTypeID = TilemapPrefabComponent.typeID
    
    func update(deltaTime: TimeInterval, component: any Component)
    {
        let prefabComp = component as! TilemapPrefabComponent
        let surfaceComp = EntityAdmin.shared.getMetalSurfaceComponent()
        guard let device = surfaceComp.device ?? MTLCreateSystemDefaultDevice() else
        {
            return
        }

        guard let texture = AssetManagerUtil.shared.texture(named: prefabComp.tilesetTexture, device: device) else
        {
            return
        }
        
        let renderComp = TilemapRenderComponent()
        renderComp.texture = texture
        renderComp.tileSize = prefabComp.tileSize
        renderComp.gridSize = prefabComp.gridSize
        
        // UV LUT left to tileset format (stub)
        renderComp.uvLUT = []
        EntityAdmin.shared.addSibling(renderComp, to: prefabComp)
        EntityAdmin.shared.removeComponent(prefabComp)
    }
}
