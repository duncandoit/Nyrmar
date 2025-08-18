//
//  Single_InputComponent.swift
//  Nyrmar
//
//  Created by Zachary Duncan on 8/8/25.
//

import Foundation

typealias ControllerID = UUID

enum GenericInput: Hashable, Codable
{
    // Mouse or touch
    case pointerDown, pointerMoved, pointerUp, pointerTap, pointerLongPress
    
    // Joysticks
    case leftStick, rightStick
    
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

/// Which kind of pointer generated this event
enum PointerType: String, Codable
{
  case touch
  case mouse
}

/// Lifecycle phase of the pointer
enum PointerPhase: String, Codable
{
  case down     // finger down or mouse-button down
  case dragged  // finger drag or mouse dragged
  case hover    // mouse moved without button down
  case up       // finger up or mouse-button up
}

/// Raw pointer data, regardless of device
struct PointerData
{
  let id: Int                // touch’s fingerIndex or always 0 for mouse
  let type: PointerType
  let phase: PointerPhase
  let screenLocation: CGPoint
}

enum PlayerCommandIntent: String, Codable
{
    // Axis2D
    case move, moveToLocation
    
    // Key presses
    case primaryFire, secondaryFire, ability1, ability2, ability3, jump, crouch, reload,
         interact, menu, inventory
}

enum CommandValue: Codable
{
    case isPressed(Bool)         // digital
    case axis1D(Float)           // trigger / single axis
    case axis2D(CGPoint)         // x,y / dx,dy
    case screenPosition(CGPoint) // x,y
}

struct PlayerCommand: Codable
{
    let controllerID: UUID
    let intent: PlayerCommandIntent
    let value: CommandValue
    let tickIndex: UInt64
}

enum AxisCurve: Hashable, Codable
{
    case linear
    case power(exp: Float)
    case expo(base: Float)
}

enum DigitalEdgePolicy: Hashable, Codable
{
    case onDown
    case onUp
    case onHold(minSeconds: TimeInterval)
    case repeatEvery(seconds: TimeInterval)
}

struct DigitalMapping: Codable, Hashable
{
    let intent: PlayerCommandIntent
    let inputs: Set<GenericInput> // any pressed among these
    let policy: DigitalEdgePolicy
}

struct Axis1DMapping: Codable, Hashable
{
    let intent: PlayerCommandIntent
    let input: GenericInput
    let deadZone: Float
    let invert: Bool
    let curve: AxisCurve
    let reportEpsilon: Float // throttle command spam
    
    init(intent: PlayerCommandIntent,
         input: GenericInput,
         deadZone: Float = 0.1,
         invert: Bool = false,
         curve: AxisCurve = .linear,
         reportEpsilon: Float = 0.02
    ){
        self.intent = intent
        self.input = input
        self.deadZone = deadZone
        self.invert = invert
        self.curve = curve
        self.reportEpsilon = reportEpsilon
    }
}

struct Axis2DMapping: Codable, Hashable
{
    let intent: PlayerCommandIntent
    let x: GenericInput
    let y: GenericInput
    let deadZone: Float // circular DZ on magnitude
    let invertX: Bool
    let invertY: Bool
    let curve: AxisCurve
    let reportEpsilon: CGFloat
    
    init(intent: PlayerCommandIntent,
         x: GenericInput,
         y: GenericInput,
         deadZone: Float = 0.15,
         invertX: Bool = false,
         invertY: Bool = false,
         curve: AxisCurve = .linear,
         reportEpsilon: CGFloat = 0.02
    ){
        self.intent = intent
        self.x = x
        self.y = y
        self.deadZone = deadZone
        self.invertX = invertX
        self.invertY = invertY
        self.curve = curve
        self.reportEpsilon = reportEpsilon
    }
}

struct PointerMapping: Codable, Hashable
{
    let intent: PlayerCommandIntent
    let phases: Set<PointerPhase>
}

/// Singleton Component: Should have only one instance per `EntityAdmin`
/// Source of the local player's `ControllerID` and inputs.
final class Single_InputComponent: Component
{
    static let typeID = componentTypeID(for: Single_InputComponent.self)
    var siblings: SiblingContainer?
    
    // Source controller
    let controllerID: UUID = UUID()

    // Raw event buffers from the OS
    struct DigitalEdge { let input: GenericInput; let isDown: Bool; let t: TimeInterval }
    var digitalEdges: [DigitalEdge] = []  // one frame only
    var pointerEvents: [PointerData] = [] // one frame only

    // Latest analog samples (overwritten by OS; NOT cleared per frame)
    var analog1D: [GenericInput: Float] = [:]
    var analog2DAxes: [(x: GenericInput, y: GenericInput)] = [] // config, not state

    // Minimal persistence to throttle analog spam
    var lastReported1D: [GenericInput: Float] = [:]
    var lastReported2D: [String: CGPoint] = [:] // key "X+Y" for a pair

    // Output queue (deterministic, serializable)
    var commandQueue: [PlayerCommand] = []
}
