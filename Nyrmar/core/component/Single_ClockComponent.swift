//
//  Single_ClockComponent.swift
//  Nyrmar
//
//  Created by Zachary Duncan on 8/8/25.
//

import Foundation

/// Singleton Component: Should have only one instance per `EntityAdmin`
/// Maintains quantized frame time information
final class Single_ClockComponent: Component
{
    static let typeID = componentTypeID(for: Single_ClockComponent.self)
    var siblings: SiblingContainer?
    
    // Quantized Time
    
    /// Discrete step counter. Use it to timestamp events/commands, seed deterministic RNG,
    /// drive “every N ticks” logic, and for rollback/replay alignment.
    /// Read-only in all systems.
    var tickIndex: UInt64 = 0
    
    /// Canonical fixed-time “now” (ticks x frameTime). Systems that need an absolute clock
    /// read this instead of wall-clock.
    var quantizedNow: TimeInterval = 0.0
    
    /// Previous fixed time. If a system needs dt, compute dt = quantizedNow - quantizedLast
    /// (which is exactly frameTime when a fixed step runs).
    ///  Keeps all fixed systems independent of the display cadence.
    var quantizedLast: TimeInterval = 0.0
    
    /// Fractional remainder after consuming full steps (fixedTickLag/frameTime).
    /// Only render (or late-visual) systems read it to blend between last and current fixed snapshots.
    /// example: lerp(prevPos, currPos, alpha).
    /// Never use it for simulation.
    var interpolationAlpha: Float = 0.0
    
    /// Internal integrator for the clock system to accumulate wall-clock time.
    /// No other system should touch or read it.
    var fixedTickLag: TimeInterval = 0.0
    
    /// Derrived from the target fps set in `Single_GameSettingsComponent`.
    var frameTime: CGFloat = 0.0
    
    // Config
    
    /// Safety limit against spiral-of-death.
    /// Only the clock uses it to bound the loop. Ordinary systems ignore it.
    let maxSimulationSteps: UInt64
    
    /// Number of simulation steps to be taken this tick in order to reduce the lag.
    var simulationSteps: UInt64 = 0
    
    init(maxSimulationSteps: UInt64 = 5)
    {
        self.maxSimulationSteps = maxSimulationSteps
    }
}
