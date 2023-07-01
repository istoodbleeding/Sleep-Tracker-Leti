import SwiftUI
import CoreData


class SleepEditorViewModel: ObservableObject {
    @Published var biggestEndDate = Date(timeIntervalSince1970: 0)
    @Published var smallestBeginDate = Date()
    @Published var sleepInterval: SleepIntervalTemp
    let viewContext = PersistenceController.shared.viewContext
    var sleep: Sleep
    @Published var isAddVisible = false
    @Published var isViewVisible = true
    let dateFormatter = DateFormatter()
    
    @Published var sleepIntervalsTemp: [SleepIntervalTemp] = []
    
    init(sleep: Sleep ){
        self.sleep = sleep
        sleepInterval = SleepIntervalTemp(id: UUID(), begin: (sleep.sleepArray.first?.begin) ?? Date(), end:  (sleep.sleepArray.first?.end) ?? Date())

        loadSleepIntervalsTemp()
        dateFormatter.dateFormat = "dd/MM/yy 'at' h:mm:ss a"
        findBiggestEndDate()
        findSmallestBeginDate()
    }
    func setSleepInterval(){
        sleepInterval = SleepIntervalTemp(id: UUID(), begin: sleepIntervalsTemp.first!.begin, end:  sleepIntervalsTemp.last!.end)
    }
    
    func loadSleepIntervalsTemp() {
    
            for interval in sleep.sleepArray {
                sleepIntervalsTemp.append(convertToTemp(sleepInterval: interval))
            }
    }
    func saveSleep ( sleep: Sleep) {
        if let intervals = sleep.sleepToSleepIntervals as? Set<SleepInterval> {
            for interval in intervals {
                viewContext.delete(interval)
            }
        }
        sleep.sleepToSleepIntervals = nil
        for item in sleepIntervalsTemp {
             let sleepInterval = SleepInterval(context: viewContext)
             sleepInterval.id = UUID()
             sleepInterval.begin = item.begin
             sleepInterval.end = item.end
             sleepInterval.sleepIntervalToSleep = sleep
            sleep.addToSleepToSleepIntervals(sleepInterval)
         }
            sleep.edited = true
         viewContext.saveContext()
     }
    func deleteSleep( sleep: Sleep?) {
        if let sleep = sleep {
            // Delete the associated SleepInterval objects
            if let intervals = sleep.sleepToSleepIntervals as? Set<SleepInterval> {
                viewContext.delete(sleep)
                for interval in intervals {
                    viewContext.delete(interval)
                }
            }
            
            
            
            // Save the changes
            do {
                try viewContext.saveContext()
            } catch {
                print("Error deleting sleep: \(error.localizedDescription)")
            }
        }
    }
    
    func convertToTemp(sleepInterval: SleepInterval) -> SleepIntervalTemp {
        return SleepIntervalTemp(id: sleepInterval.id!, begin: sleepInterval.begin!, end: sleepInterval.end!)
    }
    
    func findBiggestEndDate() {
        
        let request: NSFetchRequest<Sleep> = Sleep.fetchRequest()
        print("\(self.sleep.id) \(sleep.id)")
        request.predicate = NSPredicate(format: "id != %@", self.sleep.id! as CVarArg)
        
        let date = self.sleep.sleepArray.first?.begin
        print("\(sleep)")
        for item in sleep.sleepArray
        {
            print("\(item.begin)")
        }
        do {
            let sleeps = try viewContext.fetch(request)
            
            var biggestEndDateTemp: Date? = nil
            
            for sleep in sleeps {
                let sleepIntervals = sleep.sleepArray
                for sleepInterval in sleepIntervals {
                    if let end = sleepInterval.end, end < date! {
                        if biggestEndDateTemp == nil || end > biggestEndDateTemp! {
                            biggestEndDateTemp = end
                        }
                    }
                }
            }
            if biggestEndDateTemp != nil {
                self.biggestEndDate = biggestEndDateTemp!
            }
            
        } catch {
            print("Error fetching sleeps: \(error.localizedDescription)")
        }
    }
    

    
    func findSmallestBeginDate( ) {
        let request: NSFetchRequest<Sleep> = Sleep.fetchRequest()
            request.predicate = NSPredicate(format: "id != %@", sleep.id! as CVarArg)
        let date = sleep.sleepArray.last?.end
        
        do {
            let sleeps = try viewContext.fetch(request)
            
            var smallestBeginDateTemp: Date? = nil
            
            for sleep in sleeps {
                let sleepIntervals = sleep.sleepArray
                for sleepInterval in sleepIntervals {
                    if let begin = sleepInterval.begin, begin > date! {
                        if smallestBeginDateTemp == nil || begin < smallestBeginDateTemp! {
                            smallestBeginDateTemp = begin
                        }
                    }
                }
            }
            
            if smallestBeginDateTemp != nil {
                self.smallestBeginDate = smallestBeginDateTemp!
            }
        } catch {
            print("Error fetching sleeps: \(error.localizedDescription)")
            
        }
    }
    
    func checkOverlappingIntervals() {
        // Sort intervals by begin time in ascending order
        sleepIntervalsTemp.sort { $0.begin < $1.begin }

        var i = 0
        while i < sleepIntervalsTemp.count - 1 {
            // Check if the end of the current interval is greater than or equal to the begin of the next interval
            if sleepIntervalsTemp[i].end >= sleepIntervalsTemp[i + 1].begin {
                // If the end of the next interval is greater than the current interval's end, update the current interval's end
                if sleepIntervalsTemp[i].end < sleepIntervalsTemp[i + 1].end {
                    sleepIntervalsTemp[i + 1].begin = sleepIntervalsTemp[i ].end
                } else {
                    sleepIntervalsTemp.remove(at: i+1)
                }
            }
            i += 1
        }
    }

    
}
