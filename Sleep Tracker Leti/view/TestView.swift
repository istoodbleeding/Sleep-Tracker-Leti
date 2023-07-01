import SwiftUI
import CoreData
struct TestView: View {
    var viewModel: SleepAppViewModel
    @State var badgeManager = AppAlertBadgeManager(application: UIApplication.shared)
    @State var sleepArray: [Sleep] = []
    var count = 0
    init (viewModel: SleepAppViewModel){
        self.viewModel = viewModel
        
        
    }
    var body: some View {
        VStack {
            Button("get sleeps") {
                setAllSleepsEditedValueToFalse()
            }
        .buttonStyle(.borderedProminent)
        .tint(.black)
        
            ForEach(Array(sleepArray.enumerated()), id: \.element.id) { index, sleep in
                if index == 2 {
                   // SleepEditorView(sleep: sleep)
                }
            }
            Button("Set Badge Number") {
                badgeManager.setAlertBadge(number: 1) // Adding the badge app icon
            }
            .buttonStyle(.borderedProminent)
            .tint(.black)
            
            Button("Reset Badge Number") {
                badgeManager.resetAlertBadgetNumber() // removing badge app icon
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            
            //            SleepEditView(sleep: viewModel.fetchSleepsWithEditStatusFalse().first!)
            
            /*Button("test data processing") {
                
                viewModel.twoHoursAgoUpdate()
                let sleepFetchRequest: NSFetchRequest<NSFetchRequestResult> = Sleep.fetchRequest()
                let sleepDeleteRequest = NSBatchDeleteRequest(fetchRequest: sleepFetchRequest)
                
                let sleepIntervalFetchRequest: NSFetchRequest<NSFetchRequestResult> = SleepInterval.fetchRequest()
                let sleepIntervalDeleteRequest = NSBatchDeleteRequest(fetchRequest: sleepIntervalFetchRequest)
                do {
                    try viewModel.viewContext.execute(sleepDeleteRequest)
                    try viewModel.viewContext.execute(sleepIntervalDeleteRequest)
                    try viewModel.viewContext.saveContext()
                } catch {
                    print("Error deleting objects: \(error)")
                }
                
                var tempArray: [TempSleepInterval]
                var tempSoundArray: [TempSleepInterval]
                do{  let temple = try viewModel.fetchLocations(in: viewModel.viewContext , from: viewModel.twoHoursAgo, to: viewModel.currentDate)
                    tempArray = viewModel.processLocations(locations: temple)
                    try tempSoundArray = viewModel.evaluateNoise(for: tempArray, in: viewModel.viewContext)
                    if tempSoundArray.isEmpty == false {
                        let sleep = Sleep(context: viewModel.viewContext)
                        sleep.id = UUID()
                        sleep.edited = false
                        for item in tempSoundArray {
                            print("\(item.begin)--\(item.end)")
                            
                            if viewModel.currentDate.timeIntervalSince(item.begin!) < 24 * 60 * 60 {
                                let sleepInterval = SleepInterval(context: viewModel.viewContext)
                                sleepInterval.id = UUID()
                                sleepInterval.begin = item.begin
                                sleepInterval.end = item.end
                                sleepInterval.sleepIntervalToSleep = sleep
                                sleep.addToSleepToSleepIntervals(sleepInterval)
                            }
                            
                        }
                        viewModel.viewContext.saveContext()
                    } else {
                        print("no sleeps")
                        
                    }
                    
                } catch {
                    print("Zalupa")
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
             */
            
        }
       
        
    }
    func setAllSleepsEditedValueToFalse() {
        let fetchRequest: NSFetchRequest<Sleep> = Sleep.fetchRequest()
        fetchRequest.predicate = NSPredicate(value: true) // Retrieve all Sleep objects
        
        do {
            let sleeps = try viewModel.viewContext.fetch(fetchRequest)
            for sleep in sleeps {
                sleep.edited = false
            }
            
            try viewModel.viewContext.save() // Save the changes
        } catch {
            print("Error setting edited value to false: \(error.localizedDescription)")
        }
    }
    func fetchSleeps(in context: NSManagedObjectContext) throws -> [Sleep] {
        let fetchRequest: NSFetchRequest<Sleep> = Sleep.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "edited == false")
        
        return try context.fetch(fetchRequest)
    }

}
