//
//  AppDelegate.swift
//  ChildViewController
//
//  Created by Masatoshi Nishikata on 8/08/19.
//  Copyright © 2019 Catalystwo Limited. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
  
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    // Override point for customization after application launch.
    return true
  }
  
  // MARK: UISceneSession Lifecycle
  
  func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
  }
  
  func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
  }
  
  
}


class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?
  
  func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
    // Create a UIWindow and set it as the root window for the scene
    if let windowScene = scene as? UIWindowScene {
      
#if targetEnvironment(macCatalyst)
      if let titlebar = windowScene.titlebar {
        titlebar.titleVisibility = .hidden
        titlebar.toolbar = nil
      }
#endif

    }
  }
  
  func sceneDidDisconnect(_ scene: UIScene) {
    // Called when the scene is no longer connected or about to be removed
  }
  
  func sceneDidBecomeActive(_ scene: UIScene) {
    // Called when the scene has become active (foreground)
  }
  
  func sceneWillResignActive(_ scene: UIScene) {
    // Called when the scene is about to resign active (background)
  }
  
  func sceneWillEnterForeground(_ scene: UIScene) {
    // Called when the scene is about to enter the foreground
  }
  
  func sceneDidEnterBackground(_ scene: UIScene) {
    // Called when the scene has entered the background
  }
}
