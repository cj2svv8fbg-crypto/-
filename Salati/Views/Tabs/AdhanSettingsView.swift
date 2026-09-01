import SwiftUI

struct AdhanSettingsView: View {
    @StateObject private var adhan = AdhanManager.shared
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: "#0B1D2A"), Color(hex: "#132E3A")], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    // تفعيل عام
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("تفعيل الأذان")
                                .font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                            Text("إشعار \"حان وقت صلاة ...\" مع صوت")
                                .font(.caption2).foregroundColor(.white.opacity(0.5))
                        }
                        Spacer()
                        Toggle("", isOn: $adhan.isEnabled)
                            .tint(Color(hex: "#1B8B6A"))
                    }
                    .padding(14)
                    .background(Color.white.opacity(0.07))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    
                    ForEach(AdhanSound.allCases) { sound in
                        Button {
                            adhan.selected = sound
                            adhan.playPreview()
                        } label: {
                            HStack(spacing: 12) {
                                Text(sound.icon)
                                    .font(.title3)
                                    .frame(width: 48, height: 48)
                                    .background(adhan.selected == sound ? Color(hex: "#1B8B6A") : Color.white.opacity(0.07))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(sound.nameAr)
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(.white)
                                    Text(sound.previewText)
                                        .font(.caption2)
                                        .foregroundColor(.white.opacity(0.5))
                                }
                                Spacer()
                                if adhan.selected == sound {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(Color(hex: "#2EC4A0"))
                                }
                                Image(systemName: "play.circle.fill")
                                    .foregroundColor(.white.opacity(0.4))
                                    .font(.title3)
                            }
                            .padding(12)
                            .background(adhan.selected == sound ? Color.white.opacity(0.12) : Color.white.opacity(0.06))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(adhan.selected == sound ? Color(hex: "#2EC4A0").opacity(0.4) : Color.white.opacity(0.06), lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }
                    
                    VStack(spacing: 6) {
                        Text("ℹ️ ملاحظة")
                            .font(.caption.bold()).foregroundColor(Color(hex: "#E8B44D"))
                        Text("في الإشعارات الحقيقية سيعمل صوت الأذان حتى لو التطبيق مغلق. ضع ملفات mp3 باسم adhan_makkah.mp3 داخل المشروع ليشتغل الصوت المخصص، وإلا سيعمل الصوت الافتراضي.")
                            .font(.caption2).foregroundColor(.white.opacity(0.55))
                            .multilineTextAlignment(.center)
                    }
                    .padding(12)
                    .background(Color(hex: "#E8B44D").opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(16)
            }
        }
        .navigationTitle("صوت الأذان")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("تم") { dismiss() }.foregroundColor(Color(hex: "#2EC4A0"))
            }
        }
        .onDisappear { adhan.stopPreview() }
    }
}
