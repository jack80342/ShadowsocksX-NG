//
//  ProxyConfTool.swift
//  ShadowsocksX-NG
//
//  Created by 钟增强 on 2021/4/24.
//

import Foundation
import SystemConfiguration

class ProxyConfTool {
    func networkServicesList() -> NSArray {
        let results: NSArray = []

        let prefRef = SCPreferencesCreate(nil, "Shadowsocks" as CFString, nil)
        let sets: NSDictionary? = SCPreferencesGetValue(prefRef!, kSCPrefNetworkServices) as? NSDictionary
        // 遍历系统中的网络设备列表
        for key in sets?.allKeys ?? [] {
            guard let key = key as? String else {
                continue
            }
            let service: NSDictionary = sets?[key] as! NSDictionary
            let userDefinedName = service[kSCPropUserDefinedName as String] as? String
            let isActive = service[kSCResvInactive as String] as! Bool
            if isActive && userDefinedName != nil {
                let v = [
                    "key": key,
                    "userDefinedName": userDefinedName ?? ""
                ]
                results.adding(v)
            }
        }

        return results
    }
}
