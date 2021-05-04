//
//  IconUtils.swift
//  ShadowsocksX-NG-R
//
//  Created by 钟增强 on 2021/5/4.
//

import Foundation

class IconUtils{
    public class func getIconImageName() -> String {
        var iconImageName = "";
        let defaults = UserDefaults.standard
        let mode = defaults.string(forKey: "ShadowsocksRunningMode")
        if mode == "auto" {
            iconImageName = "menu_icon_pac"
        } else if mode == "global" {
            iconImageName = "menu_icon_global"
        } else if mode == "manual" {
            iconImageName = "menu_icon_manual"
        } else if mode == "whiteList" {
            if defaults.string(forKey: "ACLFileName")! == "chn.acl" {
                iconImageName = "menu_icon_white"
            } else {
                iconImageName = "menu_icon_acl"
            }
        }
        
        return iconImageName;
    }
}
