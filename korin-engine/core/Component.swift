//
//  Component.swift
//  Korin
//
//  Created by Zachary Duncan on 7/31/25.
//

/// Type alias for component IDs
typealias ComponentTypeID = UInt32

/// Global counter for assigning unique IDs
private var nextComponentTypeID: ComponentTypeID = 0

/// Protocol for all Components, with a shared sibling container for efficient updates
protocol Component: AnyObject
{
    static var typeID: ComponentTypeID { get }
    var siblings: SiblingContainer? { get set }
    func typeID() -> ComponentTypeID
}

protocol SingletonComponent: Component
{
    init()
}

class SiblingContainer
{
    var refs: [ComponentTypeID: WeakComponentRef] = [:]
}

extension Component
{
    func typeID() -> ComponentTypeID
    {
        return Self.typeID
    }
    
    /// Get a sibling of a specific type
    func sibling<T: Component>(_ type: T.Type = T.self) -> T?
    {
        return siblings?.refs[T.typeID]?.value as? T
    }
}

/// Wrapper to allow weak references to sibling components
class WeakComponentRef
{
    weak var value: Component?
    
    init(_ value: Component)
    {
        self.value = value
    }
}

/// Utility for generating unique type IDs
func componentTypeID<T: Component>(for type: T.Type) -> ComponentTypeID
{
    nextComponentTypeID += 1
    return nextComponentTypeID
}
