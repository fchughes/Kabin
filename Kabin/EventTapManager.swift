//
//  EventTapManager.swift
//  Kabin
//
//  Created by Forest Hughes on 7/17/23.
//

import AppKit
import CoreGraphics
import Foundation

class EventTapManager: ObservableObject {
    // Define the event type
    enum EventType {
        case mouse
        case key
    }

    // Define a callback type
    typealias EventCallback = (EventType, CGEvent, String) -> Void

    // The callback to call when an event occurs
    var callback: EventCallback?

    init() {
        // Callback function to handle events
        let eventTapCallback: CGEventTapCallBack = { _, type, event, refcon -> Unmanaged<CGEvent>? in

            guard let activeApp = NSWorkspace.shared.frontmostApplication,
                  let appWindowList = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: AnyObject]]
            else {
                return Unmanaged.passRetained(event)
            }

            let appWindows = appWindowList.filter { info in
                guard let windowOwnerPID = info[kCGWindowOwnerPID as String] as? Int,
                      let windowNumber = info[kCGWindowNumber as String] as? Int,
                      windowNumber > 0,
                      windowOwnerPID == activeApp.processIdentifier
                else {
                    return false
                }
                return true
            }

            guard let callback = Unmanaged<EventTapManager>.fromOpaque(refcon!).takeUnretainedValue().callback else {
                return Unmanaged.passRetained(event)
            }

            let activeWindowName = appWindows.first?["kCGWindowName"] as? String ?? "Unknown"
            let windowName = activeWindowName.isEmpty == false ? activeWindowName : activeApp.localizedName ?? "Unknown"

            if let activeWindow = appWindows.first,
               let windowBoundsDict = activeWindow[kCGWindowBounds as String] as? [String: Any],
               let windowBounds = CGRect(dictionaryRepresentation: windowBoundsDict as CFDictionary)
            {
                let windowOrigin = windowBounds.origin
                let screenPoint = NSEvent.mouseLocation // getting mouse location
                let windowPoint = NSPoint(x: screenPoint.x - windowOrigin.x, y: screenPoint.y - windowOrigin.y)
                print("Window Point: \(windowPoint)")
            }

            let eventType = CGEventType(rawValue: type.rawValue)!
            switch eventType {
            case .leftMouseDown, .rightMouseDown, .otherMouseDown, .leftMouseUp, .rightMouseUp, .otherMouseUp:
                callback(.mouse, event, windowName)
            case .keyDown:
                let keyCode = Int(event.getIntegerValueField(.keyboardEventKeycode))
                callback(.key, event, "\(keyCode)_\(windowName)")
            default:
                break
            }

            return Unmanaged.passRetained(event)
        }

        // Create the event tap
        let eventMask = (1 << CGEventType.leftMouseDown.rawValue) | (1 << CGEventType.rightMouseDown.rawValue) | (1 << CGEventType.otherMouseDown.rawValue) | (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue)
        guard let eventTap = CGEvent.tapCreate(tap: .cghidEventTap, place: .headInsertEventTap, options: .defaultTap, eventsOfInterest: CGEventMask(eventMask), callback: eventTapCallback, userInfo: Unmanaged.passUnretained(self).toOpaque()) else {
            print("Failed to create event tap")
            exit(1)
        }

        // Create a run loop source and add it to the run loop
        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)

        // Enable the event tap
        CGEvent.tapEnable(tap: eventTap, enable: true)

        // Run the run loop in the background
        DispatchQueue.global(qos: .background).async {
            CFRunLoopRun()
        }
    }
}

// class EventTapCallBackHolder {
//    let eventCallback: EventCallback
//    init(callback: @escaping EventCallback) {
//        self.eventCallback = callback
//    }
// }
//
// class EventTapManager: ObservableObject {
//    // The callback to call when an event occurs
//    var callback: EventCallback?
//
//    init(eventCallback: @escaping EventCallback) {
//        let callbackHolder = EventTapCallBackHolder(callback: eventCallback)
//
//        let eventTapCallback: CGEventTapCallBack = { _, type, event, refcon -> Unmanaged<CGEvent>? in
//            let callbackHolder = Unmanaged<EventTapCallBackHolder>.fromOpaque(refcon!).takeUnretainedValue()
//
//            let eventType = CGEventType(rawValue: type.rawValue)!
//            switch eventType {
//            case .leftMouseDown, .rightMouseDown, .otherMouseDown, .leftMouseUp, .rightMouseUp, .otherMouseUp:
//                callbackHolder.eventCallback(.mouse, event)
//            case .keyDown, .keyUp:
//                callbackHolder.eventCallback(.key, event)
//            default:
//                break
//            }
//            return Unmanaged.passRetained(event)
//        }
//
//        let eventMask = (1 << CGEventType.leftMouseDown.rawValue) | (1 << CGEventType.rightMouseDown.rawValue) | (1 << CGEventType.otherMouseDown.rawValue) | (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue)
//        guard let eventTap = CGEvent.tapCreate(tap: .cghidEventTap, place: .headInsertEventTap, options: .defaultTap, eventsOfInterest: CGEventMask(eventMask), callback: eventTapCallback, userInfo: Unmanaged.passRetained(callbackHolder).toOpaque()) else {
//            print("Failed to create event tap")
//            exit(1)
//        }
//
//        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
//        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
//
//        CGEvent.tapEnable(tap: eventTap, enable: true)
//
//        DispatchQueue.global(qos: .background).async {
//            CFRunLoopRun()
//        }
//    }
// }
