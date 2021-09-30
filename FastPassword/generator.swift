//
//  generator.swift
//  FastPassword
//
//  Created by Serhiy Mytrovtsiy on 06/09/2021.
//  Using Swift 5.0.
//  Running on macOS 10.15.
//
//  Copyright © 2021 Serhiy Mytrovtsiy. All rights reserved.
//

import Foundation

private enum groups: String {
    case lower = "abcdefghijklmnopqrstuvwxyz"
    case upper = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    case number = "0123456789"
    case symbol = ".!?;,&%$@#^*~"
    
    public func list() -> [Character] {
        var array: [Character] = []
        var index = self.rawValue.startIndex
        
        while index != self.rawValue.endIndex {
            let character = self.rawValue[index]
            array.append(character)
            index = self.rawValue.index(index, offsetBy: 1)
        }
        
        return array
    }
}

public class Generator {
    public static let shared: Generator = Generator()
    
    public var length: Int {
        get {
            return Store.shared.int(key: "length", defaultValue: 32)
        }
        set {
            Store.shared.set(key: "length", value: newValue)
        }
    }
    public var lower: Bool {
        get {
            return Store.shared.bool(key: "lower", defaultValue: true)
        }
        set {
            Store.shared.set(key: "lower", value: newValue)
        }
    }
    public var upper: Bool {
        get {
            return Store.shared.bool(key: "upper", defaultValue: true)
        }
        set {
            Store.shared.set(key: "upper", value: newValue)
        }
    }
    public var numbers: Bool {
        get {
            return Store.shared.bool(key: "numbers", defaultValue: true)
        }
        set {
            Store.shared.set(key: "numbers", value: newValue)
        }
    }
    public var symbols: Bool {
        get {
            return Store.shared.bool(key: "symbols", defaultValue: false)
        }
        set {
            Store.shared.set(key: "symbols", value: newValue)
        }
    }
    
    init() {}
    
    public func new() -> String {
        var characters: [Character] = []
        
        if self.lower {
            characters.append(contentsOf: groups.lower.list())
        }
        if self.upper {
            characters.append(contentsOf: groups.upper.list())
        }
        if self.numbers {
            characters.append(contentsOf: groups.number.list())
        }
        if self.symbols {
            characters.append(contentsOf: groups.symbol.list())
        }
        
        if characters.isEmpty {
            return ""
        }
        
        var passwordArray: [Character] = []
        while passwordArray.count < self.length {
            let index = Int(arc4random()) % (characters.count - 1)
            passwordArray.append(characters[index])
        }
        
        return String((0..<self.length).map{ _ in passwordArray.randomElement()! })
    }
}
