import SwiftUI

struct PrayerRow: View {
    let prayer: Prayer
    let isNext: Bool
    let isCurrent: Bool
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(isNext ? Color(hex: "#1B8B6A") : isCurrent ? Color(hex: "#E8B44D").opacity(0.2) : Color.white.opacity(0.08))
                    .frame(width: 48, height: 48)
                Image(systemName: prayer.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(isNext ? .white : isCurrent ? Color(hex: "#E8B44D") : .white.opacity(0.9))
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(prayer.nameAr)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
                Text(prayer.nameEn)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.55))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 3) {
                Text(prayer.displayTime)
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                if isNext {
                    Text("القادمة")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: "#1B8B6A"))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(Color.white)
                        .clipShape(Capsule())
                } else if isCurrent {
                    Text("الحالية")
                        .font(.caption2)
                        .foregroundColor(Color(hex: "#E8B44D"))
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(isNext ? Color.white.opacity(0.12) : Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(isNext ? Color.white.opacity(0.18) : Color.white.opacity(0.07), lineWidth: 1)
                )
        )
        .shadow(color: isNext ? Color(hex: "#1B8B6A").opacity(0.25) : .clear, radius: 12, x: 0, y: 6)
        .scaleEffect(isNext ? 1.02 : 1.0)
        .animation(.spring(response: 0.4), value: isNext)
    }
}
