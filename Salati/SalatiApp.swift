import SwiftUI
import UIKit
import UserNotifications

// يسمح بظهور الإشعار حتى لو التطبيق مفتوح
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate, ObservableObject {
    static let shared = NotificationDelegate()
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }
}

@main
struct SalatiApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
                .environment(\.layoutDirection, .rightToLeft)
        }
    }
}

// شاشة التحميل 4 ثواني تنزل من فوق لتحت
struct RootView: View {
    @State private var showSplash = true
    @State private var splashOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            MainTabView()
            
            if showSplash {
                SplashView()
                    .offset(y: splashOffset)
                    .transition(.identity)
                    .zIndex(1)
            }
        }
        .onAppear {
            // بعد 4 ثواني تنزل الشاشة لتحت وتختفي
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                withAnimation(.easeInOut(duration: 0.85)) {
                    splashOffset = UIScreen.main.bounds.height + 100
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                    showSplash = false
                }
            }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
        // طلب الإذن مباشرة عند التشغيل
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("✅ تم السماح بالإشعارات")
            } else {
                print("❌ لم يتم السماح: \(String(describing: error))")
            }
        }
        return true
    }
}
