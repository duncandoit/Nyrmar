//
//  EntityAdmin.swift
//  Nyrmar
//
//  Created by Zachary Duncan on 7/31/25.
//

import SpriteKit
import GameplayKit

class EntityAdmin
{
    private var m_EntityComponentsByType: [Entity: [ComponentTypeID: Component]] = [:]
    private var m_ComponentsByType: [ComponentTypeID: [Component]] = [:]
    private var m_Systems: [System]
//    private var m_Avatars: [Entity: Avatar] = [:]
    private var m_World: GameWorld!
    
    private static var hasInitialized = false
    static var shared: EntityAdmin = EntityAdmin()
    
    private init()
    {
        precondition(!EntityAdmin.hasInitialized, "Error: EntityAdmin should only ever be initialized once.")
        EntityAdmin.hasInitialized = true
        
        m_Systems = [
                // TargetName
                // LifetimeEntity
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
            SpawnSystem(),
            //LifeSpanSystem(),
                // SpawnOnDestroy
            GameInputCleanupSystem()
        ]
    }
    
    func initializeScene(_ world: GameWorld)
    {
//        clearScene()
        m_World = world
    }
    
//    func clearScene()
//    {
////        m_Avatars.removeAll()
////        for (entity, components) in m_EntityComponentsByType
//        var i = m_EntityComponentsByType.count
//        for _ in 0 ..< m_EntityComponentsByType.count
//        {
//            i -= 1
//            let isAvatarEntity = components.contains { (compType: ComponentTypeID, comp: any Component) in
//                return compType == AvatarComponent.typeID
//            }
//            
//        }
//    }
     
    func addEntity(_ entity: Entity = Entity()) -> Entity?
    {
        guard m_EntityComponentsByType[entity] == nil else
        {
            print("[" + #fileID + "]: " + #function + " -> Entity:\(entity) already exists.")
            return nil
        }
        
        m_EntityComponentsByType[entity] = [:]
        print("[" + #fileID + "]: " + #function + " -> Entity:\(entity) added.\n")
        return entity
    }
    
    func removeEntity(_ entity: Entity)
    {
        guard let components = m_EntityComponentsByType.removeValue(forKey: entity) else
        {
            print("[" + #fileID + "]: " + #function + " -> Entity:\(entity) does not exist.")
            return
        }
        
        for (typeId, comp) in components
        {
            m_ComponentsByType[typeId]?.removeAll { $0 === comp }
            if m_ComponentsByType[typeId]?.isEmpty == true
            {
                m_ComponentsByType.removeValue(forKey: typeId)
            }
        }
    }
    
    func removeAllEntities()
    {
        AvatarManager.shared.removeAllAvatars()
        m_EntityComponentsByType.removeAll()
        m_ComponentsByType.removeAll()
    }
    
    func allEntities() -> [Entity: [ComponentTypeID: Component]]
    {
        return m_EntityComponentsByType
    }
    
    func addComponent(_ component: Component, to entity: Entity)
    {
        guard var components = m_EntityComponentsByType[entity] else
        {
            print("[" + #fileID + "]: " + #function + " -> Entity:\(entity) does not exist.")
            return
        }
        
        components[component.typeID()] = component
        m_EntityComponentsByType[entity] = components
        m_ComponentsByType[component.typeID(), default: []].append(component)
        print("[" + #fileID + "]: " + #function + " -> Component of type: \(String(describing: component))(id:\(component.typeID())) added.")
        
        updateSiblingReferences(for: entity)
    }
    
    func addComponents(_ components: [Component], to entity: Entity)
    {
        for component in components
        {
            addComponent(component, to: entity)
        }
    }
    
    func getComponent<T: Component>(for entity: Entity) -> T?
    {
        return m_EntityComponentsByType[entity]?[T.typeID] as? T
    }
    
    func removeComponent<T: Component>(ofType type: T.Type, from entity: Entity)
    {
        guard var components = m_EntityComponentsByType[entity] else
        {
            print("[" + #fileID + "]: " + #function + " -> Entity:\(entity) does not exist.")
            return
        }
        
        guard let removed = components.removeValue(forKey: T.typeID) else
        {
            print("[" + #fileID + "]: " + #function + " -> Component not found on Entity:\(entity).")
            return
        }
                
        m_EntityComponentsByType[entity] = components
        m_ComponentsByType[T.typeID]?.removeAll { $0 === removed }
        
        if m_ComponentsByType[T.typeID]?.isEmpty == true
        {
            m_ComponentsByType.removeValue(forKey: T.typeID)
        }

        updateSiblingReferences(for: entity)
    }
    
    private func updateSiblingReferences(for entity: Entity)
    {
        guard let components = m_EntityComponentsByType[entity] else
        {
            print("[" + #fileID + "]: " + #function + " ->  Entity not found: \(entity).")
            return
        }
        
        let weakRefs = components.mapValues { WeakComponentRef($0) }
        for component in components.values
        {
            component.siblings = weakRefs
        }
    }
    
    func removeAvatar(with owningEntity: Entity)
    {
        guard let avatar = AvatarManager.shared.avatar(for: owningEntity) else
        {
            print("[" + #fileID + "]: " + #function + " -> Avatar with owningEntity: \(owningEntity) not found.")
            return
        }
        
        avatar.removeFromParent()
        print("[" + #fileID + "]: " + #function + " -> Removed Avatar with owningEntity: \(owningEntity).")
    }
    
    func tick(deltaTime: TimeInterval)
    {
        print("[" + #fileID + "]: " + #function + " -> Entity count:    \(m_EntityComponentsByType.keys.count).")
        print("[" + #fileID + "]: " + #function + " -> Component count: \(m_ComponentsByType.count).")
        
        for system in m_Systems
        {
            let componentTypeID = system.requiredComponent
            guard let components = m_ComponentsByType[componentTypeID] else
            {
                //print("[" + #fileID + "]: " + #function + " -> Component does not exist for type:\(String(describing: component)).");
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
