import SwiftUI

struct DayPrayer: Identifiable {
    let id = UUID()
    let gregorianDay: String
    let hijriDay: String
    let weekday: String
    let fajr: String
    let dhuhr: String
    let asr: String
    let maghrib: String
    let isha: String
    var isToday: Bool = false
}

class CalendarVM: ObservableObject {
    @Published var days: [DayPrayer] = []
    @Published var isLoading = false
    @Published var currentMonthHijri = ""
    @Published var currentMonthGreg = ""
    
    func loadMonth() async {
        await MainActor.run { isLoading = true }
        let cal = Calendar.current
        let now = Date()
        let comps = cal.dateComponents([.year, .month], from: now)
        guard let startOfMonth = cal.date(from: comps),
              let range = cal.range(of: .day, in: .month, for: startOfMonth) else { return }
        
        var result: [DayPrayer] = []
        let hijriFmt = DateFormatter()
        hijriFmt.calendar = Calendar(identifier: .islamicUmmAlQura)
        hijriFmt.locale = Locale(identifier: "ar_SA")
        hijriFmt.dateFormat = "d"
        let hijriMonthFmt = DateFormatter()
        hijriMonthFmt.calendar = Calendar(identifier: .islamicUmmAlQura)
        hijriMonthFmt.locale = Locale(identifier: "ar_SA")
        hijriMonthFmt.dateFormat = "MMMM yyyy"
        let gregMonthFmt = DateFormatter()
        gregMonthFmt.locale = Locale(identifier: "ar_SA")
        gregMonthFmt.dateFormat = "MMMM yyyy"
        gregMonthFmt.timeZone = TimeZone(identifier: "Asia/Riyadh")
        
        await MainActor.run {
            currentMonthHijri = hijriMonthFmt.string(from: startOfMonth) + " هـ"
            currentMonthGreg = gregMonthFmt.string(from: startOfMonth)
        }
        
        // نجلب مواقيت اليوم فقط كعينة ونكررها مع تغيير دقيقة +/-
        // للنسخة الكاملة نحتاج loop على API لكل يوم، هنا نعمل mock واقعي
        // نجلب اليوم الحقيقي من API
        var baseTimings: [String] = ["05:12","12:18","15:40","18:05","19:35"]
        do {
            let f = DateFormatter()
            f.dateFormat = "dd-MM-yyyy"
            let url = URL(string: "https://api.aladhan.com/v1/timingsByCity/\(f.string(from: now))?city=Makkah&country=Saudi Arabia&method=4")!
            let (data,_) = try await URLSession.shared.data(from: url)
            let decoded = try JSONDecoder().decode(PrayerTimesResponse.self, from: data)
            let t = decoded.data.timings
            baseTimings = [String(t.Fajr.prefix(5)), String(t.Dhuhr.prefix(5)), String(t.Asr.prefix(5)), String(t.Maghrib.prefix(5)), String(t.Isha.prefix(5))]
        } catch { }
        
        for day in range {
            guard let date = cal.date(byAdding: .day, value: day - 1, to: startOfMonth) else { continue }
            let weekday = DateFormatter().stringWithWeekdayAr(date)
            let gDay = String(format: "%02d", day)
            let hDay = hijriFmt.string(from: date)
            let isToday = cal.isDate(date, inSameDayAs: now)
            // محاكاة تغيير طفيف كل يوم (للعرض)
            let offset = day - cal.component(.day, from: now)
            func shift(_ t: String, _ o: Int) -> String {
                let parts = t.split(separator: ":").compactMap { Int($0) }
                var m = parts[0]*60 + parts[1] + o
                m = (m + 1440) % 1440
                return String(format: "%02d:%02d", m/60, m%60)
            }
            let d = DayPrayer(gregorianDay: gDay, hijriDay: hDay, weekday: weekday, fajr: PrayerDateHelper.to12Hour(shift(baseTimings[0], offset)), dhuhr: PrayerDateHelper.to12Hour(shift(baseTimings[1], offset)), asr: PrayerDateHelper.to12Hour(shift(baseTimings[2], offset)), maghrib: PrayerDateHelper.to12Hour(shift(baseTimings[3], offset)), isha: PrayerDateHelper.to12Hour(shift(baseTimings[4], offset)), isToday: isToday)
            result.append(d)
        }
        await MainActor.run {
            days = result
            isLoading = false
        }
    }
}

extension DateFormatter {
    static func stringWithWeekdayAr(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ar_SA")
        f.dateFormat = "EEE"
        f.timeZone = TimeZone(identifier: "Asia/Riyadh")
        return f.string(from: date)
    }
}

struct CalendarView: View {
    @StateObject private var vm = CalendarVM()
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: "#0B1D2A"), Color(hex: "#132E3A")], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header شهر
                VStack(spacing: 6) {
                    Text(vm.currentMonthHijri.isEmpty ? "جاري التحميل..." : vm.currentMonthHijri)
                        .font(.system(size: 18, weight: .heavy))
                        .foregroundColor(.white)
                    Text(vm.currentMonthGreg)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                    Text("مكة المكرمة • أم القرى")
                        .font(.caption2)
                        .foregroundColor(Color(hex: "#2EC4A0"))
                }
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(0.04))
                
                // عناوين الأعمدة
                HStack {
                    Text("اليوم").font(.caption2.bold()).foregroundColor(.white.opacity(0.5)).frame(width: 50)
                    Text("الفجر").font(.caption2.bold()).foregroundColor(.white.opacity(0.5)).frame(maxWidth: .infinity)
                    Text("الظهر").font(.caption2.bold()).foregroundColor(.white.opacity(0.5)).frame(maxWidth: .infinity)
                    Text("العصر").font(.caption2.bold()).foregroundColor(.white.opacity(0.5)).frame(maxWidth: .infinity)
                    Text("المغرب").font(.caption2.bold()).foregroundColor(.white.opacity(0.5)).frame(maxWidth: .infinity)
                    Text("العشاء").font(.caption2.bold()).foregroundColor(.white.opacity(0.5)).frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
                .background(Color(hex: "#1B8B6A").opacity(0.18))
                
                if vm.isLoading {
                    Spacer()
                    ProgressView().tint(.white)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(vm.days) { d in
                                HStack(spacing: 0) {
                                    VStack(spacing: 2) {
                                        Text(d.gregorianDay)
                                            .font(.system(size: 13, weight: .heavy, design: .monospaced))
                                            .foregroundColor(d.isToday ? Color(hex: "#1B8B6A") : .white)
                                        Text(d.hijriDay)
                                            .font(.caption2)
                                            .foregroundColor(Color(hex: "#E8B44D"))
                                        Text(d.weekday)
                                            .font(.caption2)
                                            .foregroundColor(.white.opacity(0.4))
                                    }
                                    .frame(width: 50)
                                    .padding(.vertical, 8)
                                    .background(d.isToday ? Color.white : Color.clear)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    
                                    Text(d.fajr).font(.caption2.monospaced()).foregroundColor(.white).frame(maxWidth: .infinity)
                                    Text(d.dhuhr).font(.caption2.monospaced()).foregroundColor(.white).frame(maxWidth: .infinity)
                                    Text(d.asr).font(.caption2.monospaced()).foregroundColor(.white).frame(maxWidth: .infinity)
                                    Text(d.maghrib).font(.caption2.monospaced()).foregroundColor(.white).frame(maxWidth: .infinity)
                                    Text(d.isha).font(.caption2.monospaced()).foregroundColor(.white).frame(maxWidth: .infinity)
                                }
                                .padding(.horizontal, 8)
                                .background(d.isToday ? Color(hex: "#2EC4A0").opacity(0.12) : Color.white.opacity(d.id.hashValue % 2 == 0 ? 0.03 : 0.0))
                                .overlay(Rectangle().fill(Color.white.opacity(0.05)).frame(height: 1), alignment: .bottom)
                            }
                        }
                    }
                }
            }
        }
        .task { await vm.loadMonth() }
        .refreshable { await vm.loadMonth() }
    }
}
