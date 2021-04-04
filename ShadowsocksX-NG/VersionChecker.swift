//
//  VersionChecker.swift
//  ShadowsocksX-NG
//
//  Created by 秦宇航 on 2017/1/9.
//  Copyright © 2017年 qinyuhang. All rights reserved.
//

import Foundation
import Alamofire

let LATEST_RELEASE_URL = "https://api.github.com/repos/shadowsocks/ShadowsocksX-NG/releases/latest"
let _VERSION_XML_LOCAL: String = Bundle.main.bundlePath + "/Contents/Info.plist"

class VersionChecker: NSObject {
    var haveNewVersion: Bool = false
    enum versionError: Error {
        case CanNotGetOnlineData
    }
    func saveFile(fromURL: String, toPath: String, withName: String) -> Bool {
        let manager = FileManager.default
        let url = URL(string: fromURL)!
        do {
            let st = try String(contentsOf: url, encoding: String.Encoding.utf8)
            print(st)
            let data = st.data(using: String.Encoding.utf8)
            manager.createFile(atPath: toPath + withName, contents: data, attributes: nil)
            return true

        } catch {
            print(error)
            return false
        }
    }
    func showAlertView(Title: String, SubTitle: String, ConfirmBtn: String, CancelBtn: String) -> Int {
        let alertView = NSAlert()
        alertView.messageText = Title
        alertView.informativeText = SubTitle
        alertView.addButton(withTitle: ConfirmBtn)
        if CancelBtn != "" {
            alertView.addButton(withTitle: CancelBtn)
        }
        let action = alertView.runModal()
        return action.rawValue
    }
    func parserVersionString(strIn: String) -> Array<Int> {
        let version: Range<String.Index>? = strIn.range(of: "-")
        var strTmp = ""
        if(version != nil) {
            strTmp = String(strIn[..<version!.lowerBound])
        } else {
            strTmp = strIn
        }

        if !strTmp.hasSuffix(".") {
            strTmp += "."
        }
        var ret = [Int]()

        repeat {
            ret.append(Int(String(strTmp[..<strTmp.range(of: ".")!.lowerBound]))!)
            print(strTmp[..<strTmp.range(of: ".")!.lowerBound])
            strTmp = String(strTmp[strTmp.range(of: ".")!.upperBound...])
        } while(strTmp.range(of: ".") != nil);

        return ret
    }
    func checkNewVersion(callback: @escaping (NSDictionary) -> Void) {
        // return
        // newVersion: Bool,
        // error: String,
        // alertTitle: String,
        // alertSubtitle: String,
        // alertConfirmBtn: String,
        // alertCancelBtn: String
        AF.request(LATEST_RELEASE_URL).responseJSON { response in
            switch response.result {
            case .success:
                callback(check(onlineData: response.value as! NSDictionary))
            case .failure(let error):
                print("Request failed with error: \(error)")
                callback(["newVersion": false,
                    "error": "network error",
                    "Title": "网络错误",
                    "SubTitle": "由于网络错误无法检查更新",
                    "ConfirmBtn": "确认",
                    "CancelBtn": ""
                    ])
            }
        }

        func check(onlineData: NSDictionary) -> NSDictionary {
            // 已发布的最新版本
            var versionString: String = onlineData["tag_name"] as! String
            //  去掉版本前缀：v
            versionString = String(versionString[versionString.range(of: "v")!.upperBound...])

            let localData = NSDictionary(contentsOfFile: _VERSION_XML_LOCAL)!
            // 用户的软件版本
            let currentVersionString: String = localData["CFBundleShortVersionString"] as! String

            var subtitle: String
            if (versionString == currentVersionString) {
                // 版本号相同
                subtitle = "当前版本 " + currentVersionString
                return ["newVersion": false,
                    "error": "",
                    "Title": "已是最新版本！",
                    "SubTitle": subtitle,
                    "ConfirmBtn": "确认",
                    "CancelBtn": ""
                ]
            } else {
                // 版本号不同
                var versionArr = parserVersionString(strIn: versionString)
                var currentVersionArr = parserVersionString(strIn: currentVersionString)

                // 做补0处理
                while (max(versionArr.count, currentVersionArr.count) != min(versionArr.count, currentVersionArr.count)) {
                    if (versionArr.count < currentVersionArr.count) {
                        versionArr.append(0)
                    }
                    else {
                        currentVersionArr.append(0)
                    }
                }

                for i in 0..<currentVersionArr.count {
                    if versionArr[i] > currentVersionArr[i] {
                        haveNewVersion = true
                        subtitle = "新版本为 " + versionString + "\n" + "当前版本 " + currentVersionString
                        return ["newVersion": true,
                            "error": "",
                            "Title": "软件有更新！",
                            "SubTitle": subtitle,
                            "ConfirmBtn": "前往下载",
                            "CancelBtn": "取消"
                        ]
                    }
                }
                subtitle = "当前版本 " + currentVersionString
                return ["newVersion": false,
                    "error": "",
                    "Title": "已是最新版本！",
                    "SubTitle": subtitle,
                    "ConfirmBtn": "确认",
                    "CancelBtn": ""
                ]
            }
        }
    }
}
