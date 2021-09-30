//
//  view.swift
//  FastPassword
//
//  Created by Serhiy Mytrovtsiy on 05/09/2021.
//  Using Swift 5.0.
//  Running on macOS 10.15.
//
//  Copyright © 2021 Serhiy Mytrovtsiy. All rights reserved.
//

import Cocoa

internal class MainView: NSStackView {
    public var heightCallback: (_: CGFloat) -> Void = {_ in }
    
    private let size: CGSize = CGSize(width: 280, height: 120)
    private let navHeight: CGFloat = 30
    
    private var generator: NSView!
    private var settings: NSView!
    
    private var button: NSButton?
    
    init(isPopup: Bool) {
        super.init(frame: NSRect(x: 0, y: 0, width: self.size.width+20, height: self.size.height+5))
        
        self.edgeInsets = NSEdgeInsets(top: 0, left: 10, bottom: 5, right: 10)
        self.orientation = .vertical
        self.spacing = 0
        
        let body: NSView = NSView(frame: NSRect(x: 0, y: 0, width: self.size.width, height: self.size.height - self.navHeight))
        body.widthAnchor.constraint(equalToConstant: body.bounds.width).isActive = true
        
        self.generator = GeneratorView(frame: NSRect(x: 0, y: 0, width: body.frame.width, height: body.frame.height))
        self.settings = SettingsView(width: body.frame.width)
        
        body.addSubview(self.generator)
        body.addSubview(self.settings)
        
        self.addArrangedSubview(body)
        self.addArrangedSubview(NSView())
        self.addArrangedSubview(self.nav(isPopup))
        
        body.heightAnchor.constraint(equalTo: self.heightAnchor, constant: -self.navHeight-5).isActive = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func nav(_ isPopup: Bool) -> NSView {
        let view: NSStackView = NSStackView(frame: NSRect(x: 0, y: 0, width: self.size.width, height: self.navHeight))
        view.widthAnchor.constraint(equalToConstant: view.bounds.width).isActive = true
        view.heightAnchor.constraint(equalToConstant: view.bounds.height).isActive = true
        view.orientation = .horizontal
        view.distribution = .equalCentering
        view.spacing = 0
        
        let settingsButton = IconButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30), title: "Settings", icon: "settings")
        settingsButton.target = self
        settingsButton.action = #selector(self.toggleSettings)
        self.button = settingsButton
        
        var exitButton: NSView = NSView()
        if isPopup {
            let btn = IconButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30), title: "Close app", icon: "power")
            btn.target = self
            btn.action = #selector(self.closeApp)
            exitButton = btn
        }
        
        view.addArrangedSubview(settingsButton)
        view.addArrangedSubview(exitButton)
        
        return view
    }
    
    @objc private func toggleSettings(sender: Any) {
        if self.generator.isHidden {
            self.hideSettings()
        } else {
            self.showSettings()
        }
    }
    
    private func showSettings() {
        self.generator.isHidden = true
        self.settings.isHidden = false
        self.button?.image = Bundle(for: type(of: self)).image(forResource: "close")!
        self.setHeight(self.settings.frame.height + self.navHeight + 5)
    }
    
    private func hideSettings() {
        self.generator.isHidden = false
        self.settings.isHidden = true
        self.button?.image = Bundle(for: type(of: self)).image(forResource: "settings")!
        self.setHeight(self.size.height+5)
    }
    
    private func setHeight(_ value: CGFloat) {
        self.setFrameSize(NSSize(width: self.frame.width, height: value))
        self.heightCallback(value)
    }
    
    @objc private func closeApp(sender: Any) {
        NSApp.terminate(sender)
    }
}

// MARK: - GeneratorView

private class GeneratorView: NSView {
    override init(frame: NSRect) {
        super.init(frame: frame)
        
        let inner: NSStackView = NSStackView(frame: NSRect(x: 0, y: 5, width: self.frame.width, height: 60))
        inner.orientation = .vertical
        inner.spacing = 0
        
        let field: NSTextView = ValueField(frame: NSRect(x: 0, y: 0, width: inner.frame.width, height: 30))
        field.textContainerInset = NSSize(width: 6, height: 8)
        
        let button: NSButton = NSButton(frame: NSRect(x: 0, y: 0, width: 100, height: 30))
        button.title = "Generate"
        button.bezelStyle = .rounded
        button.target = self
        button.action = #selector(self.generate)
        
        inner.addArrangedSubview(field)
        inner.addArrangedSubview(button)
        
        NSLayoutConstraint.activate([
            inner.widthAnchor.constraint(equalToConstant: inner.frame.width),
            inner.heightAnchor.constraint(equalToConstant: inner.frame.height),
            field.widthAnchor.constraint(equalToConstant: field.frame.width),
            field.heightAnchor.constraint(equalToConstant: field.frame.height),
            button.widthAnchor.constraint(equalToConstant: button.frame.width),
            button.heightAnchor.constraint(equalToConstant: button.frame.height)
        ])
        
        self.addSubview(inner)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func generate(sender: Any) {
        NotificationCenter.default.post(name: .update, object: nil, userInfo: ["value": Generator.shared.new()])
    }
}

private class ValueField: NSTextView {
    @objc var placeholderAttributedString: NSAttributedString? = NSAttributedString(
        string: "Generate new password...",
        attributes: [
            NSAttributedString.Key.foregroundColor: NSColor.secondaryLabelColor
        ]
    )
    
    override init(frame: NSRect) {
        let textContainer = NSTextContainer(size: NSSize(width: frame.size.width-6, height: frame.size.height))
        textContainer.lineBreakMode = .byTruncatingTail
        textContainer.maximumNumberOfLines = 1
        
        let layoutManager = NSLayoutManager()
        layoutManager.addTextContainer(textContainer)
        layoutManager.usesFontLeading = true
        
        let storage = NSTextStorage()
        storage.addLayoutManager(layoutManager)
        
        super.init(frame: frame, textContainer: textContainer)
        
        self.toolTip = "Click to copy"
        self.isEditable = false
        self.alignment = .center
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateValue), name: .update, object: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if event.type == NSEvent.EventType.keyDown && event.modifierFlags.contains(.command) {
            if event.charactersIgnoringModifiers == "c" {
                self.copyValue()
                return true
            }
        }
        return super.performKeyEquivalent(with: event)
    }
    
    override func mouseDown(with theEvent: NSEvent) {
        super.mouseDown(with: theEvent)
        self.selectLine(self)
        self.copyValue()
    }
    
    private func copyValue() {
        NSApp.sendAction(#selector(NSText.copy(_:)), to: nil, from: self)
    }
    
    @objc private func updateValue(_ notification: Notification) {
        if let value = notification.userInfo?["value"] as? String {
            self.string = value
        }
    }
}

// MARK: - SettingsView

private class SettingsView: NSStackView {
    private let rowHeight: CGFloat = 30
    
    private var lengthBtn: NSPopUpButton?
    private var lowerBtn: NSButton?
    private var upperBtn: NSButton?
    private var numbersBtn: NSButton?
    private var symbolsBtn: NSButton?
    
    private var startAtLoginBtn: NSButton?
    private var windowOnStartBtn: NSButton?
    
    private var windowOnStart: Bool {
        get {
            return Store.shared.bool(key: "windowOnStart", defaultValue: false)
        }
        set {
            Store.shared.set(key: "windowOnStart", value: newValue)
        }
    }
    
    public init(width: CGFloat) {
        super.init(frame: NSRect(x: 0, y: 0, width: width, height: 0))
        
        self.isHidden = true
        self.spacing = 0
        self.orientation = .vertical
        
        let a = self.setView(title: "Lower case letters", action: #selector(self.toggleLowerCase), state: Generator.shared.lower)
        let b = self.setView(title: "Upper case letters", action: #selector(self.toggleUpperCase), state: Generator.shared.upper)
        let c = self.setView(title: "Numbers", action: #selector(self.toggleNumbers), state: Generator.shared.numbers)
        let d = self.setView(title: "Special symbols", action: #selector(self.toggleSymbols), state: Generator.shared.symbols)
        let e = self.setView(title: "Start at login", action: #selector(self.toggleStartAtLogin), state: LaunchAtLogin.isEnabled)
        let f = self.setView(title: "Show window on start", action: #selector(self.toggleWindowOnStart), state: self.windowOnStart)
        
        if let btn = a.subviews.last as? NSButton {
            self.lowerBtn = btn
        }
        if let btn = b.subviews.last as? NSButton {
            self.upperBtn = btn
        }
        if let btn = c.subviews.last as? NSButton {
            self.numbersBtn = btn
        }
        if let btn = d.subviews.last as? NSButton {
            self.symbolsBtn = btn
        }
        if let btn = e.subviews.last as? NSButton {
            self.startAtLoginBtn = btn
        }
        if let btn = f.subviews.last as? NSButton {
            self.windowOnStartBtn = btn
        }
        
        self.addArrangedSubview(self.title("Generator"))
        self.addArrangedSubview(self.row(views: [self.lengthSelector(), a, b, c, d]))
        
        self.addArrangedSubview(self.title("Application"))
        self.addArrangedSubview(self.row(views: [e, f]))
        
        let h = self.arrangedSubviews.map({ $0.bounds.height }).reduce(0, +)
        if self.frame.size.height != h {
            self.setFrameSize(NSSize(width: self.bounds.width, height: h))
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.watchForGeneratorSettings), name: .generator, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.watchForApplicationSettings), name: .application, object: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func application() -> NSView {
        let view: NSView = NSView(frame: NSRect(x: 0, y: 0, width: self.frame.width, height: self.rowHeight))
        view.widthAnchor.constraint(equalToConstant: view.bounds.width).isActive = true
        view.heightAnchor.constraint(equalToConstant: view.bounds.height).isActive = true
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.blue.cgColor
        
        return view
    }
    
    @objc private func updateLength(_ sender: NSMenuItem) {
        if let value = Int(sender.title) {
            NotificationCenter.default.post(name: .generator, object: nil, userInfo: ["param": "length", "value": value])
            Generator.shared.length = value
        }
    }
    @objc private func toggleLowerCase(sender: NSButton) {
        let state = sender.state == .on ? true : false
        NotificationCenter.default.post(name: .generator, object: nil, userInfo: ["param": "lower", "value": state])
        Generator.shared.lower = state
    }
    @objc private func toggleUpperCase(sender: NSButton) {
        let state = sender.state == .on ? true : false
        NotificationCenter.default.post(name: .generator, object: nil, userInfo: ["param": "upper", "value": state])
        Generator.shared.upper = state
    }
    @objc private func toggleNumbers(sender: NSButton) {
        let state = sender.state == .on ? true : false
        NotificationCenter.default.post(name: .generator, object: nil, userInfo: ["param": "numbers", "value": state])
        Generator.shared.numbers = state
    }
    @objc private func toggleSymbols(sender: NSButton) {
        let state = sender.state == .on ? true : false
        NotificationCenter.default.post(name: .generator, object: nil, userInfo: ["param": "symbols", "value": state])
        Generator.shared.symbols = state
    }
    
    @objc private func toggleStartAtLogin(sender: NSButton) {
        let state = sender.state == .on ? true : false
        NotificationCenter.default.post(name: .application, object: nil, userInfo: ["param": "startAtLogin", "value": state])
        
        LaunchAtLogin.isEnabled = state
        if !Store.shared.exist(key: "runAtLoginInitialized") {
            Store.shared.set(key: "runAtLoginInitialized", value: true)
        }
    }
    
    @objc private func toggleWindowOnStart(sender: NSButton) {
        let state = sender.state == .on ? true : false
        NotificationCenter.default.post(name: .application, object: nil, userInfo: ["param": "windowOnStart", "value": state])
        self.windowOnStart = state
    }
    
    @objc private func watchForGeneratorSettings(_ notification: Notification) {
        guard let param = notification.userInfo?["param"] as? String else {
            return
        }
        
        if param == "length", let v = notification.userInfo?["value"] as? Int {
            self.lengthBtn?.selectItem(withTitle: "\(v)")
        } else if let v = notification.userInfo?["value"] as? Bool {
            switch param {
            case "lower": self.lowerBtn?.state = v ? .on : .off
            case "upper": self.upperBtn?.state = v ? .on : .off
            case "numbers": self.numbersBtn?.state = v ? .on : .off
            case "symbols": self.symbolsBtn?.state = v ? .on : .off
            default: break
            }
        }
    }
    
    @objc private func watchForApplicationSettings(_ notification: Notification) {
        guard let param = notification.userInfo?["param"] as? String else {
            return
        }
        
        if let v = notification.userInfo?["value"] as? Bool {
            switch param {
            case "startAtLogin": self.startAtLoginBtn?.state = v ? .on : .off
            case "windowOnStart": self.windowOnStartBtn?.state = v ? .on : .off
            default: break
            }
        }
    }
    
    // MARK: - helpers
    
    private func title(_ value: String) -> NSView {
        let view: NSStackView = NSStackView(frame: NSRect(x: 0, y: 0, width: self.frame.width, height: 32))
        view.widthAnchor.constraint(equalToConstant: view.bounds.width).isActive = true
        view.heightAnchor.constraint(equalToConstant: view.bounds.height).isActive = true
        view.alignment = .centerX
        view.distribution = .equalCentering
        
        let title: NSTextField = LabelField(frame: NSRect(x: 0, y: 0, width: self.frame.width, height: 20), value)
        title.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        title.alignment = .center
        title.textColor = .secondaryLabelColor
        
        view.addArrangedSubview(title)
        
        return view
    }
    
    private func row(views: [NSView]) -> NSView {
        let view: NSStackView = NSStackView(frame: NSRect(x: 0, y: 0, width: self.frame.width, height: 0))
        view.widthAnchor.constraint(equalToConstant: view.bounds.width).isActive = true
        view.spacing = 0
        view.orientation = .vertical
        
        for i in 0..<views.count {
            view.addArrangedSubview(views[i])
        }
        
        let h = view.arrangedSubviews.map({ $0.bounds.height }).reduce(0, +)
        if self.frame.size.height != h {
            view.setFrameSize(NSSize(width: self.bounds.width, height: h))
        }
        
        return view
    }
    
    private func lengthSelector() -> NSView {
        let view: NSStackView = NSStackView(frame: NSRect(x: 0, y: 0, width: self.frame.width, height: self.rowHeight))
        view.orientation = .horizontal
        view.spacing = 0
        view.distribution = .fillProportionally
        view.widthAnchor.constraint(equalToConstant: view.bounds.width).isActive = true
        view.heightAnchor.constraint(equalToConstant: view.bounds.height).isActive = true
        
        let title: NSTextField = LabelField(frame: NSRect(
            x: 0,
            y: (view.frame.height - 16)/2,
            width: view.frame.width - 52,
            height: 17
        ), "Length")
        title.font = NSFont.systemFont(ofSize: 13, weight: .light)
        title.textColor = .textColor
        
        let select: NSPopUpButton = NSPopUpButton(frame: NSRect(x: 0, y: 0, width: 0, height: 26))
        select.target = self
        select.action = #selector(self.updateLength)
        self.lengthBtn = select
        
        let menu = NSMenu()
        Array(16...128).forEach { (value) in
            let interfaceMenu = NSMenuItem(title: "\(value)", action: nil, keyEquivalent: "")
            menu.addItem(interfaceMenu)
            if value == Generator.shared.length {
                interfaceMenu.state = .on
            }
        }
        select.menu = menu
        
        select.sizeToFit()
        
        view.addArrangedSubview(title)
        view.addArrangedSubview(select)
        
        return view
    }
    
    private func setView(title: String, action: Selector, state: Bool) -> NSView {
        let row: NSStackView = NSStackView(frame: NSRect(x: 0, y: 0, width: self.frame.width, height: self.rowHeight))
        row.orientation = .horizontal
        row.spacing = 0
        row.distribution = .fillProportionally
        
        let title: NSTextField = LabelField(frame: NSRect(x: 0, y: 0, width: 0, height: 0), title)
        title.font = NSFont.systemFont(ofSize: 12, weight: .light)
        title.textColor = .textColor
        
        let state: NSControl.StateValue = state ? .on : .off
        let button: NSButton = NSButton(frame: NSRect(x: 0, y: 0, width: 20, height: row.frame.height))
        button.widthAnchor.constraint(equalToConstant: button.bounds.width).isActive = true
        button.setButtonType(.switch)
        button.state = state
        button.title = ""
        button.action = action
        button.isBordered = false
        button.isTransparent = false
        button.target = self
        button.wantsLayer = true
        
        row.addArrangedSubview(title)
        row.addArrangedSubview(button)
        
        row.widthAnchor.constraint(equalToConstant: row.bounds.width).isActive = true
        row.heightAnchor.constraint(equalToConstant: row.bounds.height).isActive = true
        
        return row
    }
}
