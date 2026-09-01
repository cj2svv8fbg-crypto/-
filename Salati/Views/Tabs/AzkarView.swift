import SwiftUI

struct Zikr: Identifiable {
    let id = UUID()
    let title: String
    let text: String
    let count: String
    let virt: String
}

struct AzkarView: View {
    @State private var selectedTab = 0 // 0 صباح 1 مساء 2 نوم 3 عام
    @State private var completed: Set<UUID> = []
    
    let tabs = ["أذكار الصباح","أذكار المساء","أذكار النوم","أدعية عامة"]
    
    var azkarData: [Zikr] {
        switch selectedTab {
        case 0: return morning
        case 1: return evening
        case 2: return sleep
        default: return general
        }
    }
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: "#0B1D2A"), Color(hex: "#132E3A")], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Picker("", selection: $selectedTab) {
                    ForEach(0..<tabs.count, id: \.self) { i in Text(tabs[i]).tag(i) }
                }
                .pickerStyle(.segmented)
                .padding(12)
                
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(azkarData) { z in
                            ZikrCard(zikr: z, done: completed.contains(z.id)) {
                                if completed.contains(z.id) { completed.remove(z.id) }
                                else {
                                    completed.insert(z.id)
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                }
                            }
                        }
                    }
                    .padding(12)
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationTitle("الأذكار")
    }
    
    let morning: [Zikr] = [
        Zikr(title: "آية الكرسي", text: "اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ...", count: "مرة واحدة", virt: "حافظ من الشيطان"),
        Zikr(title: "سورة الإخلاص", text: "قُلْ هُوَ اللَّهُ أَحَدٌ ...", count: "3 مرات", virt: "تكفيك كل شيء"),
        Zikr(title: "أصبحنا وأصبح الملك لله", text: "أصبحنا وأصبح الملك لله والحمد لله...", count: "مرة", virt: "ذكر الصباح"),
        Zikr(title: "اللهم أنت ربي", text: "اللهم أنت ربي لا إله إلا أنت خلقتني وأنا عبدك...", count: "مرة", virt: "سيد الاستغفار"),
        Zikr(title: "سبحان الله وبحمده", text: "سبحان الله وبحمده", count: "100 مرة", virt: "حطت خطاياه"),
    ]
    let evening: [Zikr] = [
        Zikr(title: "أمسينا وأمسى الملك لله", text: "أمسينا وأمسى الملك لله والحمد لله...", count: "مرة", virt: "ذكر المساء"),
        Zikr(title: "آية الكرسي", text: "اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ...", count: "مرة", virt: "حافظ"),
        Zikr(title: "اللهم بك أمسينا", text: "اللهم بك أمسينا وبك أصبحنا وبك نحيا وبك نموت...", count: "مرة", virt: ""),
        Zikr(title: "أعوذ بكلمات الله", text: "أعوذ بكلمات الله التامات من شر ما خلق", count: "3 مرات", virt: "لا يضرك شيء"),
    ]
    let sleep: [Zikr] = [
        Zikr(title: "باسمك ربي", text: "باسمك ربي وضعت جنبي وبك أرفعه...", count: "مرة", virt: ""),
        Zikr(title: "اللهم قني عذابك", text: "اللهم قني عذابك يوم تبعث عبادك", count: "3 مرات", virt: ""),
        Zikr(title: "سورة الملك", text: "اقرأ سورة الملك قبل النوم", count: "مرة", virt: "منجية من عذاب القبر"),
    ]
    let general: [Zikr] = [
        Zikr(title: "دعاء الهم", text: "اللهم إني عبدك ابن عبدك...", count: "مرة", virt: "يذهب الهم"),
        Zikr(title: "دعاء الكرب", text: "لا إله إلا الله العظيم الحليم...", count: "مرة", virt: ""),
        Zikr(title: "الاستغفار", text: "أستغفر الله العظيم وأتوب إليه", count: "100 مرة", virt: ""),
    ]
}

struct ZikrCard: View {
    let zikr: Zikr
    let done: Bool
    var onToggle: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(zikr.title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(hex: "#E8B44D"))
                Spacer()
                Text(zikr.count)
                    .font(.caption2.bold())
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Capsule())
                Button {
                    onToggle()
                } label: {
                    Image(systemName: done ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundColor(done ? Color(hex: "#2EC4A0") : .white.opacity(0.3))
                }
            }
            Text(zikr.text)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.9))
                .lineSpacing(4)
                .multilineTextAlignment(.leading)
            if !zikr.virt.isEmpty {
                Text("فضلها: \(zikr.virt)")
                    .font(.caption2)
                    .foregroundColor(Color(hex: "#2EC4A0"))
            }
        }
        .padding(14)
        .background(done ? Color(hex: "#2EC4A0").opacity(0.12) : Color.white.opacity(0.06))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(done ? Color(hex: "#2EC4A0").opacity(0.3) : Color.white.opacity(0.06), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .opacity(done ? 0.7 : 1)
    }
}
