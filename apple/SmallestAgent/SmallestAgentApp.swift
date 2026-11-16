import SwiftUI

@main struct SmallestAgentApp: App {
    var body: some Scene {
        #if os(macOS)
        WindowGroup { ContentView() }.defaultSize(width: 1180, height: 850)
        #else
        WindowGroup { ContentView() }
        #endif
    }
}
