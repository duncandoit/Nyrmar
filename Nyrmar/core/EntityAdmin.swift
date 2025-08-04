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
    private var m_World: GameWorld!
    
    private let m_LocalPlayerControllerID: UUID
    private var m_LocalPlayerControllerEntity: Entity
    private var m_AvatarEntity: Entity
    
    private static var hasInitialized = false
    static var shared: EntityAdmin = EntityAdmin()
    
    private init()
    {
        precondition(!EntityAdmin.hasInitialized, "Error: EntityAdmin should only ever be initialized once.")
        EntityAdmin.hasInitialized = true
        
        m_LocalPlayerControllerID = UUID()
        m_LocalPlayerControllerEntity = Entity()
        m_AvatarEntity = Entity()
        
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
        
        // Post initialization
        
        let _ = addEntity(m_LocalPlayerControllerEntity)
        initializeLocalPlayer()
        
        let _ = addEntity(m_AvatarEntity)
        initializeControlledAvatar()
    }
    
    func initializeScene(_ world: GameWorld)
    {
//        clearScene()
        m_World = world
    }
    
    func initializeLocalPlayer()
    {
        let inputComp = GameInputComponent()
        addComponent(inputComp, to: m_LocalPlayerControllerEntity)

        let timestamp = TimeComponent(interval: CACurrentMediaTime())
        addComponent(timestamp, to: m_LocalPlayerControllerEntity)
        print("[" + #fileID + "]: " + #function + " -> Registered local player controller")
    }
    
    func initializeControlledAvatar()
    {
        let transformComp = TransformComponent()
        let controlledByComp = ControlledByComponent(controllerID: m_LocalPlayerControllerID)
        let avatarComp = AvatarComponent(avatar: nil, owningEntity: m_AvatarEntity, textureName: "finalfall-logo")
        addComponents([transformComp, controlledByComp, avatarComp], to: m_AvatarEntity)
        print("[" + #fileID + "]: " + #function + " -> Registered avatar")
    }
    
    func getLocalPlayerID() -> UUID
    {
        return m_LocalPlayerControllerID
    }
    
    func getControlledAvatarEntity() -> Entity
    {
        return m_AvatarEntity
    }
    
    func clearAvatars()
    {
        AvatarManager.shared.removeAll()
        
        for (entity, components) in m_EntityComponentsByType
        {
            let foo = components.contains { (compType: ComponentTypeID, comp: any Component) in
                return compType == AvatarComponent.typeID
            }
            
            if foo
            {
                
            }
        }
    }
     
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
        AvatarManager.shared.removeAll()
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
