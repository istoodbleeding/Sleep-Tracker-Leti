
import NotificationCenter
import Combine
import SwiftUI
import CoreData
import CoreLocation

struct SleepAppView: View {
    @Environment(\.managedObjectContext) var viewContext
    @ObservedObject private var viewModel = SleepAppViewModel()
    @State private var selectedTab: Tab = .first
    
    
    enum Tab {
        case first
        case second
        case third
    }
    
    var body: some View {
        ZStack {
            TabView(selection: $selectedTab){
                TrackingView(isSleepStatus: $viewModel.isSleepStatus, isScreenLocked: $viewModel.isScreenLocked, lastScreenLockedTime: $viewModel.lastScreenLockedTime,
                             lastScreenUnlockedTime: $viewModel.lastScreenUnlockedTime)
                .preferredColorScheme(.dark)
                .tabItem {
                    Image(systemName: "bed.double.fill")
                    Text("Sleep")
                    
                }
                .tag(Tab.first)
                
                StatsView()
                    .preferredColorScheme(.dark)
                    .tabItem {
                        Image(systemName: "chart.bar.fill")
                        Text("Stats")
                        
                    }
                    .tag(Tab.second)
              /*  TestView(viewModel: viewModel)
                    .preferredColorScheme(.dark)
                    .tabItem {
                        Image(systemName: "circle.fill")
                        Text("Test")
                        
                    }
                    .tag(Tab.second)*/
                
            }.accentColor(.white)
                .onAppear {
                    viewModel.subscribeToScreenLockNotifications()
                }
                .onDisappear {
                    viewModel.unsubscribeFromScreenLockNotifications()
                }
            ForEach(viewModel.notEditedSleeps){ sleep in
                if sleep.edited == false {
                    SleepEditorView(sleep: sleep, appViewModel: viewModel)
                }
            }
            
            
            
        }
        
    }
}

