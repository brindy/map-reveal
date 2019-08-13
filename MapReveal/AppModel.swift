//
//  AppModel.swift
//  MapReveal
//
//  Created by Chris Brind on 12/08/2019.
//  Copyright © 2019 Chris Brind. All rights reserved.
//

import AppKit
import CoreData

class AppModel {
    
    static let shared = AppModel()

    private var persistence = NSPersistentContainer(name: "Maps")
    
    fileprivate var appUrl: URL {
        let fm = FileManager.default
        guard let appFolder = fm.urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError("Unable to find application support directory")
        }

        var isDirectory: ObjCBool = false
        let folderExists = fm.fileExists(atPath: appFolder.path, isDirectory: &isDirectory)
        if !folderExists {
            try? fm.createDirectory(at: appFolder, withIntermediateDirectories: true, attributes: nil)
        } else if !isDirectory.boolValue {
            fatalError("app folder is not a directory")
        }
        
        return appFolder
    }

    lazy var userMaps: [UserMap] = []
    
    init() {
        let semaphore = DispatchSemaphore(value: 1)
        persistence.loadPersistentStores { _, error in
            self.fetch()
            semaphore.signal()
            guard let error = error else { return }
            fatalError(error.localizedDescription)
        }
        semaphore.wait()
    }
    
    func addImage(from url: URL, completion: @escaping (Error?) -> Void) {
        DispatchQueue.global(qos: .utility).async {
            var addError: Error?
            do {
                try self.addImage(at: url)
                self.fetch()
            } catch {
                addError = error
            }
            DispatchQueue.main.async {
                completion(addError)
            }
        }
    }

    func save() {
        try? persistence.viewContext.save()
        fetch()
    }

    func fetch() {
        let request: NSFetchRequest<UserMap> = UserMap.fetchRequest()
        userMaps = (try? self.persistence.viewContext.fetch(request)) ?? []
    }

    func delete(_ userMap: UserMap) {
        persistence.viewContext.delete(userMap)        
    }
    
    private func addImage(at url: URL) throws {
        let uid = UUID().uuidString
        let destination = appUrl.appendingPathComponent(uid).appendingPathExtension("bin")
        print(#function, url, "copying to", destination)

        let context = self.persistence.newBackgroundContext()
        let entity = UserMap(context: context)
        entity.displayName = url.lastPathComponent
        entity.uid = uid
        try FileManager.default.copyItem(at: url, to: destination)
        try context.save()
    }
    
}

extension UserMap {

    var imageUrl: URL? {
        guard let uid = uid else { return nil }
        return AppModel.shared.appUrl.appendingPathComponent(uid).appendingPathExtension("bin")
    }

    var revealedUrl: URL? {
        guard let uid = uid else { return nil }
        return AppModel.shared.appUrl.appendingPathComponent(uid).appendingPathExtension("revealed")
    }

}
