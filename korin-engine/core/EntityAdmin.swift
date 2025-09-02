//
//  EntityAdmin.swift
//  Korin
//
//  Created by Zachary Duncan on 7/31/25.
//

import MetalKit

typealias Entity = UUID

class EntityAdmin
{
    /// The canonical collection of all Components
    private var m_ComponentsByType: [ComponentTypeID: [Component]] = [:]
    
    /// Reverse map for efficient Component -> Entity lookup
    private var m_EntitiesByComponent: [ObjectIdentifier: Entity] = [:]
    
    /// Map for efficient Entity -> Component lookup
    private var m_AnchorComponentByEntity: [Entity: Component] = [:]
    
    private var m_Systems: [System]
    private let m_ClockPreSimSystem: ClockPreSimSystem
    private let m_ClockPostSimSystem: ClockPostSimSystem
    private let m_InputSystem: InputSystem
    private let m_RenderSystem: RenderSystem
    
    required init()
    {
        // Initialize Systems
        m_ClockPreSimSystem = ClockPreSimSystem()
        m_ClockPostSimSystem = ClockPostSimSystem()
        m_InputSystem = InputSystem()
        m_RenderSystem = RenderSystem()
        
        m_Systems = [
            ClockSimSystem(),
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
            CommandSystem(),
                // Unsynchronized movement
            MovementExertionSystem(),
                // AI perception
                // PlatformerPlayerController
                // WallCrawler
                // RaycastMovement
            PhysicsSystem(),
            MovementStateSystem(),
                // Grounded
                // Health
                // Socket
                // Attach
                // DebugEntity
                // ImageAnimation
            ViewportSystem(),
            SpriteSpawnSystem(),
            TilemapSpawnSystem(),
                // LifeSpanSystem,
                // SpawnOnDestroy
                // InputCleanupSystem()
        ]
        
        makeInputComponent()
        makeTestSprite(textureName: "finalfall-logo")
    }
    
    // MARK: Initial Setup
    
    private func makeInputComponent()
    {
        _ = singleton(Single_InputComponent.self)
        print("[" + #fileID + "]: " + #function + " -> Initialized Singleton Entity.")
    }
    
    func makeMetalViewport(layer: CAMetalLayer, pixelsPerUnit: CGFloat = 100)
    {
        let surfaceComp = singleton(Single_MetalSurfaceComponent.self)
        surfaceComp.layer = layer
        surfaceComp.pixelsPerUnit = pixelsPerUnit
        
        let transformComp = TransformComponent()
        let moveStateComp = MoveStateComponent()
        moveStateComp.airControl = 1.0
        
        let physicsComp = PhysicsStateComponent()
        physicsComp.mass           = 1.0
        physicsComp.gravityScale   = 1.0
        physicsComp.linearDrag     = 10.0
        physicsComp.linearDamping  = 0.0
        physicsComp.airDrag        = 0.0
        physicsComp.groundFriction = 0.0
        
        addSiblings([transformComp, moveStateComp, physicsComp], to: surfaceComp)
        
        print("[" + #fileID + "]: " + #function + " -> Made Metal Viewport.")
    }
    
    func makeTestSprite(
        textureName: String,
        worldPosition: CGPoint = .zero,
        worldSize: CGSize = .init(width: 1, height: 1),
        tint: SIMD4<Float> = .init(1, 1, 1, 1),
        addCollision: Bool = false
    ){
        // Author via prefab and the SpawnSystem will resolve to SpriteRenderComponent
        let transform = TransformComponent()
        transform.position = worldPosition
        transform.scale = worldSize

        let prefab = SpritePrefabComponent(source: .texture(name: textureName))
        prefab.size = worldSize
        prefab.tint = tint
        
        let collisionComp = CollisionComponent(shape: .aabb(worldSize))
        let thrallComp = ThrallComponent(controllerID: singleton(Single_InputComponent.self).controllerID)
        let physicsComp = PhysicsStateComponent()
        physicsComp.mass           = 1.0
        physicsComp.gravityScale   = 1.0
        physicsComp.linearDrag     = 10.0
        physicsComp.linearDamping  = 0.0
        physicsComp.airDrag        = 0.0
        physicsComp.groundFriction = 0.0
        
        let forceComp = PhysicsTermComponent()
        forceComp.terms = [
            // Low Gravity
            .init(
                quantity: .acceleration(CGVector(dx: 0, dy: -20)),
                space: .world,
                decay: .infinite,
                remaining: .infinity,
                enabled: true
            )
        ]
        
        let moveStateComp = MoveStateComponent()
        moveStateComp.airControl = 1.0
        
        let exertionComp = MoveExertionComponent()
        let baseStatsComp = BaseStatsComponent()
        baseStatsComp.moveSpeedMax = 10

        _ = addEntity(with: transform, prefab, collisionComp, thrallComp, physicsComp, forceComp, moveStateComp, exertionComp, baseStatsComp)
        
        print("[" + #fileID + "]: " + #function + " -> Made test sprite.")
    }
    
    // MARK: - Helper Accessors
    
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
        
       // print("[" + #fileID + "]: Entity Added: \(entity).")
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
        
        //print("[" + #fileID + "]: Component Added: (typeid:\(String(describing: component.typeID()))) \(String(describing: component)), to Entity:\(entity)")
    }
    
    func addComponents(_ components: [Component], to entity: Entity)
    {
        components.forEach { addComponent($0, to: entity) }
    }
    
    func getComponent<T: Component>(ofType componentType: T.Type = T.self, from entity: Entity) -> T?
    {
        return m_AnchorComponentByEntity[entity]?.sibling(T.self)
    }
    
    func getComponents<T: Component>(ofType componentType: T.Type = T.self, where condition: ((T) -> Bool)? = nil) -> [T]?
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
    
    func getComponents(ofEntity entity: Entity) -> [Component]?
    {
        guard let siblings = m_AnchorComponentByEntity[entity]?.siblings?.refs else
        {
            return nil
        }
        
        var children: [Component] = []
        for sibling in siblings
        {
            if let siblingComponent = sibling.value.value
            {
                children.append(siblingComponent)
            }
        }
        
        return children.isEmpty ? nil : children
    }
    
    func hasComponent<T: Component>(ofType componentType: T.Type = T.self, from entity: Entity) -> Bool
    {
        return getComponent(ofType: componentType, from: entity) != nil ? true : false
    }
    
    func hasSingletonComponent<T: Component & SingletonComponent>(ofType componentType: T.Type = T.self) -> Bool
    {
        return m_ComponentsByType[componentType.typeID] != nil ? true : false
    }
    
    func numberOfComponents<T: Component>(ofType componentType: T.Type = T.self) -> Int
    {
        return getComponents(ofType: componentType)?.count ?? 0
    }
    
    /// Slower than removeComponent(ofType:from:). If you have the Entity, use that one otherwise use this one.
    func removeComponent(_ component: Component)
    {
        guard let entity = getEntity(forComponent: component) else
        {
            print("[" + #fileID + "]: " + #function + " -> Component is not already not registered with any Entity.")
            return
        }
        
        removeComponent(ofType: component.typeID(), from: entity)
    }
    
    /// Faster than removeComponent(). If you have the Entity, use this one otherwise use that one.
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
        
        //print("[" + #fileID + "]: Component Removed: (typeid:\(String(describing: componentID))), Entity:\(entity).")
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
    
    func addSiblings(_ components: [Component], to existingComponent: Component)
    {
        for component in components
        {
            addSibling(component, to: existingComponent)
        }
    }
    
    func singleton<T: Component & SingletonComponent>(_ type: T.Type = T.self) -> T
    {
        if let existing = getComponents(ofType: type)?.first
        {
            return existing
        }
        
        let newSingleton = T()
        _ = addEntity(with: newSingleton)
        
        return newSingleton
    }
    
    // MARK: - Update

    func variableUpdate(rawDeltaTime: TimeInterval)
    {
        let clockComp = singleton(Single_ClockComponent.self)
        m_ClockPreSimSystem.update(deltaTime: rawDeltaTime, component: clockComp, admin: self)
        m_InputSystem.update(deltaTime: rawDeltaTime, component: singleton(Single_InputComponent.self), admin: self)
        
        let clampedDeltaTime = min(max(rawDeltaTime, 0.0), 0.25)
        updateSystems(deltaTime: clampedDeltaTime)
        
        m_ClockPostSimSystem.update(deltaTime: rawDeltaTime, component: clockComp, admin: self)
        m_RenderSystem.update(deltaTime: clockComp.frameTime, component: singleton(Single_MetalSurfaceComponent.self), admin: self)
    }
    
    func fixedUpdate(rawDeltaTime: TimeInterval)
    {
        let clockComp = singleton(Single_ClockComponent.self)
        m_ClockPreSimSystem.update(deltaTime: rawDeltaTime, component: clockComp, admin: self)
        m_InputSystem.update(deltaTime: rawDeltaTime, component: singleton(Single_InputComponent.self), admin: self)

        for _ in 0 ..< clockComp.simulationSteps
        {
            updateSystems(deltaTime: clockComp.frameTime)
        }
        
        m_ClockPostSimSystem.update(deltaTime: rawDeltaTime, component: clockComp, admin: self)
        m_RenderSystem.update(deltaTime: clockComp.frameTime, component: singleton(Single_MetalSurfaceComponent.self), admin: self)
    }
    
    private func updateSystems(deltaTime: TimeInterval)
    {
        for system in m_Systems
        {
            let componentTypeID = system.requiredComponent()
            guard let components = m_ComponentsByType[componentTypeID] else
            {
                continue
            }

            // All components of the same type are updated by the system.
            for component in components
            {
                // Any other component that the system needs should be searched
                // for in the siblings to this component.
                system.update(deltaTime: deltaTime, component: component, admin: self)
            }
        }
    }
}
