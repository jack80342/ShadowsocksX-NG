//
//  ProxyConfHelper.swift
//  proxy_conf_helper
//
//  Created by 钟增强 on 2021/5/9.
//

import Foundation
import ArgumentParser
import SystemConfiguration

struct ProxyConfHelper: ParsableCommand {

    @Flag(name: .shortAndLong, help: "Print the version number.")
    var version = false

    @Option(name: .shortAndLong, help: "Proxy mode,may be:auto,global,off")
    var mode: String?

    @Option(name: [.long, .customShort("u")], help: "PAC file url for auto mode.")
    var pacUrl: String?

    @Option(name: .shortAndLong, help: "Listen port for global mode.")
    var port: Int?

    @Option(name: [.long, .customShort("r")], help: "Privoxy Port for global mode.")
    var privoxyPort: Int?

    @Option(name: .shortAndLong, parsing: .upToNextOption, help: "Manual specify the network profile need to set proxy.")
    var networkService: [String] = []

    mutating func run() throws {
        if version {
            print("\(kProxyConfHelperVersion)")
            throw ExitCode.success
        }

        // validate
        if(mode == "auto" && pacUrl == nil) {
            throw ValidationError("Please specify a PAC file url for auto mode.")
        } else if(mode == "global") {
            if(port == nil) {
                throw ValidationError("Please specify a listening port for global mode.")
            } else if(port == 0) {
                throw ValidationError("Invalid port for global mode.")
            }
        }

        var authRef: AuthorizationRef?
        let authFlags: AuthorizationFlags = [.extendRights, .interactionAllowed, .preAuthorize]
        let authErr = AuthorizationCreate(nil, nil, authFlags, &authRef)
        if authErr != noErr {
            authRef = nil
            print("Error when create authorization")
            throw ExitCode.failure
        } else {
            if authRef == nil {
                print("No authorization has been granted to modify network configuration")
                throw ExitCode.failure
            }

            if let prefRef = SCPreferencesCreateWithAuthorization(nil, "Shadowsocks" as CFString, nil, authRef),
                let sets = SCPreferencesGetValue(prefRef, kSCPrefNetworkServices) {
                var proxies: [String: Any] = [:]
                proxies[kCFNetworkProxiesHTTPEnable as String] = NSNumber(value: 0)
                proxies[kCFNetworkProxiesHTTPSEnable as String] = NSNumber(value: 0)
                proxies[kCFNetworkProxiesProxyAutoConfigEnable as String] = NSNumber(value: 0)
                proxies[kCFNetworkProxiesSOCKSEnable as String] = NSNumber(value: 0)
                proxies[kCFNetworkProxiesExceptionsList as String] = []

                // 遍历系统中的网络设备列表，设置 AirPort 和 Ethernet 的代理
                for key in sets.allKeys {
                    guard let key = key as? String else {
                        continue
                    }
                    let dict = sets.object(forKey: key) as? NSDictionary
                    let hardware = dict?.value(forKeyPath: "Interface.Hardware") as? String

                    var modify = false
                    if networkService.count > 0 {
                        if networkService.contains(key) {
                            modify = true
                        }
                    } else if (hardware == "AirPort") || (hardware == "Wi-Fi") || (hardware == "Ethernet") {
                        modify = true
                    }

                    if modify {
                        let prefPath = "/\(kSCPrefNetworkServices)/\(key)/\(kSCEntNetProxies)"

                        if mode == "auto" {
                            proxies[kCFNetworkProxiesProxyAutoConfigURLString as String] = pacUrl
                            proxies[kCFNetworkProxiesProxyAutoConfigEnable as String] = NSNumber(value: 1)
                            SCPreferencesPathSetValue(prefRef, prefPath as CFString, proxies as CFDictionary)
                        } else if mode == "global" {
                            proxies[kCFNetworkProxiesSOCKSProxy as String] = "127.0.0.1"
                            proxies[kCFNetworkProxiesSOCKSPort as String] = NSNumber(value: port!)
                            proxies[kCFNetworkProxiesSOCKSEnable as String] = NSNumber(value: 1)
                            proxies[kCFNetworkProxiesExceptionsList as String] = ["127.0.0.1", "localhost"]

                            if privoxyPort != 0 {
                                proxies[kCFNetworkProxiesHTTPProxy as String] = "127.0.0.1"
                                proxies[kCFNetworkProxiesHTTPPort as String] = NSNumber(value: privoxyPort!)
                                proxies[kCFNetworkProxiesHTTPEnable as String] = NSNumber(value: 1)

                                proxies[kCFNetworkProxiesHTTPSProxy as String] = "127.0.0.1"
                                proxies[kCFNetworkProxiesHTTPSPort as String] = NSNumber(value: privoxyPort!)
                                proxies[kCFNetworkProxiesHTTPSEnable as String] = NSNumber(value: 1)
                            }
                            SCPreferencesPathSetValue(prefRef, prefPath as CFString, proxies as CFDictionary)
                        } else if mode == "off" {
                            if pacUrl != nil && port != nil {
                                // 取原来的配置，判断是否为shadowsocksX-NG设置的
                                if let oldProxies = SCPreferencesPathGetValue(prefRef, prefPath as CFString) as? [String: AnyObject] {

                                    let proxyEnable: Bool = oldProxies[kCFNetworkProxiesProxyAutoConfigURLString as String]?.contains(pacUrl as Any) ?? false && oldProxies[kCFNetworkProxiesProxyAutoConfigEnable as String] === NSNumber(value: 1)
                                    if(proxyEnable) {
                                        if(oldProxies[kCFNetworkProxiesSOCKSProxy as String] as! String == "127.0.0.1" && oldProxies[kCFNetworkProxiesSOCKSPort as String]?.isEqual(to: NSNumber(value: port!)) ?? false && oldProxies[kCFNetworkProxiesSOCKSEnable as String] === NSNumber(value: 1)) {
                                        SCPreferencesPathSetValue(prefRef, prefPath as CFString, proxies as CFDictionary)
                                    }
                                }
                            }
                        } else {
                            SCPreferencesPathSetValue(prefRef, prefPath as CFString, proxies as CFDictionary)
                        }
                    }
                }
            }

            SCPreferencesCommitChanges(prefRef);
            SCPreferencesApplyChanges(prefRef);
            SCPreferencesSynchronize(prefRef);

            AuthorizationFree(authRef!, AuthorizationFlags());
        }
    }
}
}

ProxyConfHelper.main()
