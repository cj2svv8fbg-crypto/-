import Foundation
import Combine
import UserNotifications

class PrayerService: ObservableObject {
    // Aladhan API - طريقة أم القرى مكة المكرمة (method=4)
    private let baseURL = "https://api.aladhan.com/v1/timingsByCity"
    
    func fetchPrayerTimes(
        city: String = "Makkah",
        country: String = "Saudi Arabia",
        method: Int = 4
    ) async throws -> PrayerData {
        var components = URLComponents(string: baseURL)!
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy"
        let dateString = formatter.string(from: Date())
        components.path += "/\(dateString)"
        components.queryItems = [
            URLQueryItem(name: "city", value: city),
            URLQueryItem(name: "country", value: country),
            URLQueryItem(name: "method", value: "\(method)")
        ]
        
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        let decoded = try JSONDecoder().decode(PrayerTimesResponse.self, from: data)
        return decoded.data
    }
    
    // حساب الصلاة القادمة
    static func nextPrayer(from prayers: [Prayer]) -> (prayer: Prayer, remaining: TimeInterval)? {
        let now = Date()
        let calendar = Calendar.current
        
        // ترتيب الصلوات حسب الوقت
        let sorted = prayers.sorted { ($0.date ?? .distantFuture) < ($1.date ?? .distantFuture) }
        
        for prayer in sorted {
            guard let date = prayer.date else { continue }
            if date > now {
                return (prayer, date.timeIntervalSince(now))
            }
        }
        // إذا انتهت كل الصلوات اليوم، الفجر القادم غداً
        if let fajr = sorted.first(where: { $0.nameEn == "Fajr" }), let fajrDate = fajr.date {
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: fajrDate)!
            return (fajr, tomorrow.timeIntervalSince(now))
        }
        return nil
    }
    
    static func currentPrayer(from prayers: [Prayer]) -> Prayer? {
        let now = Date()
        let sorted = prayers.sorted { ($0.date ?? .distantFuture) < ($1.date ?? .distantFuture) }
        var last: Prayer? = sorted.last // العشاء أمس إذا قبل الفجر
        for prayer in sorted {
            guard let date = prayer.date else { continue }
            if date <= now {
                last = prayer
            } else {
                break
            }
        }
        return last
    }
    
    // جدولة إشعارات لكل صلاة عند دخول وقتها - "حان وقت صلاة العصر"
    static func scheduleNotifications(for prayers: [Prayer]) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else {
                print("🔕 الإشعارات غير مفعلة من النظام")
                return
            }
            
            let now = Date()
            let calendar = Calendar.current
            
            for prayer in prayers where prayer.nameEn != "Sunrise" {
                guard let baseDate = prayer.date else { continue }
                
                // نحسب أقرب موعد قادم لهذه الصلاة (اليوم أو غداً)
                var targetDate = baseDate
                if targetDate <= now {
                    // إذا وقتها راح اليوم، جدولها لبكرة بنفس الوقت
                    targetDate = calendar.date(byAdding: .day, value: 1, to: targetDate)!
                }
                
                let content = UNMutableNotificationContent()
                content.title = "حان وقت صلاة \(prayer.nameAr) 🕌"
                content.body = "مواقيت مكة المكرمة - \(prayer.displayTime) • \(prayer.nameEn)"
                content.sound = AdhanManager.shared.notificationSound()
                content.badge = 1
                content.interruptionLevel = .timeSensitive // يظهر حتى في التركيز
                
                // نستخدم تقويم مكة
                var comps = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: targetDate)
                comps.second = 0
                comps.timeZone = TimeZone(identifier: "Asia/Riyadh")
                
                let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
                let request = UNNotificationRequest(identifier: "salati_\(prayer.nameEn)_\(targetDate.timeIntervalSince1970)", content: content, trigger: trigger)
                center.add(request) { error in
                    if let error = error {
                        print("❌ فشل جدولة \(prayer.nameAr): \(error)")
                    } else {
                        print("✅ تم جدولة إشعار \(prayer.nameAr) at \(targetDate)")
                    }
                }
            }
            
            // تحقق: اطبع الإشعارات المجدولة
            center.getPendingNotificationRequests { reqs in
                print("📋 الإشعارات المجدولة: \(reqs.count)")
                for r in reqs { print(" - \(r.identifier)") }
            }
        }
    }
    
    // لاختبار فوري - يرسل إشعار بعد ثواني (للتجربة فقط)
    static func sendTestNotification(after seconds: TimeInterval = 5) {
        let content = UNMutableNotificationContent()
        content.title = "حان وقت صلاة العصر 🕌"
        content.body = "هذا إشعار تجريبي - مواقيت مكة المكرمة"
        content.sound = AdhanManager.shared.notificationSound()
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        let req = UNNotificationRequest(identifier: "test_salati", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(req)
    }
}
