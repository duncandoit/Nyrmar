//
//  AppDelegate.swift
//  Nyrmar
//
//  Created by Zachary Duncan on 7/31/25.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?)
    {
        guard let localControllerID = EntityAdmin.shared.getLoc() else { return }
              var input: InputComponent = EntityAdmin.shared.getComponent(for: localControllerID)
        else { return }

        for press in presses {
            // Only care about keyboard keys
            guard let key = press.key else { continue }

            switch key.keyCode {
            case .keyboardLeftArrow:  input.pressedInputs.insert(.leftArrow)
            case .keyboardRightArrow: input.pressedInputs.insert(.rightArrow)
            case .keyboardUpArrow:    input.pressedInputs.insert(.upArrow)
            case .keyboardDownArrow:  input.pressedInputs.insert(.downArrow)
            case .keyboardSpacebar:   input.pressedInputs.insert(.space)
            default:
                // map letters, numbers, or other keys:
                if let chars = key.charactersIgnoringModifiers, !chars.isEmpty {
                    input.pressedInputs.insert(.custom(chars))
                }
            }
        }
    }
}

