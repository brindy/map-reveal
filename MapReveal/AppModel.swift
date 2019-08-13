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

    func add(gmImage: NSImage, playerImage: NSImage, named: String, completion: @escaping (Error?) -> Void) {

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
                try context.save()
                self.fetch()
            } catch {
                lastError = error
            }

            DispatchQueue.main.async {
                completion(lastError)
            }
        }

    }

    func save() {
        persistence.viewContext.deletedObjects.forEach {
            ($0 as? UserMap)?.deleteFiles()
        }
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
