//
//  Item.swift
//  Item
//
//  Created by 钟增强 on 2021/9/12.
//

struct Item: Hashable, Codable, Identifiable {
    var id: Int
    var type: String
    var name: String
}
