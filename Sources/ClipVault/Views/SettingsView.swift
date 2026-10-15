import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem { Label("一般", systemImage: "gear") }
            ExclusionSettingsView()
                .tabItem { Label("排除規則", systemImage: "hand.raised") }
            AboutView()
                .tabItem { Label("關於", systemImage: "info.circle") }
        }
        .frame(width: 500, height: 480)
    }
}
