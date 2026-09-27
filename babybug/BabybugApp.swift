import SwiftUI
import CoreText

@main
struct BabybugApp: App {
    init() {
        AppFont.register()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
