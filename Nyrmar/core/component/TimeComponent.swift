//
//  TimeComponent.swift
//  Nyrmar
//
//  Created by Zachary Duncan on 8/2/25.
//

import Foundation

class TimeComponent: Component
{
    static let typeID: ComponentTypeID = componentTypeID(for: TimeComponent.self)
    var siblings: [ComponentTypeID: WeakComponentRef]?
    
    var interval: TimeInterval
    
    init(interval: TimeInterval)
    {
        self.interval = interval
    }
}
