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
    private var m_EntityAnchors: [Entity: Component] = [:]
    private var m_ComponentsByType: [ComponentTypeID: [Component]] = [:]
    private var m_Systems: [System]
    private var m_World: GameWorld!
    
    private let m_LocalPlayerControllerID: UUID
    private var m_LocalPlayerControllerEntity: Entity!
    private var m_AvatarEntity: Entity!
    
    private static var hasInitialized = false
    static var shared: EntityAdmin = EntityAdmin()
    
    private init()
    {
        precondition(!EntityAdmin.hasInitialized, "Error: EntityAdmin should only ever be initialized once.")
        EntityAdmin.hasInitialized = true
        m_LocalPlayerControllerID = UUID()
        
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
        
        initializeLocalPlayer()
        initializeControlledAvatar()
    }
    
    // MARK: - Start of debug functions
    func initializeScene(_ world: GameWorld)
    {
        m_World = world
    }
    
    func initializeLocalPlayer()
    {
        let inputComp = GameInputComponent()
        let timestamp = TimeComponent(interval: CACurrentMediaTime())
        m_LocalPlayerControllerEntity = addEntity(with: inputComp, timestamp)
        print("[" + #fileID + "]: " + #function + " -> Registered local player controller")
    }
    
    func initializeControlledAvatar()
    {
        let transformComp = TransformComponent()
        let controlledByComp = ControlledByComponent(controllerID: m_LocalPlayerControllerID)
        m_AvatarEntity = addEntity(with: transformComp, controlledByComp)
        
        let avatarComp = AvatarComponent(avatar: nil, owningEntity: m_AvatarEntity, textureName: "finalfall-logo")
        addComponent(avatarComp, to: m_AvatarEntity)
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
        removeEntitiesWith(componentType: AvatarComponent.typeID)
    }
    // MARK: - End of debug functions
     
    func addEntity(with components: Component...) -> Entity?
    {
        guard !components.isEmpty else
        {
            print("[" + #fileID + "]: " + #function + " -> Entity could not be created with empty Component variadic list.")
            return nil
        }
        
        let entity = Entity()
        addComponents(components, to: entity)
        
        print("[" + #fileID + "]: " + #function + " -> Entity:\(entity) added.")
        return entity
    }
    
    /// Remove an entire entity and all its components. Fast.
    func removeEntity(_ entity: Entity)
    {
        // Remove anchor and all its siblings from type index
        guard let anchorComp = m_EntityAnchors.removeValue(forKey: entity) else
        {
            fatalError("[" + #fileID + "]: " + #function + " -> Anchor Component for Entity:\(entity) not found.")
        }
        
        guard let siblings = anchorComp.siblings else
        {
            fatalError("[" + #fileID + "]: " + #function + " -> No sibling container found for Anchor Component for Entity:\(entity).")
        }
        
        for (typeID, weakRef) in siblings.refs
        {
            guard let sibling = weakRef.value else
            {
                // The sibling is nil and so should have already been removed from the main
                // main Components collection. It also can't be used to compare now anyway.
                continue
            }
            
            if var sameTypeComps = m_ComponentsByType[typeID]
            {
                // Remove any that are identical to our sibling
                sameTypeComps.removeAll { $0 === sibling }
                m_ComponentsByType[typeID] = sameTypeComps.isEmpty ? nil : sameTypeComps
            }
        }
    }

    /// Remove the entity that owns the given component. Slow.
    func removeEntity(ofComponent component: Component)
    {
        // Check if component is an anchor
        if let (entity, _) = m_EntityAnchors.first(where: { $0.value === component })
        {
            removeEntity(entity)
            return
        }
        
        // Otherwise search siblings in anchors
        for (entity, anchor) in m_EntityAnchors
        {
            guard let siblings = anchor.siblings else
            {
                fatalError("[" + #fileID + "]: " + #function + " -> No sibling container found for Anchor Component for Entity:\(entity).")
            }
            
            if siblings.refs.values.contains(where: { $0.value === component })
            {
                removeEntity(entity)
                return
            }
        }
    }
    
    /// Remove all entities that have a component of the given type. Slow.
    func removeEntitiesWith(componentType typeID: ComponentTypeID)
    {
        // Find all entities whose sibling container contains this component type
        let entitiesToRemove = m_EntityAnchors.compactMap { (entity, anchor) -> Entity? in
            if let refs = anchor.siblings?.refs, refs.keys.contains(typeID)
            {
                return entity
            }
            
            return nil
        }
        
        // Remove each entity
        for entity in entitiesToRemove
        {
            removeEntity(entity)
        }
    }
    
    func removeAllEntities()
    {
        AvatarManager.shared.removeAll()
        m_EntityAnchors.removeAll()
        m_ComponentsByType.removeAll()
    }
    
    func allEntities() -> [Entity: Component]
    {
        return m_EntityAnchors
    }
    
    func addComponent(_ component: Component, to entity: Entity)
    {
        if let anchorComp = m_EntityAnchors[entity]
        {
            // Link into existing sibling container
            guard let siblings = anchorComp.siblings else
            {
                fatalError("[" + #fileID + "]: " + #function + " -> Entity:\(entity) anchor has no sibling container.")
            }
            siblings.refs[component.typeID()] = WeakComponentRef(component)
            component.siblings = siblings
        }
        else
        {
            // First component becomes anchor, create its sibling container
            let siblings = SiblingContainer()
            siblings.refs[component.typeID()] = WeakComponentRef(component)
            component.siblings = siblings
            m_EntityAnchors[entity] = component
        }
        
        // Register in type-based index
        m_ComponentsByType[component.typeID(), default: []].append(component)
        print("[" + #fileID + "]: " + #function + " -> Component type \(String(describing: component)) added to Entity:\(entity)")
    }
    
    func addComponents(_ components: [Component], to entity: Entity)
    {
        components.forEach { addComponent($0, to: entity) }
    }
    
    func getComponent<T: Component>(for entity: Entity) -> T?
    {
        return m_EntityAnchors[entity]?.sibling(T.self)
    }
    
    func removeComponent<T: Component>(ofType type: T.Type, from entity: Entity)
    {
        guard let anchorComp = m_EntityAnchors[entity] else
        {
            print("[" + #fileID + "]: " + #function + " -> Entity:\(entity) does not exist.")
            return
        }
            
        let removedID = type.typeID
        
        // Remove from type index
        if var list = m_ComponentsByType[removedID]
        {
            list.removeAll { $0.typeID() == removedID }
            m_ComponentsByType[removedID] = list.isEmpty ? nil : list
        }
        
        // If removing the anchor, promote a sibling or drop entity
        if anchorComp.typeID() == removedID
        {
            if let (_, ref) = anchorComp.siblings?.refs.first(where: { $0.key != removedID })
            {
                m_EntityAnchors[entity] = ref.value
            }
            else
            {
                m_EntityAnchors.removeValue(forKey: entity)
                return
            }
        }
        
        // Remove from shared sibling container
        m_EntityAnchors[entity]?.siblings?.refs.removeValue(forKey: removedID)
    }
    
    func removeAvatar(with owningEntity: Entity)
    {
        guard let avatar = AvatarManager.shared.avatar(for: owningEntity) else
        {
            print("[" + #fileID + "]: " + #function + " -> Avatar with owningEntity:\(owningEntity) not found.")
            return
        }
        
        avatar.removeFromParent()
        print("[" + #fileID + "]: " + #function + " -> Removed Avatar with owningEntity:\(owningEntity).")
    }
    
    func tick(deltaTime: TimeInterval)
    {
        //print("[" + #fileID + "]: " + #function + " -> Entity count:    \(m_EntityComponentsByType.keys.count).")
        //print("[" + #fileID + "]: " + #function + " -> Component count: \(m_ComponentsByType.count).")
        
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
