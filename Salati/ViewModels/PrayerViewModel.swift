import Foundation
import Combine

@MainActor
class PrayerViewModel: ObservableObject {
    @Published var prayers: [Prayer] = []
    @Published var hijriDate: String = ""
    @Published var gregorianDate: String = ""
    @Published var hijriMonthYear: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var nextPrayer: Prayer?
    @Published var timeRemaining: String = "--:--:--"
    @Published var currentPrayer: Prayer?
    
    private var timer: Timer?
    private let service = PrayerService()
    private var prayerData: PrayerData?
    
    init() {
        // بيانات افتراضية قبل التحميل
        loadCachedOrMock()
        startTimer()
    }
    
    func loadPrayerTimes() async {
        isLoading = true
        errorMessage = nil
        do {
            let data = try await service.fetchPrayerTimes()
            self.prayerData = data
            self.prayers = data.timings.asArray()
            self.hijriDate = "\(data.date.hijri.weekday.ar) \(data.date.hijri.day) \(data.date.hijri.month.ar)"
            self.hijriMonthYear = "\(data.date.hijri.month.ar) \(data.date.hijri.year) هـ"
            self.gregorianDate = "\(data.date.readable) م"
            updateNextPrayer()
            PrayerService.scheduleNotifications(for: prayers)
            cacheData(data)
        } catch {
            errorMessage = "تعذر جلب المواقيت، يتم عرض آخر تحديث"
            print("Error: \(error)")
        }
        isLoading = false
    }
    
    func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task { @MainActor in
                self.updateNextPrayer()
            }
        }
    }
    
    private func updateNextPrayer() {
        guard !prayers.isEmpty else { return }
        if let next = PrayerService.nextPrayer(from: prayers) {
            self.nextPrayer = next.prayer
            self.timeRemaining = formatInterval(next.remaining)
        }
        self.currentPrayer = PrayerService.currentPrayer(from: prayers)
    }
    
    private func formatInterval(_ interval: TimeInterval) -> String {
        let total = Int(interval)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }
    
    // MARK: - Cache
    private func cacheData(_ data: PrayerData) {
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: "cached_prayer_data")
        }
    }
    
    private func loadCachedOrMock() {
        if let cached = UserDefaults.standard.data(forKey: "cached_prayer_data"),
           let decoded = try? JSONDecoder().decode(PrayerData.self, from: cached) {
            self.prayerData = decoded
            self.prayers = decoded.timings.asArray()
            self.hijriDate = "\(decoded.date.hijri.weekday.ar) \(decoded.date.hijri.day) \(decoded.date.hijri.month.ar)"
            self.hijriMonthYear = "\(decoded.date.hijri.month.ar) \(decoded.date.hijri.year) هـ"
            self.gregorianDate = "\(decoded.date.readable) م"
            updateNextPrayer()
            PrayerService.scheduleNotifications(for: prayers)
            return
        }
        // Mock data لمكة المكرمة في حال عدم وجود إنترنت أول مرة
        let mockTimings = Timings(Fajr: "05:12", Sunrise: "06:30", Dhuhr: "12:18", Asr: "15:40", Maghrib: "18:05", Isha: "19:35", Imsak: "05:02", Midnight: "00:18")
        self.prayers = mockTimings.asArray()
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ar_SA")
        formatter.dateFormat = "EEEE dd MMMM"
        formatter.timeZone = TimeZone(identifier: "Asia/Riyadh")
        self.hijriDate = "الجمعة 12 رجب"
        self.hijriMonthYear = "رجب 1447 هـ"
        self.gregorianDate = formatter.string(from: Date())
        updateNextPrayer()
        PrayerService.scheduleNotifications(for: prayers)
    }
    
    var progressToNextPrayer: Double {
        guard let next = nextPrayer, let nextDate = next.date else { return 0 }
        guard let current = currentPrayer, let currentDate = current.date else { return 0 }
        let total = nextDate.timeIntervalSince(currentDate)
        let elapsed = Date().timeIntervalSince(currentDate)
        if total <= 0 { return 1 }
        return min(max(elapsed / total, 0), 1)
    }
}
