
import Foundation
import CoreData


extension SleepInterval {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SleepInterval> {
        return NSFetchRequest<SleepInterval>(entityName: "SleepInterval")
    }

    @NSManaged public var begin: Date?
    @NSManaged public var end: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var sleepIntervalToSleep: Sleep?

    public var wrappedBegin: Date {
        begin ?? Date()
        
    }
    public var wrappedEnd: Date {
        end ?? Date()
        
    }
}

extension SleepInterval : Identifiable {

}
