//
//  ScreenshotManager.swift
//  Kabin
//
//  Created by Forest Hughes on 7/17/23.

import AppKit
import Foundation
import UniformTypeIdentifiers

class ScreenshotManager: ObservableObject {
    private(set) var directory: URL!

    init(directory: URL) {
        self.directory = directory
    }

    func takeScreenshot(filenamePostfix: String) {
        let screenshot = CGWindowListCreateImage(CGRect.null, .optionOnScreenOnly, kCGNullWindowID, .boundsIgnoreFraming)

        if let screenshot = screenshot {
            let nsImage = NSImage(cgImage: screenshot, size: NSSize.zero)
            if let tiffData = nsImage.tiffRepresentation, let bitmapImage = NSBitmapImageRep(data: tiffData) {
                let timestamp = Date().timeIntervalSince1970
                let url = directory?.appendingPathComponent("\(timestamp)_\(filenamePostfix).png")
                try? bitmapImage.representation(using: .png, properties: [:])?.write(to: url!)
            }
        }
    }

    func changeDirectory(_ newDirectory: URL) {
        directory = newDirectory
    }
}
