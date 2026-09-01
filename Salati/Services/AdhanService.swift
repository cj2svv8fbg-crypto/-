import Foundation
import AVFoundation
import UIKit
import UserNotifications

enum AdhanSound: String, CaseIterable, Identifiable {
    case makkah = "makkah"
    case madinah = "madinah"
    case alaqsa = "alaqsa"
    case silent = "silent"
    
    var id: String { rawValue }
    var nameAr: String {
        switch self {
        case .makkah: return "أذان الحرم المكي"
        case .madinah: return "أذان الحرم المدني"
        case .alaqsa: return "أذان هادئ"
        case .silent: return "صامت (إشعار فقط)"
        }
    }
    var icon: String {
        switch self {
        case .makkah: return "🕋"
        case .madinah: return "🕌"
        case .alaqsa: return "🌙"
        case .silent: return "🔕"
        }
    }
    var fileName: String? {
        // ضع ملفات mp3 في bundle بهذه الأسماء لو متوفرة
        switch self {
        case .makkah: return "adhan_makkah"
        case .madinah: return "adhan_madinah"
        case .alaqsa: return "adhan_aqsa"
        case .silent: return nil
        }
    }
    var previewText: String {
        switch self {
        case .makkah: return "بصوت علي ملا - الحرم المكي"
        case .madinah: return "بصوت الحذيفي - الحرم المدني"
        case .alaqsa: return "أذان هادئ للتركيز"
        case .silent: return "بدون صوت"
        }
    }
}

class AdhanManager: ObservableObject {
    static let shared = AdhanManager()
    @Published var selected: AdhanSound {
        didSet { UserDefaults.standard.set(selected.rawValue, forKey: "adhan_selected") }
    }
    @Published var isEnabled: Bool {
        didSet { UserDefaults.standard.set(isEnabled, forKey: "adhan_enabled") }
    }
    private var player: AVAudioPlayer?
    
    init() {
        let saved = UserDefaults.standard.string(forKey: "adhan_selected") ?? AdhanSound.makkah.rawValue
        selected = AdhanSound(rawValue: saved) ?? .makkah
        isEnabled = UserDefaults.standard.object(forKey: "adhan_enabled") as? Bool ?? true
    }
    
    func playPreview() {
        guard selected != .silent, let name = selected.fileName else {
            // اهتزاز فقط لو صامت
            let gen = UINotificationFeedbackGenerator()
            gen.notificationOccurred(.success)
            return
        }
        // يحاول تشغيل من bundle، وإذا غير موجود يشغل نغمة النظام
        if let url = Bundle.main.url(forResource: name, withExtension: "mp3") {
            do {
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                try AVAudioSession.sharedInstance().setActive(true)
                player = try AVAudioPlayer(contentsOf: url)
                player?.volume = 1.0
                player?.play()
            } catch {
                print("Adhan play error: \(error)")
            }
        } else {
            // لا يوجد ملف - شغل صوت افتراضي + اهتزاز
            AudioServicesPlaySystemSound(1005)
            let gen = UINotificationFeedbackGenerator()
            gen.notificationOccurred(.success)
            print("⚠️ ملف الأذان غير موجود في bundle، ضع \(name).mp3 في Assets")
        }
    }
    
    func stopPreview() {
        player?.stop()
    }
    
    // يحدث إعدادات الإشعارات لاستخدام الصوت المختار
    func notificationSound() -> UNNotificationSound {
        if !isEnabled || selected == .silent {
            return UNNotificationSound.default
        }
        if let name = selected.fileName, Bundle.main.url(forResource: name, withExtension: "mp3") != nil {
            // لو الملف موجود باسم مع suffix .mp3 في bundle، iOS يتطلب .caf أو .mp3
            return UNNotificationSound(named: UNNotificationSoundName(rawValue: "\(name).mp3"))
        }
        return UNNotificationSound.default
    }
}
