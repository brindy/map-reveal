//
//  MapRendering.swift
//  MapReveal
//
//  Created by Christopher Brind on 29/11/2019.
//  Copyright © 2019 Chris Brind. All rights reserved.
//

import Foundation

protocol MapRendereringDelegate: NSObjectProtocol {

    func toolFinished(_ renderer: MapRendering)
    func markerSelected(_ renderer: MapRendering, marker: UserMarker)
    func markerModified(_ renderer: MapRendering, marker: UserMarker)

}


protocol MapRendering {

    var delegate: MapRendereringDelegate? { get set }
    var imageUrl: URL? { get }

    func load(imageUrl: URL, revealedUrl: URL)
    func zoomToFit()
    func clear()

    func addMarker(_ marker: UserMarker)
    func showSelectedMarker(_ marker: UserMarker)
    func removeMarker(_ marker: UserMarker)

    // FIX:
    func update(from: FogOfWarImageView)
}
