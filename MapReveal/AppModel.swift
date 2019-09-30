/*
AppModel.swift

Copyright 2019 Chris Brind

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

import AppKit
import CoreData

class AppModel {

    static let shared = AppModel()

    private var persistence = NSPersistentContainer(name: "MapsModel")
    
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

    var userMaps: [UserMap] = []
    var userMarkers: [UserMarker] = []
    
    init() {
        let semaphore = DispatchSemaphore(value: 1)
        persistence.loadPersistentStores { _, error in
            self.fetchMaps()
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
        fetchMaps()
    }

    func add(markerImage image: NSImage, named name: String, toRow row: Int? = nil, completion: @escaping (String?, Error?) -> Void) {

        DispatchQueue.global(qos: .utility).async {

            let uid = UUID().uuidString
            var lastError: Error? = nil
            do {
                let context = self.persistence.newBackgroundContext()
                defer {
                    context.rollback()
                    self.fetchMarkers()
                }

                let entity = UserMarker(context: context)
                entity.displayName = name
                entity.uid = uid

                guard let imageUrl = entity.imageUrl else { return }
                try image.write(to: imageUrl)

                var markers = self.fetchMarkers(context: context)
                markers.insert(entity, at: (row ?? self.userMarkers.count) + 1)
                self.applyOrder(markers)

                try context.save()
            } catch {
                lastError = error
            }

            DispatchQueue.main.async {
                completion(lastError == nil ? uid : nil, lastError)
            }
        }

    }

    func add(gmImage: NSImage, playerImage: NSImage, named: String, toRow row: Int? = nil, completion: @escaping (String?, Error?) -> Void) {

        DispatchQueue.global(qos: .utility).async {
            let uid = UUID().uuidString

            var lastError: Error? = nil
            do {
                let context = self.persistence.newBackgroundContext()
                defer {
                    context.rollback()
                    self.fetchMaps()
                }

                let entity = UserMap(context: context)
                entity.displayName = named
                entity.uid = uid

                guard let gmImageUrl = entity.gmImageUrl else { return }
                guard let playerImageUrl = entity.playerImageUrl else { return }

                try gmImage.write(to: gmImageUrl)
                try playerImage.write(to: playerImageUrl)

                var maps = self.fetchMaps(context: context)
                maps.insert(entity, at: (row ?? self.userMaps.count) + 1)
                self.applyOrder(maps)

                try context.save()
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
            ($0 as? UserMarker)?.deleteFiles()
        }
        try? persistence.viewContext.save()
        fetchMaps()
        fetchMarkers()
    }

    func delete(_ userMap: UserMap) {
        persistence.viewContext.delete(userMap)
    }

    func delete(_ marker: UserMarker) {
        persistence.viewContext.delete(marker)
    }

    private func fetchMaps() {
        userMaps = fetchMaps(context: self.persistence.viewContext)
    }

    private func fetchMarkers() {
        userMarkers = fetchMarkers(context: self.persistence.viewContext)
    }

    private func applyOrder(_ maps: [UserMap]) {
        for i in 0 ..< maps.count {
            maps[i].order = Int64(i)
        }
    }

    private func applyOrder(_ markers: [UserMarker]) {
        for i in 0 ..< markers.count {
            markers[i].order = Int64(i)
        }
    }

    private func fetchMaps(context: NSManagedObjectContext) -> [UserMap] {
        let request: NSFetchRequest<UserMap> = UserMap.fetchRequest()
        request.sortDescriptors = [ .init(key: "order", ascending: true) ]
        return (try? context.fetch(request)) ?? []
    }

    private func fetchMarkers(context: NSManagedObjectContext) -> [UserMarker] {
        let request: NSFetchRequest<UserMarker> = UserMarker.fetchRequest()
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

extension UserMarker {

    var imageUrl: URL? {
        guard let uid = uid else { return nil }
        return AppModel.shared.appUrl.appendingPathComponent(uid).appendingPathExtension("marker")
    }

    func deleteFiles() {
        guard let imageUrl = imageUrl else { return }
        let fm = FileManager.default
        try? fm.removeItem(at: imageUrl)
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
