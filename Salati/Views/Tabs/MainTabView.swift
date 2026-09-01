import SwiftUI

struct MainTabView: View {
    @State private var selected = 0
    
    var body: some View {
        TabView(selection: $selected) {
            ContentView()
                .tabItem {
                    Label("صلاتي", systemImage: "moon.stars.fill")
                }
                .tag(0)
            
            QuranView()
                .tabItem {
                    Label("القرآن", systemImage: "book.fill")
                }
                .tag(1)
            
            AzkarView()
                .tabItem {
                    Label("الأذكار", systemImage: "hands.clap.fill")
                }
                .tag(2)
            
            QiblaCompassView()
                .tabItem {
                    Label("القبلة", systemImage: "location.north.fill")
                }
                .tag(3)
            
            CalendarView()
                .tabItem {
                    Label("التقويم", systemImage: "calendar")
                }
                .tag(4)
        }
        .tint(Color(hex: "#2EC4A0"))
        .onAppear {
            // ستايل التبويب
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(Color(hex: "#0B1D2A"))
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor.white.withAlphaComponent(0.6)
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.white.withAlphaComponent(0.6)]
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color(hex: "#2EC4A0"))
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(Color(hex: "#2EC4A0"))]
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}
