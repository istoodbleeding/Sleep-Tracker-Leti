
import SwiftUI
import CoreGraphics
import AVFoundation
import BackgroundTasks
import CoreLocation
import MapKit
import CoreData

struct TrackingView: View {
    @StateObject  var tvm = TrackingViewModel()
    @Binding var isSleepStatus: Bool
    @Binding var isScreenLocked: Bool
    @Binding var lastScreenLockedTime: Date?
    @Binding var lastScreenUnlockedTime: Date?
    @State var positionX = UIScreen.main.bounds.width/2 + 35
    @State private var isViewVisible = false
    @State var badgeManager = AppAlertBadgeManager(application: UIApplication.shared)
    
    
    var body: some View {
        ZStack {
            BackgroundView()
            if isViewVisible{
                Color.black.opacity(0.5)
                    .edgesIgnoringSafeArea(.all)
            }
            
            if isSleepStatus {
                VStack(alignment: .center, spacing: 40) {
                    Text("\(tvm.dayString(date: tvm.date))")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.dirtyWhite)
                        .font(.montserrat(24))
                        .padding(.bottom, 1)
                    
                    SoundAnimationView(soundLevel: $tvm.soundLevel)
                    
                    ZStack {
                        timeCircle(date: $tvm.date, isSleepStatus: $isSleepStatus)
                        VStack {
                            Cloud()
                                .foregroundColor(.dirtyWhite)
                                .opacity(30)
                                .frame(width: 50, height: 25)
                                .offset(x: CGFloat(positionX))
                                .animation(Animation.easeInOut(duration: 1).repeatForever(autoreverses: false).speed(0.02))
                                .onAppear() {
                                    positionX -= UIScreen.main.bounds.width + 70
                                }
                            Spacer().frame(height: 150)
                            Cloud()
                                .foregroundColor(.dirtyWhite)
                                .opacity(30)
                                .frame(width: 100, height: 50)
                                .offset(x: CGFloat(positionX))
                                .animation(Animation.easeInOut(duration: 1).repeatForever(autoreverses: false).speed(0.03))
                                .onAppear() {
                                    positionX -= UIScreen.main.bounds.width + 70
                                }
                        }
                        
                    }
                    Spacer().frame(height: 0)
                    
                    VStack {
                        
                        Text("Tracking duration")
                            .foregroundColor(Color.dirtyWhite)
                            .font(.system(size: 15, weight: .bold))
                        
                        RoundedRectangle(cornerRadius: 20)
                            .foregroundColor(.lightButton)
                            .frame(width: 150, height: 40)
                            .overlay(
                                Text(tvm.trackingDuration)
                                    .foregroundColor(Color.dirtyWhite)
                                
                            )
                        
                        Spacer().frame(height: 25)
                        
                        Button(action: {
                                tvm.stopTracking()
                                tvm.stopRecording()
                            print("\($tvm.isTracking)")
                            self.isSleepStatus.toggle()
                        }, label: {
                            RoundedRectangle(cornerRadius: 22)
                                .foregroundColor(.dirtyWhite)
                                .frame(width: 260, height: 60)
                                .overlay(
                                    Text("Stop tracking")
                                        .foregroundColor(.tabPurple)
                                        .font(.system(size: 18, weight: .bold))
                                        .font(.montserrat(18))
                                )
                        }).disabled(isViewVisible)
                            .foregroundColor(isViewVisible ? .gray : .tabPurple)
                        
                    }
                }
                
            } else {
                VStack(alignment: .center, spacing: 40) {
                    Text("\(tvm.dayString(date: tvm.date))")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.dirtyWhite)
                        .font(.montserrat(24))
                        .padding(.bottom, 1)
                    Text("  ")
                    ZStack {
                        timeCircle(date: $tvm.date, isSleepStatus: $isSleepStatus)
                        VStack {
                            Cloud()
                                .foregroundColor(.dirtyWhite)
                                .opacity(30)
                                .frame(width: 50, height: 25)
                                .offset(x: CGFloat(positionX))
                                .animation(Animation.easeInOut(duration: 1).repeatForever(autoreverses: false).speed(0.02))
                                .onAppear() {
                                    positionX -= UIScreen.main.bounds.width + 70
                                }
                            Spacer().frame(height: 150)
                            Cloud()
                                .foregroundColor(.dirtyWhite)
                                .opacity(30)
                                .frame(width: 100, height: 50)
                                .offset(x: CGFloat(positionX))
                                .animation(Animation.easeInOut(duration: 1).repeatForever(autoreverses: false).speed(0.03))
                                .onAppear() {
                                    positionX -= UIScreen.main.bounds.width + 70
                                }
                        }
                        
                    }
                    Spacer().frame(height: 0)
                    
                    VStack {
                        Text("Tracking duration")
                            .foregroundColor(isViewVisible ? Color.white.opacity(0.5)  : .white)
                            .font(.system(size: 15, weight: .bold))
                            .font(.montserrat(15))
                        
                        RoundedRectangle(cornerRadius: 20)
                            .foregroundColor(isViewVisible ? Color.lightButton.opacity(0.5)  : .lightButton)
                            .frame(width: 150, height: 40)
                            .overlay(
                                Text(tvm.trackingDuration)
                                    .foregroundColor(isViewVisible ? Color.white.opacity(0.5)  : .white)
                                
                            )
                        
                        Spacer().frame(height: 25)
                        
                        Button(action: {
                            self.isSleepStatus.toggle()
                                tvm.startRecording()
                                tvm.startTracking()
                                tvm.toogleTracking()
                            print("\($tvm.isTracking)")
                            
                            
                        }, label: {
                            RoundedRectangle(cornerRadius: 22)
                                .foregroundColor(isViewVisible ? Color.dirtyWhite.opacity(0.5)  : .dirtyWhite)
                                .frame(width: 260, height: 60)
                                .overlay(
                                    Text("Start tracking")
                                        .foregroundColor(isViewVisible ? Color.tabPurple.opacity(0.5) : .tabPurple)
                                        .font(.system(size: 18, weight: .bold))
                                        .font(.montserrat(18))
                                )
                        })
                        .disabled(isViewVisible)
                        
                    }
                    
                }
                
                
            }
        }
        
    }
    
    
}


