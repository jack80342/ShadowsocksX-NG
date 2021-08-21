//
//  MainMenu.swift
//  ShadowsocksX-NG
//
//  Created by 钟增强 on 2021/8/21.
//

import SwiftUI

@main
struct ShadowsocksX: App {

    @NSApplicationDelegateAdaptor(AppDelegate.self)
    var appDelegate

    init() {
        // Customize delegate here.
        // appDelegate.myProperty = ""
    }

    var body: some Scene {
        // Settings is required to Hide window
        Settings {
            EmptyView()
        }
    }
}
