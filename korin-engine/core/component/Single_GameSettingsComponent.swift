//
//  Single_GameSettingsComponent.swift
//  Korin
//
//  Created by Zachary Duncan on 8/17/25.
//

import Foundation

final class Single_GameSettingsComponent: SingletonComponent
{
    static let typeID = componentTypeID(for: Single_GameSettingsComponent.self)
    var siblings: SiblingContainer?
    
    /// Target FPS. 
    var frameRateTarget: CGFloat = 60.0
}
