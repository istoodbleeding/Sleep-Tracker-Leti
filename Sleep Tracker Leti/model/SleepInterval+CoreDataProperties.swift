
import Foundation
import CoreData


extension SleepInterval {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SleepInterval> {
        return NSFetchRequest<SleepInterval>(entityName: "SleepInterval")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var begin: Date?
    @NSManaged public var end: Date?
    @NSManaged public var sleepIntervalToSleep: Sleep?

}

extension SleepInterval : Identifiable {

}
