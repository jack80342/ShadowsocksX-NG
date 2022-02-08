//
//  SWBApplication.swift
//  ShadowsocksX-NG
//
//  Created by 钟增强 on 2021/4/13.
//

import Cocoa

@objc(SWBApplication)
class SWBApplication: NSApplication {
    open override func sendEvent(_ event: NSEvent) {
        if event.type == .keyDown {
            if event.modifierFlags.contains(.command) && NSEvent.ModifierFlags.deviceIndependentFlagsMask.contains(.command) {
                if event.modifierFlags.contains(.shift) && NSEvent.ModifierFlags.deviceIndependentFlagsMask.contains(.shift) {
                    if event.charactersIgnoringModifiers == "Z" {
                        if NSApp.sendAction(Selector(("redo:")), to: nil, from: self) { return }
                    }
                }
                guard let key = event.charactersIgnoringModifiers else { return super.sendEvent(event) }
                switch key {
                case "x":
                    if NSApp.sendAction(#selector(NSText.cut(_:)), to: nil, from: self) { return }
                case "c":
                    if NSApp.sendAction(#selector(NSText.copy(_:)), to: nil, from: self) { return }
                case "v":
                    if NSApp.sendAction(#selector(NSText.paste(_:)), to: nil, from: self) { return }
                case "z":
                    if NSApp.sendAction(Selector(("undo:")), to: nil, from: self) { return }
                case "a":
                    if NSApp.sendAction(#selector(NSStandardKeyBindingResponding.selectAll(_:)), to: nil, from: self) { return }
                default:
                    break
                }
            }
        }
        super.sendEvent(event)
    }

}
