import SwiftUI

@main
struct SporeGardenApp: App {
    @StateObject private var game = GameModel()
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
