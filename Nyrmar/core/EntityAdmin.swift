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
    static let shared: EntityAdmin = EntityAdmin()
    
    /// The canonical collection of all Components
    private var m_ComponentsByType: [ComponentTypeID: [Component]] = [:]
    
    /// Reverse map for efficient Component -> Entity lookup
    private var m_EntitiesByComponent: [ObjectIdentifier: Entity] = [:]
    
    /// Map for efficient Entity -> Component lookup
    private var m_AnchorComponentByEntity: [Entity: Component] = [:]
    
    private var m_Systems: [System]
    private var m_World: GameWorld!
    
    // MARK: - Singleton Components
    // Sim Clock
    private var m_SimClockEntity: Entity?
    private weak var m_SimClockComponent: Single_SimClockComponent?
    // Sim Clock
    
    // Player Controller
//    private var m_LocalPlayerControllerEntity: Entity!
    // Player Controller
    
    // Input
    private var m_InputEntity: Entity?
    private weak var m_InputComponent: Single_InputComponent?
    // Input
    
    // Control Bindings
    private var m_PlayerBindingsEntity: Entity?
    private weak var m_PlayerBindingsComponent: Single_PlayerBindingsComponent?
    // Control Bindings
    
    // Debug Avatar
    private var m_AvatarEntity: Entity!
    // Debug Avatar
    // MARK: - End Singleton Components
    
    private init()
    {
        // Initialize Systems
        m_Systems = [
            SimulationClockSystem(),
            InputSystem(),
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
            PlayerCommandSystem(),
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
//            CameraSystem(),
                // DebugEntity
                // ImageAnimation
            AvatarSyncSystem(),
            SpawnSystem(),
            //LifeSpanSystem(),
                // SpawnOnDestroy
//            InputCleanupSystem()
        ]
        
        // Initialize Singleton Components
        initializeInput()
//        initializeLocalPlayer()
        initializeControlledAvatar()
    }
    
    func initializeScene(_ world: GameWorld)
    {
        m_World = world
    }
    
    // MARK: - Set Up Singleton Components
    func initializeInput()
    {
        let inputComp = Single_InputComponent()
        let entity = addEntity(with: inputComp)!
        m_InputEntity = entity
        m_InputComponent = inputComp
        print("[" + #fileID + "]: " + #function + " -> Registered input")
    }
    
//    func initializeLocalPlayer()
//    {
//        let inputComp = getInputComponent()
//        let timestamp = TimeComponent(interval: CACurrentMediaTime())
//        let controller = ControllerComponent()
//        m_LocalPlayerInputComponent = inputComp
//        m_LocalPlayerControllerComponent = controller
//        m_LocalPlayerControllerEntity = addEntity(with: inputComp, timestamp, controller)
//        print("[" + #fileID + "]: " + #function + " -> Registered local player controller")
//    }
    
    func initializeControlledAvatar()
    {
        let transformComp = TransformComponent()
        let thrallComp = ThrallComponent(controllerID: getInputComponent().controllerID)
        let physicsComp = PhysicsComponent()
        let forceComp = ForceAccumulatorComponent()
        let baseStatsComp = BaseStatsComponent()
        m_AvatarEntity = addEntity(with: transformComp, thrallComp, physicsComp, forceComp, baseStatsComp)
        
        let avatarComp = AvatarComponent(avatar: nil, owningEntity: m_AvatarEntity, textureName: "finalfall-logo")
        addComponent(avatarComp, to: m_AvatarEntity)
        print("[" + #fileID + "]: " + #function + " -> Registered avatar")
    }
    // MARK: - End Set Up Singleton Components
    
    // MARK: - Singleton Component Accessors
    func getInputComponent() -> Single_InputComponent
    {
        if let inputComp = m_InputComponent
        {
            return inputComp
        }
        
        initializeInput()
        
        return m_InputComponent!
    }
    
    func getPlayerThrallEntity() -> Entity
    {
        return m_AvatarEntity
    }
    
    /// Returns the ThrallComponent currently possessed by `controllerID`, if any.
    func getThrallComponent(forControllerID controllerID: UUID) -> ThrallComponent?
    {
        guard let thrallComps = m_ComponentsByType[ThrallComponent.typeID] as? [ThrallComponent] else
        {
            fatalError("[" + #fileID + "]: " + #function + " -> m_ComponentsByType is improperly keyed.")
        }
        
        for thrallComp in thrallComps
        {
            if thrallComp.controllerID == controllerID
            {
                return thrallComp
            }
        }
        
        return nil
    }
    
    func getPlayerBindingsComponent() -> Single_PlayerBindingsComponent
    {
        if let bindingsComp = m_PlayerBindingsComponent
        {
            return bindingsComp
        }
        
        let mappings = [
            ActionMapping(intent:.moveToLocation, raw:.pointer, deadZone:0.0,  transform: { $0 })
        ]
        
        let bindingsComp = Single_PlayerBindingsComponent(mappings: mappings)
        let entity = addEntity(with: bindingsComp)!
        m_PlayerBindingsEntity = entity
        m_PlayerBindingsComponent = bindingsComp
        return bindingsComp
    }
    
    func getSimClock() -> Single_SimClockComponent
    {
        if let clockComp = m_SimClockComponent
        {
            return clockComp
        }
        
        let clockComp = Single_SimClockComponent()
        let entity = addEntity(with: clockComp)!
        m_SimClockEntity = entity
        m_SimClockComponent = clockComp
        return clockComp
    }
    // MARK: - End Singleton Component Accessors
    
    // MARK: - Debug Avatar
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
    
    func clearAvatars()
    {
        AvatarManager.shared.removeAll()
        removeEntities(withComponentType: AvatarComponent.typeID)
    }
    // MARK: - End Debug Avatar
    
    // MARK: - ECS Accessors
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
        guard let anchorComp = m_AnchorComponentByEntity.removeValue(forKey: entity) else
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
            
            removeComponent(ofType: typeID, from: entity)
        }
        
        print(debugMessage)
    }

    /// Remove the entity that owns the given component.
    func removeEntity(withComponent component: Component)
    {
        guard let entity = getEntity(forComponent: component) else
        {
            print("[" + #fileID + "]: " + #function + " -> No Entity found for Component:\(component)")
            return
        }
        
        removeEntity(entity)
    }
    
    /// Remove all entities that have a component of the given type. Slow.
    func removeEntities(withComponentType componentID: ComponentTypeID)
    {
        guard let components = m_ComponentsByType[componentID] else
        {
            return
        }
        
        for component in components
        {
            if let entity = m_EntitiesByComponent[ObjectIdentifier(component)]
            {
                removeEntity(entity)
            }
        }
    }
    
    func removeAllEntities()
    {
        AvatarManager.shared.removeAll()
        m_AnchorComponentByEntity.removeAll()
        m_ComponentsByType.removeAll()
        m_EntitiesByComponent.removeAll()
    }
    
    /// Returns the Entity that this Component belongs to (if any).
    func getEntity(forComponent component: Component) -> Entity?
    {
        return m_EntitiesByComponent[ObjectIdentifier(component)]
    }
    
    func getEntities(withComponentType componentID: ComponentTypeID) -> [Entity]?
    {
        guard let components = m_ComponentsByType[componentID] else
        {
            return nil
        }
        
        var entities: [Entity] = []
        for component in components
        {
            guard let entity = getEntity(forComponent: component) else
            {
                continue
            }
            
            entities.append(entity)
        }
        
        return entities.isEmpty ? nil : entities
    }
    
    func allEntities() -> [Entity: Component]
    {
        return m_AnchorComponentByEntity
    }
    
    func addComponent(_ component: Component, to entity: Entity)
    {
        if let anchorComp = m_AnchorComponentByEntity[entity]
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
            m_AnchorComponentByEntity[entity] = component
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
    
    func getComponent<T: Component>(ofType componentType: T.Type = T.self, from entity: Entity) -> T?
    {
        return m_AnchorComponentByEntity[entity]?.sibling(T.self)
    }
    
    func allComponents<T: Component>(ofType componentType: T.Type = T.self, where condition: ((T) -> Bool)? = nil) -> [T]?
    {
        guard let componentsOfType = m_ComponentsByType[componentType.typeID] else
        {
            return nil
        }
        
        var validComponents: [T] = []
        for case let component as T in componentsOfType
        {
            if let condition = condition, !condition(component)
            {
                continue
            }
            validComponents.append(component)
        }
        
        return validComponents.isEmpty ? nil : validComponents
    }
    
    func removeComponent(ofType componentID: ComponentTypeID, from entity: Entity)
    {
        guard let anchorComp = m_AnchorComponentByEntity[entity] else
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
                m_AnchorComponentByEntity[entity] = newAnchor
            }
            else
            {
                // No siblings left → entity no longer exists
                m_AnchorComponentByEntity.removeValue(forKey: entity)
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
    // MARK: - End ECS Accessors
    
    // MARK: - Systems Tick
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
    // MARK: - End Systems Tick
}
