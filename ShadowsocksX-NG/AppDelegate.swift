//
//  AppDelegate.swift
//  ShadowsocksX-NG
//
//  Created by 钟增强 on 2021/8/21.
//

import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {

    // 状态栏
    var statusBarItem: NSStatusItem!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        setStatusItem()
    }

    func setStatusItem() {
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        let menuItem = NSMenuItem()
        let view = NSHostingView(rootView: MainMenu())
        // Don't forget to set the frame, otherwise it won't be shown.
        view.frame = NSRect(x: 0, y: 0, width: 200, height: 200)
        menuItem.view = view
        let menu = NSMenu()
        menu.addItem(menuItem)
        statusBarItem?.menu = menu

        let image = NSImage(named: NSImage.Name("menu_icon"))
        image!.isTemplate = true
        statusBarItem!.button?.image = image
    }

}
