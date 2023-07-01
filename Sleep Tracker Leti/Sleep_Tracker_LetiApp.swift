
import SwiftUI

@main
struct Sleep_Tracker_LetiApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
                    SleepAppView()
                        .preferredColorScheme(.dark)
                        .environment(\.managedObjectContext, persistenceController.container.viewContext)
            }
        }
}
