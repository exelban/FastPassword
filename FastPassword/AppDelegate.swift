//
//  AppDelegate.swift
//  FastPassword
//
//  Created by Serhiy Mytrovtsiy on 05/09/2021.
//  Using Swift 5.0.
//  Running on macOS 10.15.
//
//  Copyright © 2021 Serhiy Mytrovtsiy. All rights reserved.
//

import Cocoa
import Updater

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    private let window: Window = Window()
    private var menuBarItem: MenuBar = MenuBar()
    
    private let isAppStoreBuild: Bool = false
    
    private let updater = Updater(
        name: "FastPassword",
        providers: [
            Updater.Github(user: "exelban", repo: "FastPassword", asset: "FastPassword.dmg")
        ]
    )
    
    static func main() {
        let delegate = AppDelegate()
        let menu = AppMenu()
        NSApplication.shared.mainMenu = menu
        NSApplication.shared.delegate = delegate
        NSApplication.shared.run()
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let startingPoint = Date()
        
        if !self.isAppStoreBuild {
            if !Store.shared.exist(key: "runAtLoginInitialized") {
                Store.shared.set(key: "runAtLoginInitialized", value: true)
                LaunchAtLogin.isEnabled = true
            }
            
            self.checkForNewVersion()
        }
        
        print("FastPassword started in \((startingPoint.timeIntervalSinceNow * -1).rounded(toPlaces: 4)) seconds")
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if flag {
            self.window.makeKeyAndOrderFront(self)
        } else {
            self.window.setIsVisible(true)
        }
        NSApp.setActivationPolicy(.regular)
        
        return true
    }
    
    private func checkForNewVersion() {
        self.updater.check() { result, error in
            if error != nil {
                print("error updater.check(): %s", "\(error!)")
                return
            }
            
            guard let external = result else {
                print("no external release found")
                return
            }
            let local = Updater.Tag("v\(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String)")
            
            if local >= external.tag {
                return
            }
            
            DispatchQueue.main.async(execute: {
                print("show update window because new version of app found: %s", "\(external.tag.raw)")
                
                let alert = NSAlert()
                alert.messageText = "New version available"
                alert.informativeText = "Current version:   \(local.raw)\nLatest version:     \(external.tag.raw)"
                alert.alertStyle = .warning
                alert.addButton(withTitle: "Install")
                alert.addButton(withTitle: "Cancel")
                
                if alert.runModal() == .alertFirstButtonReturn {
                    if let url = URL(string: external.url) {
                        self.updater.download(url, done: { path in
                            self.updater.install(path: path)
                        })
                    }
                }
            })
        }
    }
}

private class Window: NSWindow, NSWindowDelegate {
    private let main: MainView = MainView(isPopup: false)
    private let vc: NSViewController = NSViewController(nibName: nil, bundle: nil)
    
    private var windowOnStart: Bool = Store.shared.bool(key: "windowOnStart", defaultValue: false)
    
    init() {
        let view: NSView = NSView(frame: NSRect(x: 0, y: 0, width: self.main.frame.width, height: self.main.frame.height+22))
        
        let background = NSVisualEffectView(frame: NSRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height))
        background.material = .sidebar
        background.blendingMode = .behindWindow
        background.state = .active
        
        view.addSubview(background)
        view.addSubview(self.main)
        
        self.vc.view = view
        
        super.init(
            contentRect: NSRect(
                x: NSScreen.main!.frame.width - self.vc.view.frame.width,
                y: NSScreen.main!.frame.height - self.vc.view.frame.height,
                width: self.vc.view.frame.width,
                height: self.vc.view.frame.height
            ),
            styleMask: [.closable, .titled, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        self.contentViewController = self.vc
        self.animationBehavior = .default
        self.collectionBehavior = .moveToActiveSpace
        self.titlebarAppearsTransparent = true
        self.center()
        self.setIsVisible(self.windowOnStart)
        self.delegate = self
        
        let windowController = NSWindowController()
        windowController.window = self
        windowController.loadWindow()
        
        if self.windowOnStart {
            NSApp.setActivationPolicy(.regular)
            self.makeKeyAndOrderFront(nil)
        }
        
        self.main.heightCallback = { [weak self] value in
            guard let width = self?.frame.width else {
                return
            }
            
            background.setFrameSize(NSSize(width: width, height: value+22))
            self?.setContentSize(NSSize(width: width, height: value+22))
        }
    }
    
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if event.type == NSEvent.EventType.keyDown && event.modifierFlags.contains(.command) {
            if event.keyCode == 12 || event.keyCode == 13 {
                self.setIsVisible(false)
                return true
            } else if event.keyCode == 46 {
                self.miniaturize(event)
                return true
            }
        }
        
        return super.performKeyEquivalent(with: event)
    }
    
    func windowWillClose(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.accessory)
    }
}

private class MenuBar {
    private let main: MainView = MainView(isPopup: true)
    private var item: NSStatusItem
    private let popover = NSPopover()
    
    init() {
        let systemHeight = NSApplication.shared.mainMenu?.menuBarHeight ?? 22
        
        self.item = NSStatusBar.system.statusItem(withLength: systemHeight)
        self.item.autosaveName = Bundle.main.bundleIdentifier
        
        if let button = self.item.button {
            button.image = NSImage(named: NSImage.Name("icon"))
            button.imageScaling = .scaleNone
            button.target = self
            button.sendAction(on: [.leftMouseDown, .rightMouseDown])
            button.action = #selector(self.togglePopover)
        }
        
        let vc: NSViewController = NSViewController(nibName: nil, bundle: nil)
        let view = NSView(frame: NSRect(x: 0, y: 0, width: self.main.frame.width, height: self.main.frame.height+12))
        view.addSubview(self.main)
        vc.view = view
        
        self.popover.animates = false
        self.popover.behavior = .transient
        self.popover.contentViewController = vc
        
        self.main.heightCallback = { [weak self] value in
            guard let width = self?.main.frame.width else {
                return
            }
            self?.popover.contentSize = CGSize(width: width, height: value+12)
        }
    }
    
    @objc private func togglePopover(sender: Any) {
        if self.popover.isShown {
            self.popover.performClose(sender)
        } else {
            if let button = self.item.button {
                self.popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
            }
        }
    }
}

class AppMenu: NSMenu {
    private lazy var applicationName = ProcessInfo.processInfo.processName
    
    override init(title: String) {
        super.init(title: title)
        
        let mainMenu = NSMenuItem()
        mainMenu.submenu = NSMenu(title: "MainMenu")
        mainMenu.submenu?.items = [
            NSMenuItem(title: "About \(applicationName)", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: ""),
            NSMenuItem.separator(),
            NSMenuItem(title: "Quit \(applicationName)", action: #selector(NSApplication.shared.terminate(_:)), keyEquivalent: "q")
        ]
        items = [mainMenu]
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
    }
}
