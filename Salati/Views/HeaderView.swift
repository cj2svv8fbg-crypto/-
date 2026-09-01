import SwiftUI

struct HeaderView: View {
    let hijriDate: String
    let hijriMonthYear: String
    let gregorianDate: String
    
    @State private var currentTime = Date()
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 10) {
            // الشعار
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [Color(hex: "#1B8B6A"), Color(hex: "#0F5D4A")], startPoint: .top, endPoint: .bottom))
                        .frame(width: 44, height: 44)
                    Text("🕌")
                        .font(.title3)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("صلاتي")
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                    Text("مواقيت الصلاة - مكة المكرمة")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(formattedCurrentTime)
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    Text("توقيت مكة")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            // التاريخ الهجري والميلادي
            HStack(spacing: 12) {
                VStack(spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.caption)
                            .foregroundColor(Color(hex: "#2EC4A0"))
                        Text("التاريخ الهجري")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    Text(hijriDate.isEmpty ? "--" : hijriDate)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                    Text(hijriMonthYear)
                        .font(.caption2)
                        .foregroundColor(Color(hex: "#E8B44D"))
                }
                .frame(maxWidth: .infinity)
                .padding(12)
                .background(Color.white.opacity(0.07))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                
                VStack(spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.caption)
                            .foregroundColor(Color(hex: "#E8B44D"))
                        Text("التاريخ الميلادي")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    Text(gregorianDate.isEmpty ? "--" : gregorianDate)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text("Asia/Riyadh")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.5))
                }
                .frame(maxWidth: .infinity)
                .padding(12)
                .background(Color.white.opacity(0.07))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .onReceive(timer) { _ in
            currentTime = Date()
        }
    }
    
    private var formattedCurrentTime: String {
        let f = DateFormatter()
        f.dateFormat = "hh:mm:ss a"
        f.locale = Locale(identifier: "ar_SA")
        f.timeZone = TimeZone(identifier: "Asia/Riyadh")
        return f.string(from: currentTime)
    }
}
