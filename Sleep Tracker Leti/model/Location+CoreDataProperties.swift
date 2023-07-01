
import Foundation
import CoreData


extension Location {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Location> {
        return NSFetchRequest<Location>(entityName: "Location")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var longitude: Double
    @NSManaged public var latitude: Double
    @NSManaged public var time: Date?
    @NSManaged public var score: Int16

}

extension Location : Identifiable {

}
