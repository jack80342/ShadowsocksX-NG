//
//  ProxyConfHelper.swift
//  ShadowsocksX-NG-R
//
//  Created by 钟增强 on 2021/4/20.
//

import Foundation
import GCDWebServer

class ProxyConfHelper {

    let kShadowsocksHelper = "/Library/Application Support/ShadowsocksX-NG-R/proxy_conf_helper"

    var webServer: GCDWebServer? = nil

    func isVersionOk() -> Bool {
        var task: Process?
        task = Process()
        task?.launchPath = kShadowsocksHelper

        var args: [AnyHashable]?
        args = ["-v"]
        task?.arguments = args as? [String]

        var pipe: Pipe?
        pipe = Pipe()
        task?.standardOutput = pipe

        var fd: FileHandle?
        fd = pipe?.fileHandleForReading

        task?.launch()

        var data: Data?
        data = fd?.readDataToEndOfFile()

        var str: String?
        if let data = data {
            str = String(data: data, encoding: .utf8)
        }

        if str != kProxyConfHelperVersion {
            return false
        }
        return true
    }

    func install() {
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: kShadowsocksHelper) || !isVersionOk() {
            let helperPath = "\(Bundle.main.resourcePath ?? "")/\("install_helper.sh")"
            NSLog("run install script: \(helperPath)")
            var error: NSDictionary?
            let script = "do shell script \"bash \(helperPath)\" with administrator privileges"
            let appleScript = type(of: NSAppleScript()).init(source: script)
            if appleScript?.executeAndReturnError(&error) != nil {
                print("installation success")
            } else {
                print("installation failure")
            }
        }
    }

    func callHelper(_ arguments: [AnyHashable]?) {
        var task: Process?
        task = Process()
        task?.launchPath = kShadowsocksHelper

        // this log is very important
        print("run shadowsocks helper: \(kShadowsocksHelper)")
        task?.arguments = arguments as? [String]

        var stdoutpipe: Pipe?
        stdoutpipe = Pipe()
        task?.standardOutput = stdoutpipe

        var stderrpipe: Pipe?
        stderrpipe = Pipe()
        task?.standardError = stderrpipe

        var file: FileHandle?
        file = stdoutpipe?.fileHandleForReading

        task?.launch()

        var data: Data?
        data = file?.readDataToEndOfFile()

        var string: String?
        if let data = data {
            string = String(data: data, encoding: .utf8)
        }
        if (string?.count ?? 0) > 0 {
            print("\(string ?? "")")
        }

        file = stderrpipe?.fileHandleForReading
        data = file?.readDataToEndOfFile()
        if let data = data {
            string = String(data: data, encoding: .utf8)
        }
        if (string?.count ?? 0) > 0 {
            print("\(string ?? "")")
        }
    }

    func addArguments4ManualSpecifyNetworkServices(_ args: inout [String]) {
        let defaults = UserDefaults.standard

        if !defaults.bool(forKey: "AutoConfigureNetworkServices") {
            let serviceKeys = defaults.array(forKey: "Proxy4NetworkServices")
            if let serviceKeys = serviceKeys {
                for key in serviceKeys {
                    guard let key = key as? String else {
                        continue
                    }
                    args.append("--network-service")
                    args.append(key)
                }
            }
        }
    }

    func enablePACProxy(_ PACFilePath: String) {
        //start server here and then using the string next line
        //next two lines can open gcdwebserver and work around pac file
        let PACURLString = startPACServer(PACFilePath) //hi 可以切换成定制pac文件路径来达成使用定制文件路径
        let url = URL(string: PACURLString!)

        var args = ["--mode", "auto", "--pac-url", url!.absoluteString]

        addArguments4ManualSpecifyNetworkServices(&args)
        callHelper(args)
    }


    func enableGlobalProxy() {
        let port = UserDefaults.standard.integer(forKey: "LocalSocks5.ListenPort")

        var args = [
            "--mode",
            "global",
            "--port",
            String(format: "%lu", UInt(port))
        ]

        if UserDefaults.standard.bool(forKey: "LocalHTTPOn") && UserDefaults.standard.bool(forKey: "LocalHTTP.FollowGlobal") {
            let privoxyPort = UserDefaults.standard.integer(forKey: "LocalHTTP.ListenPort")

            args.append("--privoxy-port")
            args.append(String(format: "%lu", UInt(privoxyPort)))
        }

        addArguments4ManualSpecifyNetworkServices(&args)
        callHelper(args)
        stopPACServer()
    }

    func enableWhiteListProxy() {
        // 基于全局socks5代理下使用ACL文件来进行白名单代理 不需要使用pac文件
        let port = UserDefaults.standard.integer(forKey: "LocalSocks5.ListenPort")

        var args = [
            "--mode",
            "global",
            "--port",
            String(format: "%lu", UInt(port))
        ]

        if UserDefaults.standard.bool(forKey: "LocalHTTPOn") && UserDefaults.standard.bool(forKey: "LocalHTTP.FollowGlobal") {
            let privoxyPort = UserDefaults.standard.integer(forKey: "LocalHTTP.ListenPort")

            args.append("--privoxy-port")
            args.append(String(format: "%lu", UInt(privoxyPort)))
        }

        addArguments4ManualSpecifyNetworkServices(&args)
        callHelper(args)
        stopPACServer()
    }

    func disableProxy(_ PACFilePath: String?) {
        var args = ["--mode", "off"]
        addArguments4ManualSpecifyNetworkServices(&args)
        callHelper(args)
        stopPACServer()
    }

    func startPACServer(_ PACFilePath: String?) -> String? {
        var PACFilePath = PACFilePath
        //接受参数为以后使用定制PAC文件
        var originalPACData: Data?
        var routerPath = "/proxy.pac"
        if PACFilePath == "hi" {
            //用默认路径来代替
            PACFilePath = "\(NSHomeDirectory())/\(".ShadowsocksX-NG/gfwlist.js")"
            originalPACData = NSData(contentsOfFile: "\(NSHomeDirectory())/\(".ShadowsocksX-NG/gfwlist.js")") as Data?
        } else {
            //用定制路径来代替
            originalPACData = NSData(contentsOfFile: "\(NSHomeDirectory())/\(".ShadowsocksX-NG")/\(PACFilePath ?? "")") as Data?
            routerPath = "/\(PACFilePath ?? "")"
        }
        stopPACServer()
        webServer = GCDWebServer()
        webServer?.addHandler(forMethod: "GET", path: routerPath, request: GCDWebServerRequest.self, processBlock: { request in
            return GCDWebServerDataResponse(data: originalPACData!, contentType: "application/x-ns-proxy-autoconfig")
        })
        let defaults = UserDefaults.standard
        let address = defaults.string(forKey: "PacServer.ListenAddress")
        let port = Int(Int16(defaults.integer(forKey: "PacServer.ListenPort")))

        do {
            try webServer!.start(options: [
                "BindToLocalhost": NSNumber(value: true),
                "Port": NSNumber(value: port)
                ])
        } catch {
        }

        return "\("http://")\(address ?? ""):\(port)\(routerPath)"
    }

    func stopPACServer() {
        if ((webServer?.isRunning) != nil) {
            webServer?.stop()
            webServer = nil
        }
    }
}
