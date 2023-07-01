import SwiftUI
struct timeCircle: View {
    
    @State private var animateProgress = false
    @State private var animateHue = false
    @State private var animateSmallCircle = false
    @State private var animateLargeCircle = false
    @State private var animateTag = false
    @State private var animateSound = false
    @Binding var date: Date
    @Binding var isSleepStatus: Bool
    
    var body: some View {
        ZStack {
            
            ZStack {
                Circle()
                    .stroke()
                    .foregroundColor(Color.dirtyWhite)
                    .frame(width: UIScreen.main.bounds.width - 150, height: UIScreen.main.bounds.width - 150, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                    .scaleEffect(animateLargeCircle ? 1.1 : 1)
                    .opacity(animateLargeCircle ? 0 : 1)
                    .animation(Animation.easeOut(duration: 4).delay(1).repeatForever(autoreverses: false))
                    .onAppear() {
                        if isSleepStatus {
                            animateLargeCircle.toggle()
                        }
                    }
                
                Circle()
                    .stroke()
                    .foregroundColor(Color.dirtyWhite)
                    .frame(width: UIScreen.main.bounds.width - 150, height: UIScreen.main.bounds.width - 150, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                    .scaleEffect(animateSmallCircle ? 1.2 : 1)
                    .opacity(animateSmallCircle ? 0 : 1)
                    .animation(Animation.easeInOut(duration: 4).delay(1).repeatForever(autoreverses: false))
                    .onAppear() {
                        if isSleepStatus {
                            animateSmallCircle.toggle()
                        }
                    }
                
                Circle()
                    .stroke(lineWidth: 4)
                    .foregroundColor(Color.dirtyWhite)
                    .frame(width: UIScreen.main.bounds.width - 150, height: UIScreen.main.bounds.width - 150, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                
                
                
                
                // Time
                VStack {
                    Text("\(timeString(date: date))")
                        .foregroundColor(Color.dirtyWhite)
                        .font(.system(size: 48))
                    Label("Tracking", systemImage: "record.circle")
                        .opacity(isSleepStatus ? 1 : 0)
                }
            }
            
            
            
            
        }
    }  // Container for all views
    var timeFormat: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }
    func timeString(date: Date) -> String {
        let time = timeFormat.string(from: date)
        return time
    }
}
