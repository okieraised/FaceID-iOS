//
//  Persistence.swift
//  FaceID-iOS
//
//  Created by Tri Pham on 6/13/23.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "FaceID_iOS")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            
            if let error = error as NSError? {
                print("Unresolved error \(error.localizedDescription)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    /// For main queue use only, simple rule is don't access it from any queue other than main!!!
    static var viewContext: NSManagedObjectContext {
        return shared.container.viewContext
    }

    /// Context for use in background.
    static var backgroundContext: NSManagedObjectContext {
        return shared.container.newBackgroundContext()
    }
    
    
    func saveChanges() {
        let context = container.viewContext

        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Could not save changes to Core Data.", error.localizedDescription)
            }
        }
    }

    
    func saveFaceVector(vector: [Float32]) {
        let entity = FaceVector(context: container.viewContext)
        entity.id = 0
        entity.vector = vector
        entity.created = Date()
        entity.update = Date()
        saveChanges()
    }
    
    func getFaceVector() -> [FaceVector] {
        var results: [FaceVector] = []
        let request = NSFetchRequest<FaceVector>(entityName: "FaceVector")
        request.fetchLimit = 1
        
        do {
            results = try container.viewContext.fetch(request)
        } catch {
            print("Could not fetch notes from Core Data: \(error.localizedDescription)")
        }

        return results
    }
    
    func deleteFaceVector(_ entity: FaceVector) {
        container.viewContext.delete(entity)
    }
    
    func updateFaceVector(entity: FaceVector, vector: [Float32]? = nil) {
        var hasChanges: Bool = false
        
        if vector != nil {
            entity.vector = vector
            entity.update = Date()
            hasChanges = true
        }
        
        if hasChanges {
            saveChanges()
        }
    }
}
