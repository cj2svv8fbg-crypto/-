import SwiftUI
import UIKit

struct QuranView: View {
    @State private var selectedSurah = 1
    @State private var ayahs: [Ayah] = []
    @State private var isLoading = false
    @State private var showTasbih = false
    
    let surahs = [
        (1,"الفاتحة"),(2,"البقرة"),(3,"آل عمران"),(36,"يس"),(55,"الرحمن"),(67,"الملك"),(112,"الإخلاص"),(113,"الفلق"),(114,"الناس")
    ]
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: "#0B1D2A"), Color(hex: "#132E3A"), Color(hex: "#0F3A2E")], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // شريط السور
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(surahs, id: \.0) { id, name in
                            Button {
                                selectedSurah = id
                                Task { await loadSurah(id) }
                            } label: {
                                Text(name)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(selectedSurah == id ? .white : .white.opacity(0.6))
                                    .padding(.horizontal, 14).padding(.vertical, 8)
                                    .background(selectedSurah == id ? Color(hex: "#1B8B6A") : Color.white.opacity(0.07))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
                .background(Color.white.opacity(0.03))
                
                if isLoading {
                    Spacer()
                    ProgressView("جاري التحميل...").tint(.white).foregroundColor(.white.opacity(0.7))
                    Spacer()
                } else if ayahs.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Text("﷽")
                            .font(.system(size: 22)).foregroundColor(Color(hex: "#E8B44D"))
                        Text("اختر سورة للقراءة")
                            .foregroundColor(.white.opacity(0.6))
                        Button("تحميل سورة الفاتحة") { Task { await loadSurah(1) } }
                            .tint(Color(hex: "#2EC4A0"))
                    }
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            Text("﷽")
                                .font(.title3).foregroundColor(Color(hex: "#E8B44D"))
                            Text(ayahs.map { $0.text + " ﴿\($0.numberInSurah)﴾" }.joined(separator: " "))
                                .font(.system(size: 18, weight: .medium, design: .rounded))
                                .lineSpacing(10)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.white)
                                .padding(16)
                                .background(Color.white.opacity(0.05))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .padding(16)
                    }
                }
                
                // شريط المسبحة
                HStack(spacing: 10) {
                    Button {
                        showTasbih.toggle()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "circle.grid.cross.fill")
                            Text("المسبحة")
                        }
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(Color(hex: "#1B8B6A"))
                        .clipShape(Capsule())
                    }
                    Spacer()
                    Text("مكة المكرمة • مصحف عثمان")
                        .font(.caption2).foregroundColor(.white.opacity(0.4))
                }
                .padding(12)
                .background(Color.black.opacity(0.2))
            }
        }
        .sheet(isPresented: $showTasbih) { TasbihView() }
        .task { await loadSurah(selectedSurah) }
        .navigationTitle("القرآن")
    }
    
    func loadSurah(_ id: Int) async {
        isLoading = true
        do {
            let url = URL(string: "https://api.alquran.cloud/v1/surah/\(id)/ar.alafasy")!
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoded = try JSONDecoder().decode(QuranResponse.self, from: data)
            ayahs = decoded.data.ayahs
        } catch {
            print("Quran error: \(error)")
        }
        isLoading = false
    }
}

struct Ayah: Codable, Identifiable {
    var id: Int { number }
    let number: Int
    let text: String
    let numberInSurah: Int
}
struct QuranData: Codable { let ayahs: [Ayah] }
struct QuranResponse: Codable { let data: QuranData }

// MARK: - Tasbih
struct TasbihView: View {
    @State private var count = UserDefaults.standard.integer(forKey: "tasbih_count")
    @State private var target = 33
    @Environment(\.dismiss) var dismiss
    let azkar = ["سبحان الله","الحمد لله","الله أكبر","لا إله إلا الله","أستغفر الله"]
    @State private var selectedZikr = "سبحان الله"
    
    var body: some View {
        ZStack {
            Color(hex: "#0B1D2A").ignoresSafeArea()
            VStack(spacing: 20) {
                HStack {
                    Text("المسبحة 📿").font(.title3.bold()).foregroundColor(.white)
                    Spacer()
                    Button("إغلاق") { dismiss() }.foregroundColor(Color(hex: "#2EC4A0"))
                }
                .padding()
                
                Picker("الذكر", selection: $selectedZikr) {
                    ForEach(azkar, id: \.self) { Text($0).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                ZStack {
                    Circle().stroke(Color.white.opacity(0.08), lineWidth: 14).frame(width: 200, height: 200)
                    Circle().trim(from: 0, to: CGFloat(count % target)/CGFloat(target)).stroke(Color(hex: "#2EC4A0"), style: StrokeStyle(lineWidth: 14, lineCap: .round)).frame(width: 200, height: 200).rotationEffect(.degrees(-90)).animation(.easeOut, value: count)
                    VStack(spacing: 4) {
                        Text(selectedZikr).font(.caption).foregroundColor(.white.opacity(0.6))
                        Text("\(count)").font(.system(size: 48, weight: .heavy, design: .rounded)).foregroundColor(.white)
                        Text("/ \(target)").font(.caption2).foregroundColor(.white.opacity(0.4))
                    }
                }
                
                Button {
                    let gen = UIImpactFeedbackGenerator(style: .medium)
                    gen.impactOccurred()
                    count += 1
                    UserDefaults.standard.set(count, forKey: "tasbih_count")
                    if count % target == 0 {
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                    }
                } label: {
                    Text("تسبيح")
                        .font(.title2.bold()).foregroundColor(.white)
                        .frame(width: 180, height: 60)
                        .background(LinearGradient(colors: [Color(hex: "#1B8B6A"), Color(hex: "#2EC4A0")], startPoint: .top, endPoint: .bottom))
                        .clipShape(Capsule())
                        .shadow(color: Color(hex: "#1B8B6A").opacity(0.4), radius: 12)
                }
                
                HStack(spacing: 12) {
                    Button("تصفير") {
                        count = 0
                        UserDefaults.standard.set(0, forKey: "tasbih_count")
                    }
                    .foregroundColor(.red.opacity(0.8)).font(.caption.bold())
                    Spacer()
                    Text("المجموع: \(count)").font(.caption).foregroundColor(.white.opacity(0.5))
                }
                .padding(.horizontal, 24)
                Spacer()
            }
        }
    }
}
