//
//  KabinApp.swift
//  Kabin
//
//  Created by Forest Hughes on 7/17/23.

import CoreGraphics
import Foundation
import SwiftUI

func deleteFilesInFolder(atPath folderPath: URL) {
    let fileManager = FileManager.default

    do {
        let directoryContents = try fileManager.contentsOfDirectory(at: folderPath, includingPropertiesForKeys: nil)

        // Filter the directory contents for files with a ".png" extension
        let pngFiles = directoryContents.filter { $0.pathExtension == "png" }

        for png in pngFiles {
            try fileManager.removeItem(at: png)
        }

        print("All files in the folder have been deleted.")
    } catch {
        print("Error while deleting files: \(error.localizedDescription)")
    }
}

func processScreenshotFiles(from directory: URL) {
    let fileManager = FileManager.default

    do {
        // Get the directory contents urls (including subfolders urls)
        let directoryContents = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)

        // Filter the directory contents for files with a ".png" extension
        let pngFiles = directoryContents.filter { $0.pathExtension == "png" }

        for file in pngFiles {
            // Split filename into components
            let fileName = file.deletingPathExtension().lastPathComponent
            let components = fileName.split(separator: "_")

            if components.count >= 3 {
                let timestamp = Double(components[0])
                let keyPressed = String(components[1])
                let windowName = String(components[2])

                // Use these details as needed
                print("Timestamp: \(timestamp), Key Pressed: \(keyPressed), Window Name: \(windowName)")
            }
        }
    } catch {
        print("Could not read directory contents.")
    }
}

@main
struct KabinApp: App {
    @State var isRecording: Bool = false
    @State var directory: URL = .init(string: "/tmp")!
    private var eventTapManager: EventTapManager = .init()
    private var screenshotManager: ScreenshotManager

    init() {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        screenshotManager = ScreenshotManager(directory: directory)
        eventTapManager.callback = { [screenshotManager] _, _, _ in
        }
    }

    var body: some Scene {
        MenuBarExtra("Kabin", systemImage: "person.2.crop.square.stack") {
            VStack {
                Button("Choose Save Directory") {
                    let openPanel = NSOpenPanel()
                    openPanel.canChooseFiles = false
                    openPanel.canChooseDirectories = true
                    openPanel.allowsMultipleSelection = false
                    openPanel.makeKeyAndOrderFront(nil)

                    NSApplication.shared.activate(ignoringOtherApps: true)
                    openPanel.center()
                    openPanel.makeKeyAndOrderFront(nil)

                    openPanel.begin { result in
                        if result == .OK {
                            self.directory = openPanel.urls.first!
                            screenshotManager.changeDirectory(directory)
                        }
                    }
                }

                Button("Record") {
                    isRecording = true
                    eventTapManager.callback = { [screenshotManager] eventType, _, activeWindow in
                        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.01) {
                            print("Event detected: \(eventType)")
                            screenshotManager.takeScreenshot(filenamePostfix: activeWindow)
                        }
                    }
                }
                .disabled(isRecording || directory.path == "/tmp")
                Button("Stop Recording") {
                    isRecording = false
                    eventTapManager.callback = { [screenshotManager] _, _, _ in
                    }
                }
                .disabled(isRecording ? false : true)

                Button("Generate Description") {
                    Task {
                        processScreenshotFiles(from: directory)
                    }
                }.disabled(isRecording || directory.path == "/tmp")

                Button("Clear Directory") {
                    Task {
                        deleteFilesInFolder(atPath: directory)
                    }
                }.disabled(isRecording || directory.path == "/tmp")
            }
        }
    }
}
