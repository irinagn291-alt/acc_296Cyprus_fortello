import SwiftUI
import UIKit

/// Role: Lineup. Root shell. Onboarding cover, then the locked Quiz lineup. ReviewScreen is applied after onboarding.
struct ContentView: View {
    @State private var rail: LineupRail
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(rail: LineupRail = LineupRail.live()) {
        _rail = State(wrappedValue: rail)
    }

    var body: some View {
        ZStack {
            LineupInk.Palette.background.ignoresSafeArea()
            if rail.isBooting {
                Image(LineupArt.splash)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .accessibilityHidden(true)
            } else if rail.showsOnboarding {
                OnboardingCover(
                    onSkip: { Task { await rail.finishOnboarding() } },
                    onFinish: { Task { await rail.finishOnboarding() } }
                )
            } else {
                QuizView(rail: rail)
            }
        }
        .preferredColorScheme(.light)
        .animation(LineupMotion.swap(reduceMotion), value: rail.showsOnboarding)
        .animation(LineupMotion.swap(reduceMotion), value: rail.isBooting)
        .task { await rail.boot() }
        .task {
            for await notice in NotificationCenter.default.notifications(named: .lineupJob) {
                if let job = LineupJob.parse(notification: notice) {
                    rail.handle(job)
                }
            }
        }
        .onChange(of: scenePhase) { _, phase in
            Task { await rail.handle(phase: phase) }
        }
        .onOpenURL { rail.handle(url: $0) }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
            rail.refreshDay()
        }
    }
}

#Preview {
    ContentView()
}
