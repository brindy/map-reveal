//
//  ZeroConfigMapRendering.swift
//  MapReveal
//
//  Created by Christopher Brind on 01/02/2020.
//  Copyright © 2020 Chris Brind. All rights reserved.
//

import Foundation

class ZeroConfigMapRendering: NSObject, MapRendering {

    var delegate: MapRendereringDelegate?

    var imageUrl: URL?

    let service = NetService(domain: "",
                             type: "_mapreveal._tcp.",
                             name: "",
                             port: 0)

    override init() {
        super.init()
        service.delegate = self
        service.publish(options: .listenForConnections)
    }

    func load(imageUrl: URL, revealedUrl: URL) {
    }

    func zoomToFit() {
    }

    func clear() {
    }

    func addMarker(_ marker: UserMarker) {
    }

    func showSelectedMarker(_ marker: UserMarker) {
    }

    func removeMarker(_ marker: UserMarker) {
    }

    func updateRevealed() {
    }

}

extension ZeroConfigMapRendering: NetServiceDelegate {

    func netServiceWillPublish(_ sender: NetService) {
        print(#function)
    }

    func netServiceDidPublish(_ sender: NetService) {
        print(#function, sender)
    }

    func netService(_ sender: NetService, didNotPublish errorDict: [String : NSNumber]) {
        print(#function, errorDict)
    }

    func netServiceDidStop(_ sender: NetService) {
        print(#function)
    }

    func netServiceWillResolve(_ sender: NetService) {
        print(#function)
    }

    func netServiceDidResolveAddress(_ sender: NetService) {
        print(#function)
    }

    func netService(_ sender: NetService, didUpdateTXTRecord data: Data) {
        print(#function)
    }

    func netService(_ sender: NetService, didNotResolve errorDict: [String : NSNumber]) {
        print(#function, errorDict)
    }

    func netService(_ sender: NetService, didAcceptConnectionWith inputStream: InputStream, outputStream: OutputStream) {
        print(#function)
    }

}
