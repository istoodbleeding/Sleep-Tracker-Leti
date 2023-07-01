

import Foundation
import CoreData


extension Sound {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Sound> {
        return NSFetchRequest<Sound>(entityName: "Sound")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var noise: Int16
    @NSManaged public var time: Date?

}

extension Sound : Identifiable {

}
