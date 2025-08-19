//
//  ClockSystem.swift
//  Korin
//
//  Created by Zachary Duncan on 8/8/25.
//

import Foundation

final class ClockPreSimSystem: System
{
    let requiredComponent: ComponentTypeID = Single_ClockComponent.typeID
    
    func update(deltaTime: TimeInterval, component: any Component, admin: EntityAdmin)
    {
        let clockComp = component as! Single_ClockComponent
        let settingsComp = admin.settingsComponent()
        let frameRateTarget = max(1.0, settingsComp.frameRateTarget)
        clockComp.frameTime = 1.0 / frameRateTarget
        
        let clampedDeltaTime = min(max(deltaTime, 0.0), 0.25)
        clockComp.fixedTickLag += clampedDeltaTime
        
        clockComp.simulationSteps = min(
            UInt64(clockComp.fixedTickLag / clockComp.frameTime),
            clockComp.maxSimulationSteps
        )
    }
}


final class ClockSimSystem: System
{
    let requiredComponent: ComponentTypeID = Single_ClockComponent.typeID
    
    func update(deltaTime: TimeInterval, component: any Component, admin: EntityAdmin)
    {
        let clockComp = component as! Single_ClockComponent
        
        clockComp.fixedTickLag -= deltaTime
        clockComp.quantizedLast = clockComp.quantizedNow
        clockComp.tickIndex &+= 1
        clockComp.quantizedNow = TimeInterval(clockComp.tickIndex) * deltaTime
    }
}

final class ClockPostSimSystem: System
{
    let requiredComponent: ComponentTypeID = Single_ClockComponent.typeID
    
    func update(deltaTime: TimeInterval, component: any Component, admin: EntityAdmin)
    {
        let clockComp = component as! Single_ClockComponent
        
        clockComp.interpolationAlpha = (clockComp.frameTime > 0)
                ? Float(clockComp.fixedTickLag) / Float(clockComp.frameTime)
                : 0
    }
}
