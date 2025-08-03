//
//  TimestampComponent.swift
//  Nyrmar
//
//  Created by Zachary Duncan on 8/2/25.
//

import Foundation


/// Component for tracking when input was last updated
class TimestampComponent: Component
{
    static let typeID: ComponentTypeID = componentTypeID(for: TimestampComponent.self)
    var siblings: [ComponentTypeID: WeakComponentRef]?

    var lastUpdated: TimeInterval
//    var targetTime: Date

    init(lastUpdated: TimeInterval)
    {
        self.lastUpdated = lastUpdated
    }
}

class TimerComponent: Component
{
    static let typeID: ComponentTypeID = componentTypeID(for: TimerComponent.self)
    var siblings: [ComponentTypeID: WeakComponentRef]?
    
    var duration: TimeInterval
    
    init(duration: TimeInterval)
    {
        self.duration = duration
    }
}
