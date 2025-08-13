//
//  SimulationClockSystem.swift
//  Nyrmar
//
//  Created by Zachary Duncan on 8/8/25.
//

import Foundation

final class SimulationClockSystem: System
{
    let requiredComponent: ComponentTypeID = Single_SimClockComponent.typeID
    
    func update(deltaTime: TimeInterval, component: any Component)
    {
        guard let clockComp = component as? Single_SimClockComponent else
        {
            return
        }
        
        // clamp bad frames
        let dt = min(max(deltaTime, 0.0), 0.25)
        clockComp.accumulator += dt
        
        // cap steps/frame if desired to avoid spiral-of-death
        var steps = 0
        while clockComp.accumulator >= clockComp.tickDuration && steps < clockComp.frameCap
        {
            clockComp.accumulator -= clockComp.tickDuration
            clockComp.tickIndex &+= 1
            steps += 1
        }
        
        clockComp.quantizedNow = TimeInterval(clockComp.tickIndex) * clockComp.tickDuration
    }
}
