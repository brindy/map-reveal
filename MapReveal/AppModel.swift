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
    
    private var appUrl: URL {
        let fm = FileManager.default
        guard let folder = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            fatalError("Unable to find application support directory")
        }
        guard let bundleId = Bundle.main.bundleIdentifier else {
            fatalError("Unable to find bundle id")
        }
        let appFolder = folder.appendingPathComponent(bundleId)
        var isDirectory: ObjCBool = false
        let folderExists = fm.fileExists(atPath: appFolder.path, isDirectory: &isDirectory)
        if !folderExists {
            try? fm.createDirectory(at: appFolder, withIntermediateDirectories: true, attributes: nil)
        }
        
        if !isDirectory.boolValue {
            fatalError("app folder is not a directory")
        }
        
        return appFolder
    }
    
    init() {
        persistence.loadPersistentStores { _, error in
            fatalError("Error loading persistence store \(error?.localizedDescription ?? "unknown error")")
        }
    }
    
    func addImage(from url: URL, completion: @escaping (URL?, Error?) -> Void) {
        DispatchQueue.global(qos: .utility).async {
            var result: URL?
            var addError: Error?
            do {
                result = try self.addImage(at: url)
            } catch {
                addError = error
            }
            DispatchQueue.main.async {
                completion(result, addError)
            }
        }
    }
    
    private func addImage(at: URL) throws -> URL {
        let uid = UUID().uuidString
        let destination = appUrl.appendingPathComponent(uid).appendingPathExtension("bin")
        try FileManager.default.copyItem(at: at, to: destination)
        let context = self.persistence.newBackgroundContext()
        let entity = UserMap(context: context)
        entity.displayName = at.lastPathComponent
        entity.uid = uid
        try context.save()
        return destination
    }
    
}
