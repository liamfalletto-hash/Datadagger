import SwiftUI

@main
struct OverclockApp: App {
    @StateObject private var game = Game()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(game)
                .preferredColorScheme(.dark)
        }
        .onChange(of: scenePhase) { phase in
            game.handleScenePhase(phase)
        }
    }
}
