//
//  MainMenu.swift
//  ShadowsocksX-NG
//
//  Created by 钟增强 on 2021/8/21.
//

import SwiftUI
import Introspect

struct MainMenu: View {
    @StateObject
    private var modelData = ModelData()
    @State
    private var selectedItem = ""

    var body: some View {
        List {
            ForEach(modelData.itemList) { item in
                if(item.type == "divider") {
                    Divider()
                } else {
                    Text(item.name)
                        .foregroundColor(Color.black)
                        .listRowBackground(
                        selectedItem == item.name ? Color(red: 78 / 255, green: 160 / 255, blue: 252 / 255) : Color.clear)
                        .onHover(
                        perform: { hovering in
                            if hovering {
                                self.selectedItem = item.name
                            } else if selectedItem == item.name {
                                selectedItem = ""
                            }
                        })
                }
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
