//
//  AppDelegate.swift
//  ShadowsocksX-NG
//
//  Created by 邱宇舟 on 16/6/5.
//  Copyright © 2016年 qiuyuzhou. All rights reserved.
//

import Cocoa
import LaunchAtLogin

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSUserNotificationCenterDelegate {

    // MARK: Controllers
    var qrcodeWinCtrl: SWBQRCodeWindowController!
    var preferencesWinCtrl: PreferencesWindowController!
    var advPreferencesWinCtrl: AdvPreferencesWindowController!
    var proxyPreferencesWinCtrl: ProxyPreferencesController!
    var editUserRulesWinCtrl: UserRulesController!
    var httpPreferencesWinCtrl: HTTPPreferencesWindowController!
    var subscribePreferenceWinCtrl: SubscribePreferenceWindowController!

//    var launchAtLoginController: LaunchAtLoginController = LaunchAtLoginController()

    // MARK: Outlets
    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var statusMenu: NSMenu!

    @IBOutlet weak var runningStatusMenuItem: NSMenuItem!
    @IBOutlet weak var toggleRunningMenuItem: NSMenuItem!
    @IBOutlet weak var proxyMenuItem: NSMenuItem!
    @IBOutlet weak var autoModeMenuItem: NSMenuItem!
    @IBOutlet weak var globalModeMenuItem: NSMenuItem!
    @IBOutlet weak var manualModeMenuItem: NSMenuItem!
    @IBOutlet weak var whiteListModeMenuItem: NSMenuItem!
    @IBOutlet weak var ACLModeMenuItem: NSMenuItem!
    @IBOutlet weak var ACLAutoModeMenuItem: NSMenuItem!
    @IBOutlet weak var ACLBackChinaMenuItem: NSMenuItem!

    @IBOutlet weak var serversMenuItem: NSMenuItem!
    @IBOutlet var pingserverMenuItem: NSMenuItem!
    @IBOutlet var showQRCodeMenuItem: NSMenuItem!
    @IBOutlet var scanQRCodeMenuItem: NSMenuItem!
    @IBOutlet var showBunchJsonExampleFileItem: NSMenuItem!
    @IBOutlet var importBunchJsonFileItem: NSMenuItem!
    @IBOutlet var exportAllServerProfileItem: NSMenuItem!
    @IBOutlet var serversPreferencesMenuItem: NSMenuItem!

    @IBOutlet weak var lanchAtLoginMenuItem: NSMenuItem!
    @IBOutlet weak var connectAtLaunchMenuItem: NSMenuItem!
//    @IBOutlet weak var ShowNetworkSpeedItem: NSMenuItem!
    @IBOutlet weak var checkUpdateMenuItem: NSMenuItem!
    @IBOutlet weak var checkUpdateAtLaunchMenuItem: NSMenuItem!
    @IBOutlet var updateSubscribeAtLaunchMenuItem: NSMenuItem!
    @IBOutlet var manualUpdateSubscribeMenuItem: NSMenuItem!
    @IBOutlet var editSubscribeMenuItem: NSMenuItem!

    // MARK: Variables
//    var statusItemView: StatusItemView?
    var statusItem: NSStatusItem!
//    var speedMonitor: NetWorkMonitor?
    var globalSubscribeFeed: Subscribe!
    var proxyConfHelper: ProxyConfHelper = ProxyConfHelper()

    // MARK: Application function

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application

        NSUserNotificationCenter.default.delegate = self

        // Prepare ss-local
        InstallSSLocal()
        InstallPrivoxy()
        // Prepare defaults
        let defaults = UserDefaults.standard
        defaults.register(defaults: [
            "ShadowsocksOn": true,
            "ShadowsocksRunningMode": "auto",
            "LocalSocks5.ListenPort": NSNumber(value: 1086 as UInt16),
            "LocalSocks5.ListenAddress": "127.0.0.1",
            "PacServer.ListenAddress": "127.0.0.1",
            "PacServer.ListenPort": NSNumber(value: 8090 as UInt16),
            "LocalSocks5.Timeout": NSNumber(value: 60 as UInt),
            "LocalSocks5.EnableUDPRelay": NSNumber(value: false as Bool),
            "LocalSocks5.EnableVerboseMode": NSNumber(value: false as Bool),
            "GFWListURL": "https://raw.githubusercontent.com/gfwlist/gfwlist/master/gfwlist.txt",
            "ACLWhiteListURL": "https://raw.githubusercontent.com/shadowsocks/shadowsocks-libev/master/acl/chn.acl",
            "ACLAutoListURL": "https://raw.githubusercontent.com/shadowsocks/shadowsocks-libev/master/acl/gfwlist.acl",
            "ACLProxyBackCHNURL": "https://raw.githubusercontent.com/shadowsocks/shadowsocks-libev/master/ShadowsocksX-NG/server_block_chn.acl",
            "AutoConfigureNetworkServices": NSNumber(value: true as Bool),
            "LocalHTTP.ListenAddress": "127.0.0.1",
            "LocalHTTP.ListenPort": NSNumber(value: 1087 as UInt16),
            "LocalHTTPOn": true,
            "LocalHTTP.FollowGlobal": true,
            "AutoCheckUpdate": false,
            "ACLFileName": "chn.acl",
            "Subscribes": [],
            "AutoUpdateSubscribe": false,
            ])

//        setSpeedStatusItem(defaults.bool(forKey: "enable_showSpeed"))
        if(statusItem == nil) {
            statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
            let image = NSImage(named: NSImage.Name("menu_icon"))
            image!.isTemplate = true
            statusItem!.button?.image = image
            statusItem!.menu = statusMenu
        }

        let notifyCenter = NotificationCenter.default
        notifyCenter.addObserver(forName: NSNotification.Name(rawValue: NOTIFY_ADV_PROXY_CONF_CHANGED), object: nil, queue: nil
            , using: {
                (note) in
                self.applyConfig()
            }
        )
        notifyCenter.addObserver(forName: NSNotification.Name(rawValue: NOTIFY_SERVER_PROFILES_CHANGED), object: nil, queue: nil
            , using: {
                (note) in
                let profileMgr = ServerProfileManager.instance
                if profileMgr.getActiveProfileId() == "" &&
                    profileMgr.profiles.count > 0 {
                    if profileMgr.profiles[0].isValid() {
                        profileMgr.setActiveProfiledId(profileMgr.profiles[0].uuid)
                    }
                }
                self.updateServersMenu()
                self.updateMainMenu()
                self.updateRunningModeMenu()
                SyncSSLocal()
            }
        )
        notifyCenter.addObserver(forName: NSNotification.Name(rawValue: NOTIFY_ADV_CONF_CHANGED), object: nil, queue: nil
            , using: {
                (note) in
                SyncSSLocal()
                self.applyConfig()
            }
        )
        notifyCenter.addObserver(forName: NSNotification.Name(rawValue: NOTIFY_HTTP_CONF_CHANGED), object: nil, queue: nil
            , using: {
                (note) in
                SyncPrivoxy()
                self.applyConfig()
            }
        )
        notifyCenter.addObserver(forName: NSNotification.Name(rawValue: "NOTIFY_FOUND_SS_URL"), object: nil, queue: nil) {
            (note: Notification) in
            if let userInfo = (note as NSNotification).userInfo {
                let urls: [URL] = userInfo["urls"] as! [URL]

                let mgr = ServerProfileManager.instance
                var isChanged = false

                for url in urls {
                    let profielDict = parseAppURLSchemes(url)//ParseSSURL(url)
                    if let profielDict = profielDict {
                        let profile = ServerProfile.fromDictionary(profielDict as [String: AnyObject])
                        mgr.profiles.append(profile)
                        isChanged = true

                        let userNote = NSUserNotification()
                        userNote.title = "Add Shadowsocks Server Profile".localized
                        if userInfo["source"] as! String == "qrcode" {
                            userNote.subtitle = "By scan QR Code".localized
                        } else if userInfo["source"] as! String == "url" {
                            userNote.subtitle = "By Handle SS URL".localized
                        }
                        userNote.informativeText = "Host: \(profile.serverHost)\n Port: \(profile.serverPort)\n Encription Method: \(profile.method)".localized
                        userNote.soundName = NSUserNotificationDefaultSoundName

                        NSUserNotificationCenter.default
                            .deliver(userNote);
                    } else {
                        let userNote = NSUserNotification()
                        userNote.title = "Failed to Add Server Profile".localized
                        userNote.subtitle = "Address can not be recognized".localized
                        NSUserNotificationCenter.default
                            .deliver(userNote);
                    }
                }

                if isChanged {
                    mgr.save()
                    self.updateServersMenu()
                }
            }
        }

        // Handle ss url scheme
        NSAppleEventManager.shared().setEventHandler(self
            , andSelector: #selector(self.handleURLEvent)
            , forEventClass: AEEventClass(kInternetEventClass), andEventID: AEEventID(kAEGetURL))

        updateMainMenu()
        updateServersMenu()
        updateRunningModeMenu()
        updateLaunchAtLoginMenu()

        proxyConfHelper.install()
        applyConfig()
//        SyncSSLocal()

        if defaults.bool(forKey: "ConnectAtLaunch") && ServerProfileManager.instance.getActiveProfileId() != "" {
            defaults.set(false, forKey: "ShadowsocksOn")
            toggleRunning(toggleRunningMenuItem)
        }

        DispatchQueue.global().async {
            // Version Check!
            if defaults.bool(forKey: "AutoCheckUpdate") {
                // 如果用户设置了打开时检查更新，那么只在有更新时才提示
                self.checkForUpdate(mustShowAlert: false)
            }
            if defaults.bool(forKey: "AutoUpdateSubscribe") {
                SubscribeManager.instance.updateAllServerFromSubscribe()
            }
            DispatchQueue.main.async {

            }
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        StopSSLocal()
        StopPrivoxy()
        proxyConfHelper.disableProxy("hi")
        let defaults = UserDefaults.standard
        defaults.set(false, forKey: "ShadowsocksOn")
        proxyConfHelper.stopPACServer()
    }

    func applyConfig() {
        let defaults = UserDefaults.standard
        let isOn = defaults.bool(forKey: "ShadowsocksOn")
        let mode = defaults.string(forKey: "ShadowsocksRunningMode")

        if isOn {
            StartSSLocal()
            StartPrivoxy()
            if mode == "auto" {
                proxyConfHelper.disableProxy("hi")
                proxyConfHelper.enablePACProxy("hi")
            } else if mode == "global" {
                proxyConfHelper.disableProxy("hi")
                proxyConfHelper.enableGlobalProxy()
            } else if mode == "manual" {
                proxyConfHelper.disableProxy("hi")
                proxyConfHelper.disableProxy("hi")
            } else if mode == "whiteList" {
                proxyConfHelper.disableProxy("hi")
                proxyConfHelper.enableWhiteListProxy()//新白名单基于GlobalMode
            }
        } else {
            StopSSLocal()
            StopPrivoxy()
            proxyConfHelper.disableProxy("hi")
        }

    }

    // MARK: Mainmenu functions

    @IBAction func toggleRunning(_ sender: NSMenuItem) {
        let defaults = UserDefaults.standard
        defaults.set(!defaults.bool(forKey: "ShadowsocksOn"), forKey: "ShadowsocksOn")

        updateMainMenu()
        SyncSSLocal()
        applyConfig()
    }

    @IBAction func updateGFWList(_ sender: NSMenuItem) {
        UpdatePACFromGFWList()
    }

    @IBAction func updateWhiteList(_ sender: NSMenuItem) {
        UpdateACL()
    }

    @IBAction func editUserRulesForPAC(_ sender: NSMenuItem) {
        if editUserRulesWinCtrl != nil {
            editUserRulesWinCtrl.close()
        }
        let ctrl = UserRulesController(windowNibName: NSNib.Name("UserRulesController"))
        editUserRulesWinCtrl = ctrl

        ctrl.showWindow(self)
        NSApp.activate(ignoringOtherApps: true)
        ctrl.window?.makeKeyAndOrderFront(self)
    }

    @IBAction func editSubscribeFeed(_ sender: NSMenuItem) {
        if subscribePreferenceWinCtrl != nil {
            subscribePreferenceWinCtrl.close()
        }
        let ctrl = SubscribePreferenceWindowController(windowNibName: NSNib.Name("SubscribePreferenceWindowController"))
        subscribePreferenceWinCtrl = ctrl

        ctrl.showWindow(self)
        NSApp.activate(ignoringOtherApps: true)
        ctrl.window?.makeKeyAndOrderFront(self)
    }

    @IBAction func toggleLaunghAtLogin(_ sender: NSMenuItem) {
        LaunchAtLogin.isEnabled = (sender.state == .off)
        updateLaunchAtLoginMenu()
    }

    @IBAction func toggleConnectAtLaunch(_ sender: NSMenuItem) {
        let defaults = UserDefaults.standard
        defaults.set(!defaults.bool(forKey: "ConnectAtLaunch"), forKey: "ConnectAtLaunch")
        updateMainMenu()
    }

    // MARK: Server submenu function

    @IBAction func showQRCodeForCurrentServer(_ sender: NSMenuItem) {
        var errMsg: String?
        if let profile = ServerProfileManager.instance.getActiveProfile() {
            if profile.isValid() {
                // Show window
                if qrcodeWinCtrl != nil {
                    qrcodeWinCtrl.close()
                }
                qrcodeWinCtrl = SWBQRCodeWindowController(windowNibName: NSNib.Name("SWBQRCodeWindowController"))
                qrcodeWinCtrl.qrCode = profile.URL()!.absoluteString
                qrcodeWinCtrl.title = profile.title()
                DispatchQueue.main.async {
                    self.qrcodeWinCtrl.showWindow(self)
                    NSApp.activate(ignoringOtherApps: true)
                    self.qrcodeWinCtrl.window?.makeKeyAndOrderFront(nil)
                }
                return
            } else {
                errMsg = "Current server profile is not valid.".localized
            }
        } else {
            errMsg = "No current server profile.".localized
        }
        let userNote = NSUserNotification()
        userNote.title = errMsg
        userNote.soundName = NSUserNotificationDefaultSoundName

        NSUserNotificationCenter.default
            .deliver(userNote);
    }

    @IBAction func scanQRCodeFromScreen(_ sender: NSMenuItem) {
        scanQRCodeOnScreen()
    }

    @IBAction func showBunchJsonExampleFile(_ sender: NSMenuItem) {
        ServerProfileManager.showExampleConfigFile()
    }

    @IBAction func importBunchJsonFile(_ sender: NSMenuItem) {
        ServerProfileManager.instance.importConfigFile()
        //updateServersMenu()//not working
    }

    @IBAction func exportAllServerProfile(_ sender: NSMenuItem) {
        ServerProfileManager.instance.exportConfigFile()
    }

    @IBAction func updateSubscribe(_ sender: NSMenuItem) {
        SubscribeManager.instance.updateAllServerFromSubscribe()
    }

    @IBAction func updateSubscribeAtLaunch(_ sender: NSMenuItem) {
        let defaults = UserDefaults.standard
        defaults.set(!defaults.bool(forKey: "AutoUpdateSubscribe"), forKey: "AutoUpdateSubscribe")
        updateSubscribeAtLaunchMenuItem.state = defaults.bool(forKey: "AutoUpdateSubscribe") ? NSControl.StateValue(rawValue: 1) : NSControl.StateValue(rawValue: 0)
    }


    // MARK: Proxy submenu function

    @IBAction func selectPACMode(_ sender: NSMenuItem) {
        let defaults = UserDefaults.standard
        defaults.setValue("auto", forKey: "ShadowsocksRunningMode")
        defaults.setValue("", forKey: "ACLFileName")
        updateRunningModeMenu()
        SyncSSLocal()
        applyConfig()
    }

    @IBAction func selectGlobalMode(_ sender: NSMenuItem) {
        let defaults = UserDefaults.standard
        defaults.setValue("global", forKey: "ShadowsocksRunningMode")
        defaults.setValue("", forKey: "ACLFileName")
        updateRunningModeMenu()
        SyncSSLocal()
        applyConfig()
    }

    @IBAction func selectManualMode(_ sender: NSMenuItem) {
        let defaults = UserDefaults.standard
        defaults.setValue("manual", forKey: "ShadowsocksRunningMode")
        defaults.setValue("", forKey: "ACLFileName")
        updateRunningModeMenu()
        SyncSSLocal()
        applyConfig()
    }
    @IBAction func selectACLAutoMode(_ sender: NSMenuItem) {
        let defaults = UserDefaults.standard
        defaults.setValue("whiteList", forKey: "ShadowsocksRunningMode")
        defaults.setValue("gfwlist.acl", forKey: "ACLFileName")
        updateRunningModeMenu()
        SyncSSLocal()
        applyConfig()
    }
    @IBAction func selectACLBackCHNMode(_ sender: NSMenuItem) {
        let defaults = UserDefaults.standard
        defaults.setValue("whiteList", forKey: "ShadowsocksRunningMode")
        defaults.setValue("backchn.acl", forKey: "ACLFileName")
        updateRunningModeMenu()
        SyncSSLocal()
        applyConfig()
    }
    @IBAction func selectWhiteListMode(_ sender: NSMenuItem) {
        let defaults = UserDefaults.standard
        defaults.setValue("whiteList", forKey: "ShadowsocksRunningMode")
        defaults.setValue("chn.acl", forKey: "ACLFileName")
        updateRunningModeMenu()
        SyncSSLocal()
        applyConfig()
    }

    @IBAction func editServerPreferences(_ sender: NSMenuItem) {
        if preferencesWinCtrl != nil {
            preferencesWinCtrl.close()
        }
        let ctrl = PreferencesWindowController(windowNibName: NSNib.Name("PreferencesWindowController"))
        preferencesWinCtrl = ctrl

        ctrl.showWindow(self)
        NSApp.activate(ignoringOtherApps: true)
        ctrl.window?.makeKeyAndOrderFront(self)
    }

    @IBAction func editAdvPreferences(_ sender: NSMenuItem) {
        if advPreferencesWinCtrl != nil {
            advPreferencesWinCtrl.close()
        }
        let ctrl = AdvPreferencesWindowController(windowNibName: NSNib.Name("AdvPreferencesWindowController"))
        advPreferencesWinCtrl = ctrl

        ctrl.showWindow(self)
        NSApp.activate(ignoringOtherApps: true)
        ctrl.window?.makeKeyAndOrderFront(self)
    }

    @IBAction func editHTTPPreferences(_ sender: NSMenuItem) {
        if httpPreferencesWinCtrl != nil {
            httpPreferencesWinCtrl.close()
        }
        let ctrl = HTTPPreferencesWindowController(windowNibName: NSNib.Name("HTTPPreferencesWindowController"))
        httpPreferencesWinCtrl = ctrl

        ctrl.showWindow(self)
        NSApp.activate(ignoringOtherApps: true)
        ctrl.window?.makeKeyAndOrderFront(self)
    }

    @IBAction func editProxyPreferences(_ sender: NSObject) {
        if proxyPreferencesWinCtrl != nil {
            proxyPreferencesWinCtrl.close()
        }
        proxyPreferencesWinCtrl = ProxyPreferencesController(windowNibName: NSNib.Name("ProxyPreferencesController"))
        proxyPreferencesWinCtrl.showWindow(self)
        NSApp.activate(ignoringOtherApps: true)
        proxyPreferencesWinCtrl.window?.makeKeyAndOrderFront(self)
    }

    @IBAction func selectServer(_ sender: NSMenuItem) {
        let index = sender.tag
        let spMgr = ServerProfileManager.instance
        let newProfile = spMgr.profiles[index]
        if newProfile.uuid != spMgr.getActiveProfileId() {
            spMgr.setActiveProfiledId(newProfile.uuid)
            updateServersMenu()
            SyncSSLocal()
        }
        updateRunningModeMenu()
    }

    @IBAction func doPingTest(_ sender: AnyObject) {
        PingServers.instance.ping()
    }

//    @IBAction func showSpeedTap(_ sender: NSMenuItem) {
//        let defaults = UserDefaults.standard
//        var enable = defaults.bool(forKey: "enable_showSpeed")
//        enable = !enable
//        setSpeedStatusItem(enable)
//        defaults.set(enable, forKey: "enable_showSpeed")
//        updateMainMenu()
//    }

    @IBAction func showLogs(_ sender: NSMenuItem) {
        // 在控制台打开日志
        NSWorkspace.shared.openFile(NSHomeDirectory() + "/Library/Logs/ss-local.log", withApplication: "Console")
    }

    @IBAction func feedback(_ sender: NSMenuItem) {
        NSWorkspace.shared.open(URL(string: "https://github.com/jack80342/ShadowsocksX-NG/issues")!)
    }

    @IBAction func checkForUpdate(_ sender: NSMenuItem) {
        // 用户手动点击检查更新，那么必须显示提示
        checkForUpdate(mustShowAlert: true)
    }

    @IBAction func checkUpdatesAtLaunch(_ sender: NSMenuItem) {
        let defaults = UserDefaults.standard
        defaults.set(!defaults.bool(forKey: "AutoCheckUpdate"), forKey: "AutoCheckUpdate")
        checkUpdateAtLaunchMenuItem.state = defaults.bool(forKey: "AutoCheckUpdate") ? NSControl.StateValue(rawValue: 1) : NSControl.StateValue(rawValue: 0)
    }

    @IBAction func showAbout(_ sender: NSMenuItem) {
        NSApp.orderFrontStandardAboutPanel(sender);
        NSApp.activate(ignoringOtherApps: true)
    }

    func updateLaunchAtLoginMenu() {
        lanchAtLoginMenuItem.state = LaunchAtLogin.isEnabled ? NSControl.StateValue(rawValue: 1) : NSControl.StateValue(rawValue: 0)
    }

    // MARK: this function is use to update menu bar

    func updateRunningModeMenu() {
        let defaults = UserDefaults.standard
        let mode = defaults.string(forKey: "ShadowsocksRunningMode")
        var serverMenuText = "Servers".localized

        let mgr = ServerProfileManager.instance
        for p in mgr.profiles {
            if mgr.getActiveProfileId() == p.uuid {
                if !p.remark.isEmpty {
                    serverMenuText = p.remark
                } else {
                    serverMenuText = p.serverHost
                }
                if let latency = p.latency {
                    serverMenuText += "  - \(latency) ms"
                }
                else {
                    if !neverSpeedTestBefore {
                        serverMenuText += "  - failed"
                    }
                }
            }
        }

        serversMenuItem.title = serverMenuText
        autoModeMenuItem.state = NSControl.StateValue(rawValue: 0)
        globalModeMenuItem.state = NSControl.StateValue(rawValue: 0)
        manualModeMenuItem.state = NSControl.StateValue(rawValue: 0)
        whiteListModeMenuItem.state = NSControl.StateValue(rawValue: 0)
        ACLBackChinaMenuItem.state = NSControl.StateValue(rawValue: 0)
        ACLAutoModeMenuItem.state = NSControl.StateValue(rawValue: 0)
        ACLModeMenuItem.state = NSControl.StateValue(rawValue: 0)
        if mode == "auto" {
            autoModeMenuItem.state = NSControl.StateValue(rawValue: 1)
        } else if mode == "global" {
            globalModeMenuItem.state = NSControl.StateValue(rawValue: 1)
        } else if mode == "manual" {
            manualModeMenuItem.state = NSControl.StateValue(rawValue: 1)
        } else if mode == "whiteList" {
            let aclMode = defaults.string(forKey: "ACLFileName")!
            switch aclMode {
            case "backchn.acl":
                ACLModeMenuItem.state = NSControl.StateValue(rawValue: 1)
                ACLBackChinaMenuItem.state = NSControl.StateValue(rawValue: 1)
                ACLModeMenuItem.title = "Proxy Back China".localized
                break
            case "gfwlist.acl":
                ACLModeMenuItem.state = NSControl.StateValue(rawValue: 1)
                ACLAutoModeMenuItem.state = NSControl.StateValue(rawValue: 1)
                ACLModeMenuItem.title = "ACL Auto".localized
                break
            default:
                whiteListModeMenuItem.state = NSControl.StateValue(rawValue: 1)
            }
        }
        updateStatusItemUI()
    }

    func updateStatusItemUI() {
        if !UserDefaults.standard.bool(forKey: "ShadowsocksOn") {
            return
        }

        var image = NSImage()
        let iconImageName = IconUtils.getIconImageName();
        if(iconImageName != "") {
            image = NSImage(named: NSImage.Name(iconImageName))!
        }
        image.isTemplate = true
        statusItem!.button?.image = image

//        if(statusItem!.view != nil) {
//            statusItem!.length = 85
//            statusItemView = StatusItemView(statusItem: statusItem!, menu: statusMenu)
//            statusItem!.view = statusItemView
//
//            speedMonitor?.stop()
//            speedMonitor = NetWorkMonitor(statusItemView: statusItemView!)
//            speedMonitor?.start()
//        }
    }

    func updateMainMenu() {
        let defaults = UserDefaults.standard
        let isOn = defaults.bool(forKey: "ShadowsocksOn")
        var image = NSImage()
        if isOn {
            runningStatusMenuItem.title = "Shadowsocks: On".localized
            toggleRunningMenuItem.title = "Turn Shadowsocks Off".localized
            //image = NSImage(named: "menu_icon")!
            updateStatusItemUI()
        } else {
            runningStatusMenuItem.title = "Shadowsocks: Off".localized
            toggleRunningMenuItem.title = "Turn Shadowsocks On".localized
            image = NSImage(named: NSImage.Name("menu_icon_disabled"))!
            image.isTemplate = true
            statusItem!.button?.image = image
        }

//        ShowNetworkSpeedItem.state = defaults.bool(forKey: "enable_showSpeed") ? NSControl.StateValue(rawValue: 1) : NSControl.StateValue(rawValue: 0)
        connectAtLaunchMenuItem.state = defaults.bool(forKey: "ConnectAtLaunch") ? NSControl.StateValue(rawValue: 1) : NSControl.StateValue(rawValue: 0)
        checkUpdateAtLaunchMenuItem.state = defaults.bool(forKey: "AutoCheckUpdate") ? NSControl.StateValue(rawValue: 1) : NSControl.StateValue(rawValue: 0)
    }

    func updateServersMenu() {
        let mgr = ServerProfileManager.instance
        serversMenuItem.submenu?.removeAllItems()
        let showQRItem = showQRCodeMenuItem
        let scanQRItem = scanQRCodeMenuItem
        let preferencesItem = serversPreferencesMenuItem
        let showBunch = showBunchJsonExampleFileItem
        let importBuntch = importBunchJsonFileItem
        let exportAllServer = exportAllServerProfileItem
        let updateSubscribeItem = manualUpdateSubscribeMenuItem
        let autoUpdateSubscribeItem = updateSubscribeAtLaunchMenuItem
        let editSubscribeItem = editSubscribeMenuItem
//        let pingItem = pingserverMenuItem

        var i = 0
        for p in mgr.profiles {
            let item = NSMenuItem()
            item.tag = i //+ kProfileMenuItemIndexBase
            item.title = p.title()
            if let latency = p.latency {
                item.title += "  - \(latency) ms"
            } else {
                if !neverSpeedTestBefore {
                    item.title += "  - failed"
                }
            }
            if mgr.getActiveProfileId() == p.uuid {
                item.state = NSControl.StateValue(rawValue: 1)
            }
            if !p.isValid() {
                item.isEnabled = false
            }

            item.action = #selector(AppDelegate.selectServer)

            if !p.ssrGroup.isEmpty {
                if((serversMenuItem.submenu?.item(withTitle: p.ssrGroup)) == nil) {
                    let groupSubmenu = NSMenu()
                    let groupSubmenuItem = NSMenuItem()
                    groupSubmenuItem.title = p.ssrGroup
                    serversMenuItem.submenu?.addItem(groupSubmenuItem)
                    serversMenuItem.submenu?.setSubmenu(groupSubmenu, for: groupSubmenuItem)
                    if mgr.getActiveProfileId() == p.uuid {
                        item.state = NSControl.StateValue(rawValue: 1)
                        groupSubmenuItem.state = NSControl.StateValue(rawValue: 1)
                    }
                    groupSubmenuItem.submenu?.addItem(item)
                    i += 1
                    continue
                }
                else {
                    if mgr.getActiveProfileId() == p.uuid {
                        item.state = NSControl.StateValue(rawValue: 1)
                        serversMenuItem.submenu?.item(withTitle: p.ssrGroup)?.state = NSControl.StateValue(rawValue: 1)
                    }
                    serversMenuItem.submenu?.item(withTitle: p.ssrGroup)?.submenu?.addItem(item)
                    i += 1
                    continue
                }
            }

            serversMenuItem.submenu?.addItem(item)
            i += 1
        }
        if !mgr.profiles.isEmpty {
            serversMenuItem.submenu?.addItem(NSMenuItem.separator())
        }
        serversMenuItem.submenu?.addItem(editSubscribeItem!)
        serversMenuItem.submenu?.addItem(autoUpdateSubscribeItem!)
        autoUpdateSubscribeItem?.state = UserDefaults.standard.bool(forKey: "AutoUpdateSubscribe") ? NSControl.StateValue(rawValue: 1) : NSControl.StateValue(rawValue: 0)
        serversMenuItem.submenu?.addItem(updateSubscribeItem!)
        serversMenuItem.submenu?.addItem(showQRItem!)
        serversMenuItem.submenu?.addItem(scanQRItem!)
        serversMenuItem.submenu?.addItem(showBunch!)
        serversMenuItem.submenu?.addItem(importBuntch!)
        serversMenuItem.submenu?.addItem(exportAllServer!)
        serversMenuItem.submenu?.addItem(NSMenuItem.separator())
        serversMenuItem.submenu?.addItem(preferencesItem!)
//        serversMenuItem.submenu?.addItem(pingItem)

    }

//    func setSpeedStatusItem(_ showSpeed: Bool) {
//        // should not operate the system status bar
//        // we can add sub menu like bittorrent sync
//        if(statusItem == nil) {
//            statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
//            let image = NSImage(named: NSImage.Name("menu_icon"))
//            image!.isTemplate = true
//            statusItem!.button?.image = image
//            statusItem!.menu = statusMenu
//        }
//
//        if showSpeed {
//            statusItem!.length = 85
//            statusItemView = StatusItemView(statusItem: statusItem!, menu: statusMenu)
//            statusItem!.view = statusItemView
//
//            if speedMonitor == nil {
//                speedMonitor = NetWorkMonitor(statusItemView: statusItemView!)
//            }
//            speedMonitor?.start()
//        } else {
//            statusItem!.length = 20
//            statusItem!.view = nil
//
//            speedMonitor?.stop()
//            speedMonitor = nil
//        }
//    }

    func checkForUpdate(mustShowAlert: Bool) -> Void {
        let versionChecker = VersionChecker()
        DispatchQueue.global().async {
            versionChecker.checkNewVersion(callback: { newVersion in
                DispatchQueue.main.async {
                    if (mustShowAlert || newVersion["newVersion"] as! Bool) {
                        let alertResult = versionChecker.showAlertView(Title: newVersion["Title"] as! String, SubTitle: newVersion["SubTitle"] as! String, ConfirmBtn: newVersion["ConfirmBtn"] as! String, CancelBtn: newVersion["CancelBtn"] as! String)
                        print(alertResult)
                        if (newVersion["newVersion"] as! Bool && alertResult == 1000) {
                            NSWorkspace.shared.open(URL(string: "https://github.com/jack80342/ShadowsocksX-NG/releases")!)
                        }
                    }
                }
            })
        }
    }

    // MARK:

    @objc func handleURLEvent(_ event: NSAppleEventDescriptor, withReplyEvent replyEvent: NSAppleEventDescriptor) {
        if let urlString = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue {
            if URL(string: urlString) != nil {
                NotificationCenter.default.post(
                    name: Notification.Name(rawValue: "NOTIFY_FOUND_SS_URL"), object: nil
                    , userInfo: [
                        "urls": splitProfile(url: urlString, max: 5).map({ (item: String) -> URL in
                            return URL(string: item)!
                        }),
                        "source": "url",
                    ])
            }
        }
    }

    //------------------------------------------------------------
    // MARK: NSUserNotificationCenterDelegate

    func userNotificationCenter(_ center: NSUserNotificationCenter
        , shouldPresent notification: NSUserNotification) -> Bool {
        return true
    }
}

