import SwiftUI
import UIKit
import UserNotifications

struct ContentView: View {
    @StateObject private var vm = PrayerViewModel()
    @StateObject private var adhanMgr = AdhanManager.shared
    @State private var showQibla = false
    @State private var showAdhanSettings = false
    @State private var notifStatus = "جاري..."
    @State private var showNotifAlert = false
    @State private var notifAlertMsg = ""
    
    var body: some View {
        ZStack {
            background
            scrollContent
        }
        .task {
            await vm.loadPrayerTimes()
            checkNotificationStatus()
        }
        .sheet(isPresented: $showQibla) { QiblaView() }
        .sheet(isPresented: $showAdhanSettings) { NavigationView { AdhanSettingsView() } }
        .alert("التنبيهات", isPresented: $showNotifAlert) {
            Button("حسناً", role: .cancel) {}
            if notifAlertMsg.contains("الإعدادات") {
                Button("فتح الإعدادات") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            }
        } message: { Text(notifAlertMsg) }
        .onChange(of: vm.prayers) { _, _ in
            PrayerService.scheduleNotifications(for: vm.prayers)
            checkNotificationStatus()
        }
    }
    
    private var background: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: "#0B1D2A"), Color(hex: "#132E3A"), Color(hex: "#0F3A2E")], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack {
                Image(systemName: "moon.stars")
                    .font(.system(size: 200))
                    .foregroundColor(.white.opacity(0.03))
                    .offset(x: 80, y: 40)
                Spacer()
            }
            .ignoresSafeArea()
        }
    }
    
    private var scrollContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                HeaderView(hijriDate: vm.hijriDate, hijriMonthYear: vm.hijriMonthYear, gregorianDate: vm.gregorianDate)
                NextPrayerCard(nextPrayer: vm.nextPrayer, timeRemaining: vm.timeRemaining, progress: vm.progressToNextPrayer)
                quickButtons
                prayerList
                adhanCard
                ayahCard
                footer
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
        .refreshable { await vm.loadPrayerTimes() }
    }
    
    private var quickButtons: some View {
        HStack(spacing: 10) {
            QuickButton(icon: "location.fill", title: "مكة", subtitle: "21.38°N") {}
            QuickButton(icon: "bell.badge.fill", title: "التنبيهات", subtitle: notifStatus) { handleNotificationTap() }
            QuickButton(icon: "compass.drawing", title: "القبلة", subtitle: "21°") { showQibla.toggle() }
        }
        .onAppear { checkNotificationStatus() }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in checkNotificationStatus() }
    }
    
    private var prayerList: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("مواقيت اليوم").font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                Spacer()
                if vm.isLoading {
                    ProgressView().tint(.white).scaleEffect(0.8)
                } else {
                    Button { Task { await vm.loadPrayerTimes() } } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.clockwise").font(.caption)
                            Text("تحديث").font(.caption)
                        }.foregroundColor(Color(hex: "#2EC4A0"))
                    }
                }
            }
            if let err = vm.errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "wifi.exclamationmark")
                    Text(err).font(.caption)
                }.foregroundColor(.orange.opacity(0.9)).padding(10).background(Color.orange.opacity(0.12)).clipShape(RoundedRectangle(cornerRadius: 10))
            }
            ForEach(vm.prayers) { prayer in
                PrayerRow(prayer: prayer, isNext: prayer.id == vm.nextPrayer?.id, isCurrent: prayer.id == vm.currentPrayer?.id && prayer.id != vm.nextPrayer?.id)
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }
    
    private var adhanCard: some View {
        Button { showAdhanSettings = true } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12).fill(Color(hex: "#1B8B6A")).frame(width: 44, height: 44)
                    Text(adhanMgr.selected.icon).font(.title3)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text("صوت الأذان").font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                    Text(adhanMgr.selected.nameAr + " • " + (adhanMgr.isEnabled ? "مفعل" : "صامت")).font(.caption2).foregroundColor(.white.opacity(0.6))
                }
                Spacer()
                Image(systemName: "chevron.left").font(.caption).foregroundColor(.white.opacity(0.4))
                Image(systemName: "play.circle.fill").font(.title3).foregroundColor(Color(hex: "#2EC4A0"))
            }
            .padding(12)
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.06), lineWidth: 1))
        }
    }
    
    private var ayahCard: some View {
        VStack(spacing: 8) {
            Text("﷽").font(.title3).foregroundColor(Color(hex: "#E8B44D"))
            Text("«إنَّ الصَّلاةَ كَانَتْ عَلَى الْمُؤْمِنِينَ كِتَابًا مَّوْقُوتًا»").font(.system(size: 14, weight: .medium)).foregroundColor(.white.opacity(0.9)).multilineTextAlignment(.center)
            Text("النساء - 103").font(.caption2).foregroundColor(.white.opacity(0.5))
        }.padding(16).frame(maxWidth: .infinity).background(Color.white.opacity(0.06)).clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var footer: some View {
        Text("طريقة الحساب: أم القرى - مكة المكرمة • المنطقة الزمنية Asia/Riyadh")
            .font(.caption2).foregroundColor(.white.opacity(0.35)).multilineTextAlignment(.center).padding(.bottom, 20)
    }
    
    private func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .authorized, .provisional: notifStatus = "مفعلة ✅"
                case .denied: notifStatus = "متوقفة ❌"
                case .notDetermined: notifStatus = "غير مفعلة"
                default: notifStatus = "غير معروفة"
                }
            }
        }
        UNUserNotificationCenter.current().getPendingNotificationRequests { reqs in print("🔔 pending count: \(reqs.count)") }
    }
    
    private func handleNotificationTap() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .notDetermined:
                    UNUserNotificationCenter.current().requestAuthorization(options: [.alert,.sound,.badge]) { granted, _ in
                        DispatchQueue.main.async {
                            if granted {
                                notifStatus = "مفعلة ✅"
                                PrayerService.scheduleNotifications(for: vm.prayers)
                                notifAlertMsg = "تم تفعيل الإشعارات بنجاح ✅\nستصلك رسالة \"حان وقت صلاة ...\" عند دخول كل وقت صلاة."
                                showNotifAlert = true
                            } else {
                                notifAlertMsg = "لم يتم السماح بالإشعارات."
                                showNotifAlert = true
                            }
                        }
                    }
                case .denied:
                    notifAlertMsg = "الإشعارات متوقفة من الإعدادات.\nافتح الإعدادات > الإشعارات > صلاتي وفعّل السماح."
                    showNotifAlert = true
                case .authorized, .provisional:
                    PrayerService.scheduleNotifications(for: vm.prayers)
                    notifAlertMsg = "الإشعارات مفعلة ✅\nتمت إعادة جدولة كل الصلوات.\nستصلك: \"حان وقت صلاة الفجر\" ... وهكذا لكل صلاة في وقتها تماماً."
                    showNotifAlert = true
                default: break
                }
            }
        }
    }
}

struct QuickButton: View {
    let icon: String
    let title: String
    let subtitle: String
    var action: () -> Void = {}
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 16, weight: .semibold)).foregroundColor(Color(hex: "#1B8B6A")).frame(width: 36, height: 36).background(Color.white).clipShape(Circle())
                Text(title).font(.caption).fontWeight(.bold).foregroundColor(.white)
                Text(subtitle).font(.caption2).foregroundColor(.white.opacity(0.5))
            }.frame(maxWidth: .infinity).padding(.vertical, 12).background(Color.white.opacity(0.07)).clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}

struct QiblaView: View {
    @Environment(\.dismiss) var dismiss
    var body: some View {
        ZStack {
            Color(hex: "#0B1D2A").ignoresSafeArea()
            VStack(spacing: 20) {
                HStack {
                    Text("اتجاه القبلة").font(.title3).bold().foregroundColor(.white)
                    Spacer()
                    Button("إغلاق") { dismiss() }.foregroundColor(Color(hex: "#2EC4A0"))
                }.padding()
                ZStack {
                    Circle().stroke(Color.white.opacity(0.12), lineWidth: 2).frame(width: 220, height: 220)
                    Circle().fill(Color.white.opacity(0.06)).frame(width: 180, height: 180)
                    VStack(spacing: 6) {
                        Image(systemName: "location.north.fill").font(.system(size: 44)).foregroundColor(Color(hex: "#E8B44D"))
                        Text("مكة المكرمة").font(.headline).foregroundColor(.white)
                        Text("21.4225° N, 39.8262° E").font(.caption2).foregroundColor(.white.opacity(0.5))
                    }
                    Image(systemName: "arrow.up").font(.title2.bold()).foregroundColor(Color(hex: "#2EC4A0")).offset(y: -95)
                }
                VStack(spacing: 8) {
                    Text("في مكة المكرمة أنت في الحرم 🕋").font(.subheadline).bold().foregroundColor(.white)
                    Text("اتجه نحو الكعبة المشرفة مباشرة. التطبيق يستخدم موقعك الحالي لحساب الاتجاه الدقيق في النسخة الكاملة.").font(.caption).foregroundColor(.white.opacity(0.6)).multilineTextAlignment(.center).padding(.horizontal)
                }.padding(16).background(Color.white.opacity(0.07)).clipShape(RoundedRectangle(cornerRadius: 16)).padding(.horizontal)
                Spacer()
            }
        }
    }
}

#Preview { ContentView() }
