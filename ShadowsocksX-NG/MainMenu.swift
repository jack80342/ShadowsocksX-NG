//
//  MainMenu.swift
//  ShadowsocksX-NG
//
//  Created by 钟增强 on 2021/8/21.
//

import SwiftUI
import Introspect

struct MainMenu: View {

    var body: some View {
        List {
            Divider()
            Text("显示日志")
            Text("反馈")
            Text("检查更新")
            Text("打开时检查更新")
            Text("关于")
            Divider()
            HStack {
                Text("退出")
            }
        }.removeBackground()
    }
}

struct MainMenu_Previews: PreviewProvider {
    static var previews: some View {
        MainMenu()
    }
}

extension List {
    // List on macOS uses an opaque background with no option for
    // removing/changing it. listRowBackground() doesn't work either.
    // This workaround works because List is backed by NSTableView.
    func removeBackground() -> some View {
        return introspectTableView { tableView in
            tableView.backgroundColor = .clear
            tableView.enclosingScrollView!.drawsBackground = false
        }
    }
}
