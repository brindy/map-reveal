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
            self.fetchUserMaps()
            semaphore.signal()
            guard let error = error else { return }
            fatalError(error.localizedDescription)
        }
        semaphore.wait()
    }

    func moveMap(from: Int, to: Int) {
        var maps = self.userMaps
        let map = maps.remove(at: from)
        maps.insert(map, at: to)
        applyOrder(maps)
        save()
        fetchUserMaps()
    }

    func add(gmImage: NSImage, playerImage: NSImage, named: String, toRow row: Int? = nil, completion: @escaping (String?, Error?) -> Void) {

        DispatchQueue.global(qos: .utility).async {
            let uid = UUID().uuidString

            let gmImageUrl = AppModel.shared.appUrl.appendingPathComponent(uid).appendingPathExtension("gm")
            let playerImageUrl = AppModel.shared.appUrl.appendingPathComponent(uid).appendingPathExtension("player")
            var lastError: Error? = nil
            do {
                try gmImage.write(to: gmImageUrl)
                try playerImage.write(to: playerImageUrl)

                let context = self.persistence.newBackgroundContext()


                let entity = UserMap(context: context)
                entity.displayName = named
                entity.uid = uid

                var maps = self.fetch(context: context)
                maps.insert(entity, at: (row ?? self.userMaps.count) + 1)
                self.applyOrder(maps)

                try context.save()
                self.fetchUserMaps()
            } catch {
                lastError = error
            }

            DispatchQueue.main.async {
                completion(lastError == nil ? uid : nil, lastError)
            }
        }

    }

    func save() {
        persistence.viewContext.deletedObjects.forEach {
            ($0 as? UserMap)?.deleteFiles()
        }
        try? persistence.viewContext.save()
        fetchUserMaps()
    }

    func fetchUserMaps() {
        userMaps = fetch(context: self.persistence.viewContext)
    }

    func delete(_ userMap: UserMap) {
        persistence.viewContext.delete(userMap)        
    }

    private func applyOrder(_ maps: [UserMap]) {
        for i in 0 ..< maps.count {
            maps[i].order = Int64(i)
        }
    }

    private func fetch(context: NSManagedObjectContext) -> [UserMap] {
        let request: NSFetchRequest<UserMap> = UserMap.fetchRequest()
        request.sortDescriptors = [ .init(key: "order", ascending: true) ]
        return (try? context.fetch(request)) ?? []
    }

}

extension UserMap {

    var gmImageUrl: URL? {
        guard let uid = uid else { return nil }
        return AppModel.shared.appUrl.appendingPathComponent(uid).appendingPathExtension("gm")
    }

    var playerImageUrl: URL? {
        guard let uid = uid else { return nil }
        return AppModel.shared.appUrl.appendingPathComponent(uid).appendingPathExtension("player")
    }

    var revealedUrl: URL? {
        guard let uid = uid else { return nil }
        return AppModel.shared.appUrl.appendingPathComponent(uid).appendingPathExtension("revealed")
    }

    func deleteFiles() {
        guard let gmImageUrl = gmImageUrl, let playerImageUrl = playerImageUrl, let revealedUrl = revealedUrl else { return }
        let fm = FileManager.default
        try? fm.removeItem(at: gmImageUrl)
        try? fm.removeItem(at: playerImageUrl)
        try? fm.removeItem(at: revealedUrl)
    }

}

extension NSImage {

    func write(to url: URL) throws {
        guard let image = cgImage(forProposedRect: nil, context: nil, hints: nil) else { return }

        let rep = NSBitmapImageRep(cgImage: image)
        rep.size = NSSize(width: image.width, height: image.height)
        guard let imageData = rep.representation(using: .png, properties: [:]) else {
            print(#function, "failed to create representation of image")
            return
        }

        try imageData.write(to: url)
    }

}
