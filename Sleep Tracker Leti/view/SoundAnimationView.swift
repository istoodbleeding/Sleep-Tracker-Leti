import SwiftUI

struct SoundAnimationView: View {
 
    @State private var drawingHeight = true
    @Binding var soundLevel: Int
    var animation: Animation {
        return .linear(duration: 0.5).repeatForever()
    }
 
    var body: some View {
        VStack(alignment: .leading) {
            HStack{
                HStack {
                    bar(low: 0.2)
                        .animation(animation.speed(1.5), value: drawingHeight)
                    bar(low: 0.1)
                        .animation(animation.speed(1.2), value: drawingHeight)
                    bar(low: 0.3)
                        .animation(animation.speed(1.0), value: drawingHeight)
                    bar(low: 0.2)
                        .animation(animation.speed(1.7), value: drawingHeight)
                    bar(low: 0.3)
                        .animation(animation.speed(1.0), value: drawingHeight)
                }
                .frame(width: 60)
                .onAppear{
                    drawingHeight.toggle()
                }
                
                Text("\(String(soundLevel)) Дб").frame(height: 64, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                    
            }
        }.frame(width: UIScreen.main.bounds.width - 200, height: 20, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
    }
 
    func bar(low: CGFloat = 0.0, high: CGFloat = 0.5) -> some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(.white.gradient)
            .frame(height: (drawingHeight ? high : low) * 64)
            .frame(height: 64, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
    }
}
