

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()
    let container: NSPersistentContainer
    
    var viewContext: NSManagedObjectContext {
        container.viewContext
    }
    static var preview: PersistenceController = {
            let result = PersistenceController(inMemory: true)
            let viewContext = result.container.viewContext
            // Заполнить контекст данными для предпросмотра здесь
            return result
        }()

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Sleep_Tracker_Leti")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
}

extension NSManagedObjectContext {
    func saveContext(){
        if self.hasChanges {
            do{
                try self.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}
