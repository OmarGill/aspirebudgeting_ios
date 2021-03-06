//
//  StateManager.swift
//  Aspire Budgeting
//

import Combine
import Foundation
import os.log

enum AppState: Equatable {
  case loggedOut
  case verifiedExternally
  case authenticatedLocally
  case localAuthFailed
  case needsLocalAuthentication
  case hasDefaultSheet
}

enum AppStateEvent {
  case authenticatedLocally(result: Bool)
  case enteredBackground
  case hasDefaultFile
  case verifiedExternally
}

protocol AppStateManager {
  var currentState: CurrentValueSubject<AppState, Never> { get }

  var needsLocalAuth: Bool { get }
  var isLoggedOut: Bool { get }
  var hasDefaultSheet: Bool { get }

  func processEvent(event: AppStateEvent)
}

final class StateManager: AppStateManager {
  private(set) var currentState = CurrentValueSubject<AppState, Never>(.loggedOut)

  private lazy var transitions: [AppState: Set<AppState>] = {
    var transitions = [AppState: Set<AppState>]()

    transitions[.loggedOut] = [.verifiedExternally]
    transitions[.verifiedExternally] = [.authenticatedLocally, .localAuthFailed]
    transitions[.authenticatedLocally] = [
      .localAuthFailed,
      .hasDefaultSheet,
      .needsLocalAuthentication,
      .loggedOut,
    ]
    transitions[.hasDefaultSheet] = [.needsLocalAuthentication, .loggedOut]
    transitions[.needsLocalAuthentication] = [.authenticatedLocally, .localAuthFailed]
    transitions[.localAuthFailed] = [.authenticatedLocally]

    return transitions
  }()

  func transition(to nextState: AppState) {
    if canTransition(to: nextState) {
      currentState.value = nextState
    } else {
      os_log(
        "Invalid state transition. No state transition performed.",
        log: .stateManager,
        type: .error
      )
    }
  }

  func canTransition(to nextState: AppState) -> Bool {
    guard let validTransitions = transitions[currentState.value] else {
      return false
    }

    return validTransitions.contains(nextState)
  }
}

// MARK: - Computed Properties
extension StateManager {
  var needsLocalAuth: Bool {
    let currentValue = currentState.value
    return currentValue == .verifiedExternally
      || currentValue == .localAuthFailed
      || currentValue == .needsLocalAuthentication
  }

  var isLoggedOut: Bool {
    let currentValue = currentState.value
    return currentValue == .loggedOut
  }

  var hasDefaultSheet: Bool {
    let currentValue = currentState.value
    return currentValue == .hasDefaultSheet
  }
}

// MARK: - … AppStateManager Protocol Methods
extension StateManager {
  func processEvent(event: AppStateEvent) {
    switch event {
    case .verifiedExternally:
      verifiedExternally()

    case .authenticatedLocally(let result):
      authenticatedLocally(result: result)

    case .enteredBackground:
      enteredBackground()

    case .hasDefaultFile:
      foundDefaultFile()
    }
  }
}

// MARK: - Event Handlers
extension StateManager {
  private func verifiedExternally() {
    self.transition(to: .verifiedExternally)
  }

  private func authenticatedLocally(result: Bool) {
    if result {
      os_log(
        "Transitioning to authenticatedLocally",
        log: .stateManager,
        type: .default
      )
      self.transition(to: .authenticatedLocally)
    } else {
      os_log(
        "Transitioning to localAuthFailed",
        log: .stateManager,
        type: .error
      )
      self.transition(to: .localAuthFailed)
    }
  }

  private func enteredBackground() {
    self.transition(to: .needsLocalAuthentication)
  }

  private func foundDefaultFile() {
    self.transition(to: .hasDefaultSheet)
  }
}
