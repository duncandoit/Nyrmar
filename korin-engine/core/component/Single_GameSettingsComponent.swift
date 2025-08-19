//
//  Single_GameSettingsComponent.swift
//  Korin
//
//  Created by Zachary Duncan on 8/17/25.
//

import Foundation

class Single_GameSettingsComponent: Component
{
    static let typeID = componentTypeID(for: Single_Camera2DComponent.self)
    var siblings: SiblingContainer?
    
    /// Target FPS. 
    var frameRateTarget: CGFloat = 60.0
}
