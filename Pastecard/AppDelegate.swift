//
//  AppDelegate.swift
//  Pastecard
//
//  Created by Brian Sutorius on 5/2/23.
//  to support home screen actions per
//  https://www.kodeco.com/29646799-home-screen-quick-actions-for-ios-getting-started

import UIKit

enum ActionType: String {
  case swapIcon = "swapIcon"
}

enum Action: Equatable {
  case swapIcon

  init?(shortcutItem: UIApplicationShortcutItem) {
    guard let type = ActionType(rawValue: shortcutItem.type) else {
      return nil
    }

    switch type {
    case .swapIcon:
      self = .swapIcon
    }
  }
}

class ActionService: ObservableObject {
  static let shared = ActionService()
  @Published var action: Action?
}


class AppDelegate: NSObject, UIApplicationDelegate {
  private let actionService = ActionService.shared

  func application(
    _ application: UIApplication,
    configurationForConnecting connectingSceneSession: UISceneSession,
    options: UIScene.ConnectionOptions
  ) -> UISceneConfiguration {
    if let shortcutItem = options.shortcutItem {
      actionService.action = Action(shortcutItem: shortcutItem)
    }

    let configuration = UISceneConfiguration(
      name: connectingSceneSession.configuration.name,
      sessionRole: connectingSceneSession.role
    )
    configuration.delegateClass = SceneDelegate.self
    return configuration
  }
}

class SceneDelegate: NSObject, UIWindowSceneDelegate {
  private let actionService = ActionService.shared

  func windowScene(
    _ windowScene: UIWindowScene,
    performActionFor shortcutItem: UIApplicationShortcutItem,
    completionHandler: @escaping (Bool) -> Void
  ) {
    actionService.action = Action(shortcutItem: shortcutItem)
    completionHandler(true)
  }
}
