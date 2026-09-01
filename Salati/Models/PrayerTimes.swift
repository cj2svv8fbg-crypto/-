import Foundation

// MARK: - Models

struct Prayer: Identifiable, Hashable {
    let id = UUID()
    let nameAr: String
    let nameEn: String
    let time: String // "05:12" - 24h للمنطق الداخلي
    let icon: String
    var date: Date? {
        PrayerDateHelper.todayDate(from: time)
    }
    // للعرض بنظام 12 ساعة (مثلاً 05:12 ص / 03:40 م)
    var displayTime: String {
        PrayerDateHelper.to12Hour(time)
    }
}

struct PrayerTimesResponse: Codable {
    let code: Int
    let status: String
    let data: PrayerData
}

struct PrayerData: Codable {
    let timings: Timings
    let date: APIDate
    let meta: Meta
}

struct Timings: Codable {
    let Fajr: String
    let Sunrise: String
    let Dhuhr: String
    let Asr: String
    let Maghrib: String
    let Isha: String
    let Imsak: String
    let Midnight: String
    
    func asArray() -> [Prayer] {
        return [
            Prayer(nameAr: "الفجر", nameEn: "Fajr", time: strip(Timings: Fajr), icon: "moon.stars.fill"),
            Prayer(nameAr: "الشروق", nameEn: "Sunrise", time: strip(Timings: Sunrise), icon: "sunrise.fill"),
            Prayer(nameAr: "الظهر", nameEn: "Dhuhr", time: strip(Timings: Dhuhr), icon: "sun.max.fill"),
            Prayer(nameAr: "العصر", nameEn: "Asr", time: strip(Timings: Asr), icon: "sun.haze.fill"),
            Prayer(nameAr: "المغرب", nameEn: "Maghrib", time: strip(Timings: Maghrib), icon: "sunset.fill"),
            Prayer(nameAr: "العشاء", nameEn: "Isha", time: strip(Timings: Isha), icon: "moon.fill")
        ]
    }
    
    private func strip(Timings t: String) -> String {
        // API returns "05:12 (AST)" sometimes, take first 5 chars
        return String(t.prefix(5))
    }
}

struct APIDate: Codable {
    let readable: String
    let timestamp: String
    let hijri: HijriDate
    let gregorian: GregorianDate
}

struct HijriDate: Codable {
    let date: String
    let format: String
    let day: String
    let weekday: HijriWeekday
    let month: HijriMonth
    let year: String
    let designation: Designation
}

struct HijriWeekday: Codable {
    let en: String
    let ar: String
}

struct HijriMonth: Codable {
    let number: Int
    let en: String
    let ar: String
}

struct Designation: Codable {
    let abbreviated: String
    let expanded: String
}

struct GregorianDate: Codable {
    let date: String
    let format: String
    let day: String
    let weekday: GregorianWeekday
    let month: GregorianMonth
    let year: String
    let designation: Designation
}

struct GregorianWeekday: Codable {
    let en: String
}

struct GregorianMonth: Codable {
    let number: Int
    let en: String
}

struct Meta: Codable {
    let timezone: String
    let method: APIMethod
}

struct APIMethod: Codable {
    let id: Int
    let name: String
}

// MARK: - Helpers

enum PrayerDateHelper {
    static func todayDate(from timeString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Asia/Riyadh")
        guard let time = formatter.date(from: timeString) else { return nil }
        let calendar = Calendar.current
        let now = Date()
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        var todayComponents = calendar.dateComponents([.year, .month, .day], from: now)
        todayComponents.hour = timeComponents.hour
        todayComponents.minute = timeComponents.minute
        todayComponents.second = 0
        todayComponents.timeZone = TimeZone(identifier: "Asia/Riyadh")
        return calendar.date(from: todayComponents)
    }
    
    static func formattedTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "hh:mm a"
        f.locale = Locale(identifier: "ar_SA")
        f.timeZone = TimeZone(identifier: "Asia/Riyadh")
        return f.string(from: date)
    }

    // تحويل "14:05" -> "02:05 م"  و "05:12" -> "05:12 ص" بنظام 12 ساعة
    static func to12Hour(_ time24: String) -> String {
        let inFmt = DateFormatter()
        inFmt.dateFormat = "HH:mm"
        inFmt.locale = Locale(identifier: "en_US_POSIX")
        inFmt.timeZone = TimeZone(identifier: "Asia/Riyadh")
        guard let date = inFmt.date(from: time24) else { return time24 }
        let outFmt = DateFormatter()
        outFmt.dateFormat = "hh:mm a"
        outFmt.locale = Locale(identifier: "ar_SA")
        outFmt.timeZone = TimeZone(identifier: "Asia/Riyadh")
        // النتيجة تكون مثل "٠٢:٠٥ م" - نحولها لأرقام إنجليزية مع ص/م للوضوح
        var s = outFmt.string(from: date)
        // تحويل الأرقام العربية لأرقام إنجليزية لو حبيت تبقي عربية احذف السطرين التاليين
        let arabicToEng: [String:String] = ["٠":"0","١":"1","٢":"2","٣":"3","٤":"4","٥":"5","٦":"6","٧":"7","٨":"8","٩":"9"]
        for (ar,en) in arabicToEng { s = s.replacingOccurrences(of: ar, with: en) }
        return s // مثال: "02:05 م"
    }
}
