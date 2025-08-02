//
//  Component.swift
//  Nyrmar
//
//  Created by Zachary Duncan on 7/31/25.
//

/// Type alias for component IDs
typealias ComponentTypeID = UInt32

/// Global counter for assigning unique IDs
private var nextComponentTypeID: ComponentTypeID = 0

/// Protocol for all Components
protocol Component: AnyObject
{
    static var typeID: ComponentTypeID { get }
    var siblings: [ComponentTypeID: WeakComponentRef]? { get set }
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
        return siblings?[T.typeID]?.value as? T
    }
}

/// Wrapper to allow weak references to sibling components
class WeakComponentRef
{
    weak var value: Component?
    init(_ value: Component) { self.value = value }
}

/// Utility for generating unique type IDs
func componentTypeID<T: Component>(for type: T.Type) -> ComponentTypeID
{
    nextComponentTypeID += 1
    return nextComponentTypeID
}
