//
//  EntityManager.swift
//  Nyrmar
//
//  Created by Zachary Duncan on 7/31/25.
//

import SpriteKit
import GameplayKit

class EntityManager
{
    private var m_EntityComponentsByType: [Entity: [ComponentTypeID: Component]] = [:]
    private var m_ComponentsByType: [ComponentTypeID: [Component]] = [:]
    private var m_Systems: [System]
//    private var m_Avatars: [Entity: Avatar] = [:]
    private var m_World: GameWorld!
    
    static var shared: EntityManager { EntityManager() }
    
    private init()
    {
        m_Systems = [
            // TargetName
            // LifetimeEntity
        //    PlayerSpawnSystem(),
            GameInputSystem(),
            // Behavior
            // AimAtTarget
            // MouseCursorFollow
            ParametricMovementSystem(),
            // PlatformerPlayerController
            // WallCrawler
            // RaycastMovement
            // Physics
            // Grounded
            // Health
            // Socket
            // Attach
            // Camera
            // DebugEntity
            // ImageAnimation
            RenderSyncSystem(),
            // EntitySpawner
        //    LifeSpanSystem(),
            // SpawnOnDestroy
        ]
    }
    
    func initializeScene(_ world: GameWorld)
    {
        clearScene()
        self.m_World = world
    }
    
    func clearScene()
    {
//        m_Avatars.removeAll()
        // Mark AvatarComponents as wantToSpawn
    }
     
    func addEntity(_ entity: Entity = Entity()) -> Entity
    {
        m_EntityComponentsByType[entity] = [:]
        return entity
    }
    
    func removeEntity(_ entity: Entity)
    {
        m_EntityComponentsByType.removeValue(forKey: entity)
        // TODO: when removing an Entity we must also remove its owned components from m_ComponentsByType
    }
    
    func removeAllEntities()
    {
//        m_Avatars.removeAll()
        m_EntityComponentsByType.removeAll()
        m_ComponentsByType.removeAll()
    }
    
    func allEntities() -> [Entity: [ComponentTypeID: Component]]
    {
        return m_EntityComponentsByType
    }
    
    func addComponent(_ component: Component, to entity: Entity)
    {
        m_EntityComponentsByType[entity]?[component.typeID()] = component
        m_ComponentsByType[component.typeID(), default: []].append(component)
        updateSiblingReferences(for: entity)
    }
    
    func addComponents(_ components: [Component], to entity: Entity)
    {
        for component in components
        {
            addComponent(component, to: entity)
        }
    }
    
    private func updateSiblingReferences(for entity: Entity)
    {
        guard let components = m_EntityComponentsByType[entity] else
        {
            print(#function + ":  Entity not found: \(entity).")
            return
        }
        
        let weakRefs = components.mapValues { WeakComponentRef($0) }
        for component in components.values
        {
            component.siblings = weakRefs
        }
    }
    
    func getComponent<T: Component>(for entity: Entity) -> T?
    {
        return m_EntityComponentsByType[entity]?[T.typeID] as? T
    }
    
//    func addAvatar(_ avatar: AvatarComponent, atTransform transformComp: TransformComponent, with owningEntity: Entity)
//    {
//        guard m_Avatars[owningEntity] == nil else
//        {
//            print(#function + ": Avatar already exists for Entity: \(owningEntity).")
//            return
//        }
//        let avatar = Avatar(
//            textureName: "Avatar",
//            owningEntity: owningEntity,
//            size: CGSize(width: 10, height: 10),
//            position: transformComp.position,
//            zPosition: transformComp.zPosition
//        )
//        
//        m_Avatars[owningEntity] = avatar
//        m_World.addChild(avatar)
//        print(#function + ": Spawned Avatar for Entity: \(owningEntity).")
//    }
    
    func removeAvatar(with owningEntity: Entity)
    {
        guard let avatar = m_Avatars[owningEntity] else
        {
            print(#function + ": Avatar with owningEntity: \(owningEntity) not found.")
            return
        }
        
        avatar.removeFromParent()
        print(#function + ": Removed Avatar with owningEntity: \(owningEntity).")
    }
    
    func getAvatar(with owningEntity: Entity) -> Avatar?
    {
        return m_Avatars[owningEntity]
    }
    
    func allAvatars() -> [SKSpriteNode]
    {
        return Array(m_Avatars.values)
    }
    
    func tick(deltaTime: TimeInterval)
    {
        for system in m_Systems
        {
            let componentTypeID = system.requiredComponent
            guard let components = m_ComponentsByType[componentTypeID] else
            {
                print(#function + ": Component does not exist for type: \(componentTypeID).");
                continue
            }

            // All components of the same type are updated by the system.
            for component in components
            {
                // Any other component that the system needs should be searched
                // for in the siblings to this component.
                system.update(deltaTime: deltaTime, component: component, world: m_World)
            }
        }
    }
}
