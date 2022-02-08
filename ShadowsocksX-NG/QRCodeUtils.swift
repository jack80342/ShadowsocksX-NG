//
//  QRCodeUtils.swift
//  ShadowsocksX-NG
//
//  Created by 钟增强 on 2021/4/15.
//

import Cocoa

func scanQRCodeOnScreen() {

    var displayCount: UInt32 = 0;

    // How many active displays do we have?
    var result = CGGetActiveDisplayList(0, nil, &displayCount)

    // If we are getting an error here then their won't be much to display.
    if result != CGError.success {
        NSLog("Could not get active display count: \(result)")
        return
    }

    let allocated = Int(displayCount)
    // Allocate enough memory to hold all the display IDs we have.
    let activeDisplays = UnsafeMutablePointer<CGDirectDisplayID>.allocate(capacity: allocated)

    // Get the list of active displays
    result = CGGetActiveDisplayList(displayCount, activeDisplays, &displayCount)
    // More error-checking here.
    if (result != CGError.success) {
        NSLog("Could not get active display list: \(result)")
        return
    }

    var foundSSUrls: [AnyHashable] = []

    let detector = CIDetector(
        ofType: CIDetectorTypeQRCode,
        context: CIContext(options: [
            CIContextOption.useSoftwareRenderer: NSNumber(value: true)
            ]),
        options: [
            CIDetectorAccuracy: CIDetectorAccuracyHigh
        ])

    for displaysIndex in 0..<Int(displayCount) {
        // Make a snapshot image of the current display.
        let image: CGImage? = CGDisplayCreateImage(activeDisplays[displaysIndex])

        var features: [CIFeature]? = nil
        if let image = image {
            features = detector?.features(in: CIImage(cgImage: image))
        }
        for feature in features ?? [] {
            guard let feature = feature as? CIQRCodeFeature else {
                continue
            }
            if feature.messageString?.hasPrefix("ss://") ?? false {
                if let url = URL(string: feature.messageString ?? "") {
                    foundSSUrls.append(url)
                }
            } else if feature.messageString?.hasPrefix("ssr://") ?? false {
                if let url = URL(string: feature.messageString ?? "") {
                    foundSSUrls.append(url)
                }
            }
        }
    }

    free(activeDisplays)
    // if not find any urls push a notification tells there is no QR on the screen
    NotificationCenter.default.post(
        name: NSNotification.Name("NOTIFY_FOUND_SS_URL"),
        object: nil,
        userInfo: [
            "urls": foundSSUrls,
            "source": "qrcode"
        ])
}

func decode64(_ str: String?) -> String? {
    var str = str

    str = str?.replacingOccurrences(of: "-", with: "+")
    str = str?.replacingOccurrences(of: "_", with: "/")
    if (str?.count ?? 0) % 4 != 0 {
        let length = (4 - (str?.count ?? 0) % 4) + (str?.count ?? 0)
        str = str?.padding(toLength: length, withPad: "=", startingAt: 0)
    }
    let decodeData = Data(base64Encoded: str ?? "", options: [])
    var decodeStr: String? = nil
    if let decodeData = decodeData {
        decodeStr = String(data: decodeData, encoding: .utf8)
    }
    return decodeStr
}

func encode64(_ str: String?) -> String? {
    let data = str?.data(using: .utf8)
    var stringBase64 = data?.base64EncodedString(options: .endLineWithCarriageReturn)
    stringBase64 = stringBase64?.replacingOccurrences(of: "+", with: "-")
    stringBase64 = stringBase64?.replacingOccurrences(of: "/", with: "_")
    stringBase64 = stringBase64?.replacingOccurrences(of: "=", with: "")
    return stringBase64
}

func parseAppURLSchemes(_ url: URL?) -> [String: Any?]? {
    if url?.host == nil {
        return nil
    }
    let urlString = url?.absoluteString
    if urlString?.hasPrefix("ss://") ?? false {
        return parseSsUrl(url)
    }
    if urlString?.hasPrefix("ssr://") ?? false {
        return parseSsrUrl(url)
    }
    return nil
}

/*
  解析SS URL，如果成功则返回一个与ServerProfile类兼容的dict
  或SSR URL，ServerProfile类已经默认添加SSR参数，默认放空，如果URL为SSR://则改变解析方法
  ss:// + base64(method:password@domain:port)
 */
private func parseSsUrl(_ url: URL?) -> [String: Any?]? {
    if url?.host == nil {
        return nil
    }

    var urlString: String? = url?.absoluteString
    var i = 0
    if urlString?.hasPrefix("ss://") ?? false {
        while i < 2 {
            if i == 1 {
                var host = url?.host
                if (host?.count ?? 0) % 4 != 0 {
                    let n = 4 - (host?.count ?? 0) % 4
                    if 1 == n {
                        host = (host ?? "") + "="
                    } else if 2 == n {
                        host = (host ?? "") + "=="
                    }
                }
                let data = Data(base64Encoded: host ?? "", options: [])
                var decodedString: String? = nil
                if let data = data {
                    decodedString = String(data: data, encoding: .utf8)
                }
                urlString = decodedString
            }
            i += 1
            urlString = (urlString as NSString?)?.replacingOccurrences(of: "ss://", with: "", options: .anchored, range: NSRange(location: 0, length: urlString?.count ?? 0))
            let firstColonRange = (urlString as NSString?)?.range(of: ":")
            let lastColonRange = (urlString as NSString?)?.range(of: ":", options: .backwards)
            let lastAtRange = (urlString as NSString?)?.range(of: "@", options: .backwards)
            if (firstColonRange?.length ?? 0) == 0 {
                NSLog("colon not found")
                continue
            }
            if firstColonRange?.location == lastColonRange?.location {
                NSLog("only one colon")
                continue
            }
            if (lastAtRange?.length ?? 0) == 0 {
                NSLog("at not found")
                continue
            }
            if ((firstColonRange!.location < lastAtRange!.location) && (lastAtRange!.location < lastColonRange!.location)) {
                NSLog("wrong position")
                continue
            }
            let method = (urlString as NSString?)?.substring(with: NSRange(location: 0, length: firstColonRange!.location))
            let password = (urlString as NSString?)?.substring(with: NSRange(location: firstColonRange!.location + 1, length: lastAtRange!.location - firstColonRange!.location - 1))
            let IP = (urlString as NSString?)?.substring(with: NSRange(location: lastAtRange!.location + 1, length: lastColonRange!.location - lastAtRange!.location - 1))
            let port = (urlString as NSString?)?.substring(with: NSRange(location: lastColonRange!.location + 1, length: (urlString?.count ?? 0) - lastColonRange!.location - 1))

            return [
                "ServerHost": IP ?? "",
                "ServerPort": NSNumber(value: Int(port ?? "") ?? 0),
                "Method": method ?? "",
                "Password": password ?? ""
            ]
        }
    }
    return nil
}

private func parseSsrUrl(_ url: URL?) -> [String : Any?]? {
    var urlString = url?.absoluteString
    var firstParam: String?
    var lastParam: String?
    //if ([urlString hasPrefix:@"ssr://"]){
    // ssr:// + base64(abc.xyz:12345:auth_sha1_v2:rc4-md5:tls1.2_ticket_auth:{base64(password)}/?obfsparam={base64(混淆参数(网址))}&protoparam={base64(混淆协议)}&remarks={base64(节点名称)}&group={base64(分组名)})

    urlString = (urlString as NSString?)?.replacingOccurrences(of: "ssr://", with: "", options: .anchored, range: NSRange(location: 0, length: urlString?.count ?? 0))
    let decodedString = decode64(urlString!)
    NSLog("decodedString: \(decodedString ?? "")")
    if decodedString == "" {
        NotificationCenter.default.post(
            name: NSNotification.Name("NOTIFY_INVALIDE_QR"),
            object: nil,
            userInfo: [
                "urls": "配置二维码无效!",
                "source": "qrcode"
            ])
    } else {
        let paramSplit = (decodedString! as NSString).range(of: "?")

        if paramSplit.length == 0 {
            firstParam = decodedString
        } else {
            firstParam = (decodedString! as NSString).substring(to: paramSplit.location - 1)
            lastParam = (decodedString! as NSString).substring(from: paramSplit.location)
        }

        let parserLastParamDict = parseSsrLastParam(lastParam)

        //后面已经parser完成，接下来需要解析到profile里面
        //abc.xyz:12345:auth_sha1_v2:rc4-md5:tls1.2_ticket_auth:{base64(password)}
        var range = (firstParam as NSString?)?.range(of: ":")
        let ip = (firstParam as NSString?)?.substring(to: range?.location ?? 0) //第一个参数是域名

        firstParam = (firstParam as NSString?)?.substring(from: (range?.location ?? 0) + (range?.length ?? 0))
        range = (firstParam as NSString?)?.range(of: ":")
        let port = (firstParam as NSString?)?.substring(to: range?.location ?? 0) //第二个参数是端口

        firstParam = (firstParam as NSString?)?.substring(from: range!.location + range!.length)
        range = (firstParam as NSString?)?.range(of: ":")
        let ssrProtocol = (firstParam as NSString?)?.substring(to: range!.location) //第三个参数是协议

        firstParam = (firstParam as NSString?)?.substring(from: range!.location + range!.length)
        range = (firstParam as NSString?)?.range(of: ":")
        let encryption = (firstParam as NSString?)?.substring(to: range!.location) //第四个参数是加密

        firstParam = (firstParam as NSString?)?.substring(from: range!.location + range!.length)
        range = (firstParam as NSString?)?.range(of: ":")
        let ssrObfs = (firstParam as NSString?)?.substring(to: range!.location) //第五个参数是混淆协议

        firstParam = (firstParam as NSString?)?.substring(from: range!.location + range!.length)
        // range = [firstParam rangeOfString:@":"];
        let password = decode64(firstParam!)
        // [[NSString alloc] initWithData:[[NSData alloc] initWithBase64EncodedString:firstParam options:0]encoding:NSUTF8StringEncoding];//第五个参数是base64密码

        var ssrObfsParam = ""
        var remarks = ""
        var ssrProtocolParam = ""
        var ssrGroup = ""
        for key in parserLastParamDict!.keys {
            if key == "obfsparam" {
                ssrObfsParam = parserLastParamDict![key] as! String
            } else if key == "remarks" {
                remarks = parserLastParamDict![key] as! String
            } else if key == "protoparam" {
                ssrProtocolParam = parserLastParamDict![key] as! String
            } else if key == "group" {
                ssrGroup = parserLastParamDict![key] as! String
            }
        }
        
        return [
            "ServerHost": ip,
            "ServerPort": UInt16(port!),
            "Method": encryption,
            "Password": password ?? "",
            "ssrObfs": ssrObfs,
            "ssrObfsParam": ssrObfsParam,
            "ssrProtocol": ssrProtocol,
            "ssrProtocolParam": ssrProtocolParam,
            "Remark": remarks,
            "ssrGroup": ssrGroup
        ]
    }
    return nil
}

private func parseSsrLastParam(_ lastParam: String?) -> [String : Any?]? {
    var lastParam = lastParam
    var parserLastParamDict: [AnyHashable : Any] = [:]
    if (lastParam?.count ?? 0) == 0 {
        return nil
    }
    lastParam = (lastParam as NSString?)?.substring(from: 1)
    let lastParamArray = lastParam?.components(separatedBy: "&")
    for i in 0..<(lastParamArray?.count ?? 0) {
        let toSplitString = lastParamArray?[i]
        let lastParamSplit = (toSplitString as NSString?)?.range(of: "=")
        if lastParamSplit?.location != NSNotFound {
            let key = (toSplitString as NSString?)?.substring(to: lastParamSplit?.location ?? 0)
            let value = decode64(((toSplitString as NSString?)?.substring(from: (lastParamSplit?.location ?? 0) + 1))!)
            parserLastParamDict[key ?? ""] = value
        }
    }
    return parserLastParamDict as? [String : Any?]
}
