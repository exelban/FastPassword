//
//  utils.swift
//  FastPassword
//
//  Created by Serhiy Mytrovtsiy on 07/09/2021.
//  Using Swift 5.0.
//  Running on macOS 10.15.
//
//  Copyright © 2021 Serhiy Mytrovtsiy. All rights reserved.
//

import Cocoa
import ServiceManagement

public extension Notification.Name {
    static let update = Notification.Name("updateValue")
    static let generator = Notification.Name("generator")
    static let application = Notification.Name("application")
}

public class LabelField: NSTextField {
    public init(frame: NSRect, _ label: String = "") {
        super.init(frame: frame)
        
        self.isEditable = false
        self.isSelectable = false
        self.isBezeled = false
        self.wantsLayer = true
        self.backgroundColor = .clear
        self.canDrawSubviewsIntoLayer = true
        
        self.stringValue = label
        self.textColor = .secondaryLabelColor
        self.alignment = .natural
        self.font = NSFont.systemFont(ofSize: 12, weight: .regular)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public class IconButton: NSButton {
    public init(frame: NSRect, title: String, icon: String) {
        super.init(frame: frame)
        
        self.title = title
        self.toolTip = title
        self.bezelStyle = .regularSquare
        self.translatesAutoresizingMaskIntoConstraints = false
        self.imageScaling = .scaleNone
        if let img = Bundle(for: type(of: self)).image(forResource: icon) {
            self.image = img
        } else {
            print("image \(icon) not found")
        }
        self.contentTintColor = .tertiaryLabelColor
        self.isBordered = false
        self.focusRingType = .none
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public struct LaunchAtLogin {
    private static let id = "\(Bundle.main.bundleIdentifier!).LaunchAtLogin"
    
    public static var isEnabled: Bool {
        get {
            guard let jobs = (SMCopyAllJobDictionaries(kSMDomainUserLaunchd).takeRetainedValue() as? [[String: AnyObject]]) else {
                return false
            }
            
            let job = jobs.first { $0["Label"] as! String == id }
            return job?["OnDemand"] as? Bool ?? false
        }
        set {
            SMLoginItemSetEnabled(id as CFString, newValue)
        }
    }
}

public class Store {
    public static let shared = Store()
    private let defaults = UserDefaults.standard
    
    public func exist(key: String) -> Bool {
        return self.defaults.object(forKey: key) == nil ? false : true
    }
    
    public func bool(key: String, defaultValue value: Bool) -> Bool {
        return !self.exist(key: key) ? value : defaults.bool(forKey: key)
    }
    
    public func int(key: String, defaultValue value: Int) -> Int {
        return (!self.exist(key: key) ? value : defaults.integer(forKey: key))
    }
    
    public func set(key: String, value: Bool) {
        self.defaults.set(value, forKey: key)
    }
    
    public func set(key: String, value: Int) {
        self.defaults.set(value, forKey: key)
    }
}
