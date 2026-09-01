import SwiftUI
import CoreLocation
import UIKit

// حساب زاوية القبلة من أي موقع للكعبة 21.4225,39.8262
struct QiblaHelper {
    static let kaabaLat = 21.4225
    static let kaabaLng = 39.8262
    
    static func qiblaAngle(from lat: Double, lng: Double) -> Double {
        let phiK = kaabaLat * .pi / 180
        let lambdaK = kaabaLng * .pi / 180
        let phi = lat * .pi / 180
        let lambda = lng * .pi / 180
        let delta = lambdaK - lambda
        let y = sin(delta)
        let x = cos(phi) * tan(phiK) - sin(phi) * cos(delta)
        var q = atan2(y, x) * 180 / .pi
        if q < 0 { q += 360 }
        return q
    }
    static func distanceKm(from lat: Double, lng: Double) -> Double {
        let dLat = (kaabaLat - lat) * .pi / 180
        let dLng = (kaabaLng - lng) * .pi / 180
        let a = sin(dLat/2)*sin(dLat/2) + cos(lat * .pi/180)*cos(kaabaLat * .pi/180)*sin(dLng/2)*sin(dLng/2)
        let c = 2 * atan2(sqrt(a), sqrt(1-a))
        return 6371 * c
    }
}

class CompassManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var heading: Double = 0 // 0-360
    @Published var location: CLLocation?
    @Published var authStatus: CLAuthorizationStatus = .notDetermined
    @Published var qiblaAngle: Double = 0
    @Published var isInMakkah = false
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        checkAuth()
    }
    
    func checkAuth() {
        authStatus = manager.authorizationStatus
        if authStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        } else if authStatus == .authorizedWhenInUse || authStatus == .authorizedAlways {
            start()
        }
    }
    
    func start() {
        if CLLocationManager.headingAvailable() {
            manager.startUpdatingHeading()
        }
        manager.startUpdatingLocation()
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authStatus = manager.authorizationStatus
        if authStatus == .authorizedWhenInUse || authStatus == .authorizedAlways {
            start()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let h = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
        withAnimation(.easeOut(duration: 0.25)) {
            heading = h
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        location = loc
        qiblaAngle = QiblaHelper.qiblaAngle(from: loc.coordinate.latitude, lng: loc.coordinate.longitude)
        let dist = QiblaHelper.distanceKm(from: loc.coordinate.latitude, lng: loc.coordinate.longitude)
        isInMakkah = dist < 20 // داخل مكة
    }
}

struct QiblaCompassView: View {
    @StateObject private var compass = CompassManager()
    @State private var showCalibrate = false
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: "#0B1D2A"), Color(hex: "#132E3A"), Color(hex: "#0F3A2E")], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    // Header
                    VStack(spacing: 6) {
                        Text("اتجاه القبلة 🕋")
                            .font(.system(size: 22, weight: .heavy))
                            .foregroundColor(.white)
                        Text("الكعبة المشرفة • 21.4225°N 39.8262°E")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.55))
                        if compass.isInMakkah {
                            Text("أنت في مكة المكرمة — اتجه للكعبة مباشرة")
                                .font(.caption2).bold()
                                .foregroundColor(Color(hex: "#2EC4A0"))
                                .padding(.horizontal, 12).padding(.vertical, 5)
                                .background(Color(hex: "#2EC4A0").opacity(0.15))
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.top, 8)
                    
                    // البوصلة
                    ZStack {
                        // حلقات
                        Circle().stroke(Color.white.opacity(0.08), lineWidth: 1).frame(width: 270, height: 270)
                        Circle().stroke(Color.white.opacity(0.05), lineWidth: 1).frame(width: 220, height: 220)
                        Circle().fill(Color.white.opacity(0.04)).frame(width: 190, height: 190)
                        
                        // اتجاهات
                        ForEach(0..<4) { i in
                            let deg = Double(i)*90
                            let label = ["ش","ق","ج","غ"][i]
                            Text(label)
                                .font(.caption2.bold())
                                .foregroundColor(.white.opacity(0.4))
                                .offset(y: -125)
                                .rotationEffect(.degrees(deg))
                        }
                        
                        // إبرة القبلة (ثابتة حسب qiblaAngle - heading)
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 44))
                            .foregroundColor(Color(hex: "#E8B44D"))
                            .offset(y: -85)
                            .rotationEffect(.degrees(compass.qiblaAngle - compass.heading))
                            .shadow(color: Color(hex: "#E8B44D").opacity(0.5), radius: 8)
                            .animation(.easeOut(duration: 0.3), value: compass.qiblaAngle - compass.heading)
                        
                        // قرص البوصلة يدور عكس heading
                        ZStack {
                            Circle().stroke(Color(hex: "#2EC4A0").opacity(0.25), lineWidth: 2).frame(width: 270, height: 270)
                            Image(systemName: "location.north.fill")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(Color(hex: "#2EC4A0"))
                                .offset(y: -135)
                            // علامة الشمال
                            VStack(spacing: 2) {
                                Circle().fill(Color.red).frame(width: 8, height: 8)
                                Rectangle().fill(Color.red).frame(width: 2, height: 18)
                            }
                            .offset(y: -62)
                        }
                        .rotationEffect(.degrees(-compass.heading))
                        
                        // المركز
                        VStack(spacing: 3) {
                            Text("🕋")
                                .font(.title2)
                            Text(compass.location == nil ? "--°" : String(format: "%.0f°", compass.qiblaAngle))
                                .font(.system(size: 18, weight: .heavy, design: .monospaced))
                                .foregroundColor(.white)
                            Text("القبلة")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .frame(width: 90, height: 90)
                        .background(Circle().fill(Color(hex: "#0B1D2A")))
                        .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 1))
                    }
                    .frame(height: 300)
                    .onTapGesture { showCalibrate.toggle() }
                    
                    // معلومات
                    HStack(spacing: 10) {
                        InfoBox(title: "اتجاهك", value: String(format: "%.0f°", compass.heading), sub: headingName(compass.heading))
                        InfoBox(title: "القبلة", value: String(format: "%.0f°", compass.qiblaAngle), sub: "من الشمال")
                        InfoBox(title: "المسافة", value: compass.location == nil ? "--" : String(format: "%.0f كم", QiblaHelper.distanceKm(from: compass.location!.coordinate.latitude, lng: compass.location!.coordinate.longitude)), sub: "للكعبة")
                    }
                    
                    // حالة
                    VStack(spacing: 8) {
                        let diff = abs(compass.qiblaAngle - compass.heading)
                        let aligned = min(diff, 360-diff) < 5
                        HStack(spacing: 8) {
                            Circle().fill(aligned ? Color(hex: "#2EC4A0") : Color(hex: "#E8B44D")).frame(width: 10, height: 10)
                            Text(aligned ? "✅ أنت متجه للقبلة الآن" : "حرّك الجوال حتى تطابق السهم مع القبلة")
                                .font(.caption).bold()
                                .foregroundColor(aligned ? Color(hex: "#2EC4A0") : .white.opacity(0.85))
                        }
                        if compass.authStatus == .denied {
                            Text("الإذن مرفوض — فعّل الموقع من الإعدادات")
                                .font(.caption2).foregroundColor(.red.opacity(0.8))
                            Button("فتح الإعدادات") {
                                if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                            }
                            .font(.caption2.bold()).foregroundColor(Color(hex: "#2EC4A0"))
                        } else if compass.location == nil {
                            Text("جاري تحديد موقعك...")
                                .font(.caption2).foregroundColor(.white.opacity(0.5))
                            ProgressView().tint(.white).scaleEffect(0.7)
                        }
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    
                    Text("نصيحة: ضع الجوال بشكل أفقي وحركه على شكل 8 لمعايرة البوصلة")
                        .font(.caption2).foregroundColor(.white.opacity(0.35))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
        }
        .onAppear { compass.checkAuth() }
    }
    
    func headingName(_ h: Double) -> String {
        switch h {
        case 337.5...360, 0..<22.5: return "شمال"
        case 22.5..<67.5: return "شمال شرق"
        case 67.5..<112.5: return "شرق"
        case 112.5..<157.5: return "جنوب شرق"
        case 157.5..<202.5: return "جنوب"
        case 202.5..<247.5: return "جنوب غرب"
        case 247.5..<292.5: return "غرب"
        default: return "شمال غرب"
        }
    }
}

struct InfoBox: View {
    let title: String
    let value: String
    let sub: String
    var body: some View {
        VStack(spacing: 4) {
            Text(title).font(.caption2).foregroundColor(.white.opacity(0.5))
            Text(value).font(.system(size: 16, weight: .heavy, design: .monospaced)).foregroundColor(.white)
            Text(sub).font(.caption2).foregroundColor(Color(hex: "#2EC4A0"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
