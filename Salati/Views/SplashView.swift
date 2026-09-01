import SwiftUI

struct SplashView: View {
    @State private var progress: CGFloat = 0
    @State private var dots = ""
    
    var body: some View {
        ZStack {
            // نفس خلفية التطبيق تماماً
            LinearGradient(colors: [Color(hex: "#0B1D2A"), Color(hex: "#132E3A"), Color(hex: "#0F3A2E")],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            // زخرفة خفيفة
            VStack {
                Image(systemName: "moon.stars")
                    .font(.system(size: 220))
                    .foregroundColor(.white.opacity(0.04))
                    .offset(x: 70, y: 30)
                Spacer()
            }
            .ignoresSafeArea()
            
            VStack(spacing: 28) {
                Spacer()
                
                // الشعار
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [Color(hex: "#1B8B6A"), Color(hex: "#0F5D4A")], startPoint: .top, endPoint: .bottom))
                        .frame(width: 110, height: 110)
                        .shadow(color: Color(hex: "#1B8B6A").opacity(0.4), radius: 20, x: 0, y: 10)
                    Text("🕌")
                        .font(.system(size: 52))
                }
                .scaleEffect(progress > 0 ? 1 : 0.8)
                .animation(.spring(response: 0.8, dampingFraction: 0.7), value: progress)
                
                VStack(spacing: 8) {
                    Text("صلاتي")
                        .font(.system(size: 38, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                    Text("مواقيت الصلاة في مكة المكرمة")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.caption2)
                            .foregroundColor(Color(hex: "#2EC4A0"))
                        Text("مكة المكرمة • أم القرى")
                            .font(.caption)
                            .foregroundColor(Color(hex: "#2EC4A0"))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Capsule())
                }
                
                Spacer()
                
                // منطقة التحميل
                VStack(spacing: 14) {
                    // شريط تقدم
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.15))
                                .frame(height: 5)
                            Capsule()
                                .fill(LinearGradient(colors: [Color(hex: "#1B8B6A"), Color(hex: "#2EC4A0")], startPoint: .leading, endPoint: .trailing))
                                .frame(width: geo.size.width * progress, height: 5)
                                .animation(.linear(duration: 0.15), value: progress)
                        }
                    }
                    .frame(height: 5)
                    .padding(.horizontal, 40)
                    
                    HStack(spacing: 8) {
                        ProgressView()
                            .tint(Color(hex: "#2EC4A0"))
                            .scaleEffect(0.9)
                        Text("جاري تحميل مواقيت مكة\(dots)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .animation(.easeInOut, value: dots)
                    }
                    
                    Text("﷽")
                        .font(.title3)
                        .foregroundColor(Color(hex: "#E8B44D").opacity(0.8))
                        .padding(.top, 4)
                    Text("«إن الصلاة كانت على المؤمنين كتاباً موقوتاً»")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                }
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 20)
        }
        .onAppear {
            startLoading()
        }
    }
    
    private func startLoading() {
        // تقدم سلس على مدى 4 ثواني
        withAnimation(.linear(duration: 4)) {
            progress = 1
        }
        // نقاط متحركة
        Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { t in
            if dots.count >= 3 {
                dots = ""
            } else {
                dots += "."
            }
            if progress >= 1 {
                t.invalidate()
            }
        }
    }
}

#Preview {
    SplashView()
}
