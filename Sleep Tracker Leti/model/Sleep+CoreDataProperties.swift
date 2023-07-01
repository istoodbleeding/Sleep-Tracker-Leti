
import Foundation
import CoreData


extension Sleep {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Sleep> {
        return NSFetchRequest<Sleep>(entityName: "Sleep")
    }

    @NSManaged public var edited: Bool
    @NSManaged public var id: UUID?
    @NSManaged public var sleepToSleepIntervals: NSSet?
    
    public var sleepArray: [SleepInterval] {
        let set = sleepToSleepIntervals as? Set<SleepInterval> ?? []
        return set.sorted {
            ($0.begin ?? Date()) < ($1.begin ?? Date())
        }
    }

}

// MARK: Generated accessors for sleepToSleepIntervals
extension Sleep {

    @objc(addSleepToSleepIntervalsObject:)
    @NSManaged public func addToSleepToSleepIntervals(_ value: SleepInterval)

    @objc(removeSleepToSleepIntervalsObject:)
    @NSManaged public func removeFromSleepToSleepIntervals(_ value: SleepInterval)

    @objc(addSleepToSleepIntervals:)
    @NSManaged public func addToSleepToSleepIntervals(_ values: NSSet)

    @objc(removeSleepToSleepIntervals:)
    @NSManaged public func removeFromSleepToSleepIntervals(_ values: NSSet)

}

extension Sleep : Identifiable {

}
