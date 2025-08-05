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
    
    
    /// The canonical collection of all Components
    private var m_ComponentsByType: [ComponentTypeID: [Component]] = [:]
    
    /// Reverse map for efficient Component -> Entity lookup
    private var m_EntitiesByComponent: [ObjectIdentifier: Entity] = [:]
    
    /// Map for efficient Entity -> Component lookup
    private var m_ComponentByEntity: [Entity: Component] = [:]
    
    private var m_Systems: [System]
    private var m_World: GameWorld!
    
    // Start Debug properties
    private let m_LocalPlayerControllerID: UUID
    private var m_LocalPlayerControllerEntity: Entity!
    private var m_AvatarEntity: Entity!
    // End Debug properties
    
    static var shared: EntityAdmin = EntityAdmin()
    
    private init()
    {
        m_LocalPlayerControllerID = UUID()
        
        m_Systems = [
            GameInputSystem(),
                // TargetName
                // LifetimeEntity
                // Path data invalidate
                // Fixed update
                // Behavior
                // AimAtTarget
                // MouseCursorFollow
                // Path data
                // AI Strategic
                // AI path find
                // AI behavior
                // AI Spawn
                // AI movement
                // Unsynchronized movement
                // Movement state
            MovementExertionSystem(),
            ParametricMovementSystem(),
                // AI perception
                // PlatformerPlayerController
                // WallCrawler
                // RaycastMovement
            ForceAccumulatorSystem(),
            PhysicsIntegrationSystem(),
                // Grounded
                // Health
                // Socket
                // Attach
                // Camera
                // DebugEntity
                // ImageAnimation
            AvatarSyncSystem(),
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
        let movementComp = MovementComponent(moveSpeed: 50.0, destination: nil)
        let physicsComp = PhysicsComponent()
        let forceComp = ForceAccumulatorComponent()
        let curveComp = CurveComponent(curveType: .easeIn)
        m_AvatarEntity = addEntity(with: transformComp, controlledByComp, movementComp, physicsComp, forceComp, curveComp)
        
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
        guard let anchorComp = m_ComponentByEntity.removeValue(forKey: entity) else
        {
            fatalError("[" + #fileID + "]: " + #function + " -> Anchor Component for Entity:\(entity) not found.")
        }
        
        guard let siblings = anchorComp.siblings else
        {
            fatalError("[" + #fileID + "]: " + #function + " -> No sibling container found for Anchor Component for Entity:\(entity).")
        }
        
        var debugMessage = "[" + #fileID + "]: " + #function + " -> Entity:\(entity) removed.\n"
        debugMessage += "  Removing \(siblings.refs.count) siblings:\n"
        
        for (typeID, weakRef) in siblings.refs
        {
            guard let sibling = weakRef.value else
            {
                // The sibling is nil and so should have already been removed from the main
                // main Components collection. It also can't be used to compare now anyway.
                continue
            }
            
            debugMessage += "    \(String(describing: sibling))\n"
            
            removeComponentType(typeID , from: entity)
        }
        
        print(debugMessage)
    }

    /// Remove the entity that owns the given component.
    func removeEntity(ofComponent component: Component)
    {
        guard let entity = getEntity(forComponent: component) else
        {
            print("[" + #fileID + "]: " + #function + " -> No Entity found for Component:\(component)")
            return
        }
        
        removeEntity(entity)
    }
    
    /// Remove all entities that have a component of the given type. Slow.
    func removeEntitiesWith(componentType typeID: ComponentTypeID)
    {
        // Find all entities whose sibling container contains this component type
        let entitiesToRemove = m_ComponentByEntity.compactMap { (entity, anchor) -> Entity? in
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
        m_ComponentByEntity.removeAll()
        m_ComponentsByType.removeAll()
    }
    
    /// Returns the Entity that this Component belongs to (if any).
    func getEntity(forComponent component: Component) -> Entity?
    {
        return m_EntitiesByComponent[ObjectIdentifier(component)]
    }
    
    func allEntities() -> [Entity: Component]
    {
        return m_ComponentByEntity
    }
    
    func addComponent(_ component: Component, to entity: Entity)
    {
        if let anchorComp = m_ComponentByEntity[entity]
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
            m_ComponentByEntity[entity] = component
        }
        
        // Register in type-based index
        m_ComponentsByType[component.typeID(), default: []].append(component)
        
        // record reverse mapping
        m_EntitiesByComponent[ObjectIdentifier(component)] = entity
        
        print("[" + #fileID + "]: " + #function + " -> Component type \(String(describing: component)) added to Entity:\(entity)")
    }
    
    func addComponents(_ components: [Component], to entity: Entity)
    {
        components.forEach { addComponent($0, to: entity) }
    }
    
    func getComponent<T: Component>(for entity: Entity) -> T?
    {
        return m_ComponentByEntity[entity]?.sibling(T.self)
    }
    
    func removeComponentType(_ componentID: ComponentTypeID, from entity: Entity)
    {
        guard let anchorComp = m_ComponentByEntity[entity] else
        {
            print("[" + #fileID + "]: " + #function + " -> Entity:\(entity) does not exist.")
            return
        }
        
        guard let siblings = anchorComp.siblings else
        {
            print("[" + #fileID + "]: " + #function + " -> Anchor Component for Entity:\(entity) does not have a sibling container.")
            return
        }

        guard let weakSibling = siblings.refs[componentID] else
        {
            print("[" + #fileID + "]: " + #function + " -> Sibling of type \(String(describing: componentID)) for Entity:\(entity) is not found.")
            return
        }
              
        guard let sibling = weakSibling.value else
        {
            print("[" + #fileID + "]: " + #function + " -> Component of type \(String(describing: componentID)) on Entity:\(entity) is nil.")
            return
        }

        // Remove from the global type‐index
        if var sameTypeComponents = m_ComponentsByType[componentID]
        {
            sameTypeComponents.removeAll { $0 === sibling }
            m_ComponentsByType[componentID] = sameTypeComponents.isEmpty ? nil : sameTypeComponents
        }

        // Remove the reverse‐lookup entry
        m_EntitiesByComponent.removeValue(forKey: ObjectIdentifier(sibling))

        // If we removed the anchor, promote another sibling (or drop the entity)
        if sibling === anchorComp
        {
            // Try to pick any other sibling as new anchor
            if let (_, newRef) = siblings.refs.first(where: { $0.key != componentID }),
               let newAnchor = newRef.value
            {
                m_ComponentByEntity[entity] = newAnchor
            }
            else
            {
                // No siblings left → entity no longer exists
                m_ComponentByEntity.removeValue(forKey: entity)
                return
            }
        }

        // Remove from the shared sibling container
        siblings.refs.removeValue(forKey: componentID)
        
        print("[" + #fileID + "]: " + #function + " -> Removed Component:\(String(describing: componentID)) from Entity:\(entity).")
    }
    
    /// Add a new component as a sibling to an existing component and the same entity.
    func addSibling(_ component: Component, to existingComponent: Component)
    {
        guard let entity = getEntity(forComponent: existingComponent) else
        {
            print("[" + #fileID + "]: " + #function + " -> Component is not registered with an Entity so cannot be linked with a sibling.")
            return
        }
        
        addComponent(component, to: entity)
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
        //print("[" + #fileID + "]: " + #function + " -> Entity count:    \(allEntities().count).")
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
