//
//  InputCommandManager.swift
//  Nyrmar
//
//  Created by Zachary Duncan on 8/6/25.
//

import UIKit

/// Digital vs. analog distinction
enum InputActionKind: String, Codable
{
    case digital    // e.g. button press / release
    case analog     // e.g. joystick, trigger
}

/// Phase of the action
enum InputActionPhase: String, Codable
{
    case began      // touch down / key down
    case ongoing    // held or continuously reported
    case ended      // touch up / key up
}

/// A single input event, analogous to UE’s FInputActionValue + phase
struct InputCommand: Codable
{
    /// A stable, designer‐driven name for this action (e.g. "Move", "Fire", "Jump")
    let actionName: String
    
    /// Whether this is a digital (on/off) or analog (float) action
    let kind: InputActionKind
    
    /// Press / hold / release phase
    let phase: InputActionPhase
    
    /// For analog: the current value (–1…1 or 0…1); nil for digital
    let value: Float?
    
    /// Source identifier (e.g. "touch", "keyboard", "gamepad-LStick")
    let source: String?
    
    /// High‐precision time recorded via CACurrentMediaTime()
    let timestamp: TimeInterval
}

/// A buffer of discrete input events this frame (or across frames)
struct CommandBuffer: Codable
{
    private(set) var commands: [InputCommand] = []
    
    /// Append a new command
    mutating func push(
        actionName: String,
        kind: InputActionKind,
        phase: InputActionPhase,
        value: Float? = nil,
        source: String? = nil,
        timestamp: TimeInterval = CACurrentMediaTime()
    ){
        let cmd = InputCommand(
            actionName: actionName,
            kind: kind,
            phase: phase,
            value: value,
            source: source,
            timestamp: timestamp
        )
        commands.append(cmd)
    }
    
    /// Clear all buffered commands
    mutating func clear()
    {
        commands.removeAll(keepingCapacity: true)
    }
}

enum GenericInput: Hashable
{
    // Mouse or touch
    case pointerDown, pointerMoved, pointerUp, pointerTap, pointerLongPress
    
    // Joysticks
    case leftStickX, leftStickY, rightStickX, rightStickY
    
    // Controller buttons
    case leftTrigger, rightTrigger, leftBumper, rightBumper, leftThumbstickButton, rightThumbstickButton,
         dpadUp, dpadDown, dpadLeft, dpadRight, leftFaceButton, rightFaceButton, topFaceButton, bottomFaceButton,
         leftSpecialButton, rightSpecialButton
    
    // Special keyboard keys
    case space, enter, esc, backspace, tab, delete, leftShift, leftControl, leftAlt, leftCommand,
         rightShift, rightControl, rightAlt, rightCommand, upArrow, downArrow, leftArrow, rightArrow
    
    // Letters, numbers, symbols
    case custom(String)
}

/// Defines one binding from raw inputs -> a high-level action
struct ActionMapping
{
  /// The name of the InputCommand this binding produces
  let actionName: String
  
  /// Whether this is digital (on/off) or analog (float) input
  let kind: InputActionKind
  
  /// Which raw input(s) this binding listens to
  /// - For digital: a Set of discrete inputs (buttons, taps, keys)
  /// - For analog: a single axis or joystick enum case
  let rawInputs: RawInputSpec
  
  /// Optional scaling/transform for analog values
  let valueTransform: (Float) -> Float
}

/// Raw input spec: either a set of buttons/taps, or a single analog axis
enum RawInputSpec
{
  case digital(Set<GenericInput>)   // e.g. Set([.space, .custom("A")])
  case analog(GenericInput)         // e.g. .custom("LeftStickY")
}

/// Keeps all mappings and can be loaded from JSON/Plist
class InputMappingManager
{
    static let shared = InputMappingManager()
    
    private var mappings: [ActionMapping] = []
    
    private init()
    {
        // Default mappings
        mappings = [
            ActionMapping(
                actionName: "Jump",
                kind:       .digital,
                rawInputs:  .digital([.space, .pointerLongPress]),
                valueTransform: { _ in 1 }
            ),
            ActionMapping(
                actionName: "Move",
                kind:       .analog,
                rawInputs:  .analog(.leftStickX),
                valueTransform: { $0 }   // pass-through
            )
        ]
    }

    func setMappings(_ mappings: [ActionMapping])
    {
        self.mappings = mappings
    }

    /// Given the current raw state, produce zero or more commands
    func commands(
        digitalPressed: Set<GenericInput>,
        analogValues: [GenericInput: Float],
        timestamp: TimeInterval
    ) -> [InputCommand]
    {
        var newCommands: [InputCommand] = []

        for map in mappings
        {
            switch map.rawInputs
            {
            case .digital(let buttons):
                // if any of the buttons are down, fire a began/ongoing/ended
                let isPressed = !buttons.isDisjoint(with: digitalPressed)
                
                // compare against the previous frame’s pressed set to decide phase
                let phase: InputActionPhase = isPressed ? .ongoing : .ended
                
                guard isPressed else { break }

                newCommands.append(
                    InputCommand(
                      actionName: map.actionName,
                      kind:       map.kind,
                      phase:      phase,
                      value:      nil,
                      source:     "digital",
                      timestamp:  timestamp
                    )
                )

            case .analog(let axis):
                if let raw = analogValues[axis]
                {
                    // apply dead-zone or smoothing if needed
                    let value = map.valueTransform(raw)
                    guard abs(value) > 0 else { break }

                    // always treat analog as ongoing while non-zero
                    newCommands.append(
                        InputCommand(
                            actionName: map.actionName,
                            kind:       map.kind,
                            phase:      .ongoing,
                            value:      value,
                            source:     "analog",
                            timestamp:  timestamp
                        )
                    )
                    
                }
            }
        }

        return newCommands
    }
}
