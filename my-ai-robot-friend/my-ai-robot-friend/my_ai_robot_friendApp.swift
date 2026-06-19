//
//  my_ai_robot_friendApp.swift
//  my-ai-robot-friend
//
//  Created by 申方达 on 2026/6/18.
//

import SwiftUI

@main
struct my_ai_robot_friendApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                RootView()
            } else {
                OnboardingView {
                    withAnimation(GenUIMotion.morph) {
                        hasCompletedOnboarding = true
                    }
                }
            }
        }
    }
}
