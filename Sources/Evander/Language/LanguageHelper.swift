//
//  LanguageHelper.swift
//  Sileo
//
//  Created by Andromeda on 03/08/2021.
//  Copyright © 2021 Sileo Team. All rights reserved.
//

import UIKit
import CommonCrypto

final public class LanguageHelper {
    
    public static let shared = LanguageHelper()
    public let availableLanguages: [Language]
    public var primaryBundle: Bundle?
    public var alternateBundle: Bundle?
    public var locale: Locale?
    public var isRtl = false
    
    private func hashFolder(_ url: URL) -> (String, [String]) {
        var filenames = [String]()
        var context = CC_SHA256_CTX()
        CC_SHA256_Init(&context)
        
        while autoreleasepool(invoking: {
            for content in url.implicitContents {
                if content.lastPathComponent &= ["LaunchScreen.storyboardc", "Main.storyboardc"] { continue }
                if let data = try? Data(contentsOf: content) {
                    _ = data.withUnsafeBytes { bytesFromBuffer -> Int32 in
                      guard let rawBytes = bytesFromBuffer.bindMemory(to: UInt8.self).baseAddress else {
                        return Int32(kCCMemoryFailure)
                      }

                      return CC_SHA256_Update(&context, rawBytes, numericCast(data.count))
                    }
                    filenames.append(content.lastPathComponent)
                }
            }
            return false
        }) { }
        var digestData = Data(count: Int(CC_SHA256_DIGEST_LENGTH))
        _ = digestData.withUnsafeMutableBytes { bytesFromDigest -> Int32 in
            
            guard let rawBytes = bytesFromDigest.bindMemory(to: UInt8.self).baseAddress else {
                return Int32(kCCMemoryFailure)
            }

            return CC_SHA256_Final(rawBytes, &context)
        }
        return (digestData.compactMap { String(format: "%02x", $0) }.joined(), filenames)
    }
    
    private func delete(_ folder: URL, if_newer newer: URL) -> Bool {
        guard let folderDate = folder.attributes?[FileAttributeKey.modificationDate] as? Date,
              let newerDate = newer.attributes?[FileAttributeKey.modificationDate] as? Date else { return false }
        if newerDate > folderDate {
            try? FileManager.default.removeItem(at: folder)
            return false
        }
        return true
    }
    
    #if DEBUG
    private func generateManifest() {
        var data = [String: String]()
        for locale in availableLanguages {
            guard let path = Bundle.main.url(forResource: locale.key, withExtension: "lproj") else { continue }
            let (hash, _) = hashFolder(path)
            data[locale.key] = hash
        }
        guard let json = try? JSONSerialization.data(withJSONObject: data) else { return }
        try? json.write(to: EvanderNetworking.localeCache.appendingPathComponent(".MANIFEST"))
    }
    #endif
    
    public func remoteManifest(url: URL, _ completion: @escaping (Bool) -> Void) {
        if Thread.isMainThread {
            DispatchQueue.global(qos: .background).async { [self] in
                self.remoteManifest(url: url, completion)
            }
            return
        }
        guard let language = UserDefaults.standard.string(forKey: "SelectedLanguage"),
              var path = Bundle.main.url(forResource: language, withExtension: "lproj") else { return }
        if language == "Base" { return completion(false) }
        let finalDestination = EvanderNetworking.localeCache.appendingPathComponent("\(language).lproj")
        if finalDestination.dirExists && delete(finalDestination, if_newer: path) {
            path = finalDestination
        }
        let (hash, filenames) = hashFolder(path)
        guard !filenames.isEmpty else { return completion(false) }
        EvanderNetworking.request(url: url.appendingPathComponent("MANIFEST"), type: [String: String].self, cache: .init(localCache: false, skipNetwork: false)) { _, _, _, dict in
            guard let remoteMainfest = dict,
                  let selected = remoteMainfest[language],
                  selected != hash else { return }
            let tmpDestination = EvanderNetworking.localeCache.appendingPathComponent("_\(language).lproj")
            do {
                try FileManager.default.createDirectory(at: tmpDestination, withIntermediateDirectories: true)
            } catch {
                return completion(false)
            }
            let remoteFolder = url.appendingPathComponent("\(language).lproj")
            let loadGroup = DispatchGroup()
            for file in filenames {
                loadGroup.enter()
                let url = remoteFolder.appendingPathComponent(file)
                EvanderNetworking.request(url: url, type: Data.self) { _, _, _, data in
                    guard let data = data else {
                        return completion(false)
                    }
                    do {
                        try data.write(to: tmpDestination.appendingPathComponent(file))
                    } catch {
                        return completion(false)
                    }
                    loadGroup.leave()
                }
            }
            loadGroup.notify(queue: .global(qos: .background)) {
                defer {
                    try? FileManager.default.removeItem(at: tmpDestination)
                }
                let (newHash, newFilenames) = LanguageHelper.shared.hashFolder(tmpDestination)
                if newHash == selected && newFilenames == filenames {
                    do {
                        try FileManager.default.moveItem(at: tmpDestination, to: finalDestination)
                    } catch {
                        return completion(false)
                    }
                    completion(true)
                }
            }
        }
    }
    
    init() {
        #if DEBUG
        defer {
            generateManifest()
        }
        #endif
        var locales = Bundle.main.localizations
        locales.removeAll { $0 == "Base" }
        locales.sort { $0 < $1 }
        
        let currentLocale = NSLocale.current as NSLocale
        var temp = [Language]()
        for language in locales {
            let locale = NSLocale(localeIdentifier: language)
            let localizedDisplay: String
            let display: String
            if language == "en-PT" {
                localizedDisplay = "Pirate English"
                display = "Pirate English"
            } else {
                localizedDisplay = currentLocale.displayName(forKey: .identifier, value: language)?.capitalized(with: currentLocale as Locale) ?? language
                display = locale.displayName(forKey: .identifier, value: language)?.capitalized(with: locale as Locale) ?? language
            }
            temp.append(Language(displayName: display, localizedDisplay: localizedDisplay, key: language))
        }
        availableLanguages = temp

        var selectedLanguage: String
        if currentLocale.languageCode == "en-PT" && UserDefaults.standard.optionalBool("UseSystemLanguage", fallback: true) {
            selectedLanguage = "Base"
            UserDefaults.standard.setValue("Base", forKey: "SelectedLanguage")
        } else if UserDefaults.standard.object(forKey: "UseSystemLanguage") == nil {
            UserDefaults.standard.setValue(true, forKey: "UseSystemLanguage")
            let locale = Locale.current.identifier
            self.isRtl = Locale.characterDirection(forLanguage: locale) == .rightToLeft
            return
        } else if UserDefaults.standard.bool(forKey: "UseSystemLanguage") {
            let locale = Locale.current.identifier
            self.isRtl = Locale.characterDirection(forLanguage: locale) == .rightToLeft
            return
        // swiftlint:disable:next identifier_name
        } else if let _selectedLanguage = UserDefaults.standard.string(forKey: "SelectedLanguage") {
            selectedLanguage = _selectedLanguage
        } else {
            selectedLanguage = "Base"
            UserDefaults.standard.setValue("Base", forKey: "SelectedLanguage")
        }
        
        if let path = Bundle.main.path(forResource: selectedLanguage, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            self.isRtl = Locale.characterDirection(forLanguage: selectedLanguage) == .rightToLeft
            UIView.appearance().semanticContentAttribute = isRtl ? .forceRightToLeft : .forceLeftToRight
            UIButton.appearance().semanticContentAttribute = isRtl ? .forceRightToLeft : .forceLeftToRight
            UITextView.appearance().semanticContentAttribute = isRtl ? .forceRightToLeft : .forceLeftToRight
            UITextField.appearance().semanticContentAttribute = isRtl ? .forceRightToLeft : .forceLeftToRight
            UISwitch.appearance().semanticContentAttribute = isRtl ? .forceRightToLeft : .forceLeftToRight
            UITableView.appearance().semanticContentAttribute = isRtl ? .forceRightToLeft : .forceLeftToRight
            UILabel.appearance().semanticContentAttribute = isRtl ? .forceRightToLeft : .forceLeftToRight
            self.alternateBundle = bundle
            self.locale = Locale(identifier: selectedLanguage)
            let primaryPath = EvanderNetworking.localeCache.appendingPathComponent("\(selectedLanguage).lproj")
            if let bundle = Bundle(url: primaryPath) {
                self.primaryBundle = bundle
            }
            return
        }
        
        guard selectedLanguage != "Base" else { return }
        if let path = Bundle.main.path(forResource: "Base", ofType: "lproj"),
           let bundle = Bundle(path: path) {
            self.primaryBundle = bundle
            self.isRtl = false
            UIView.appearance().semanticContentAttribute = isRtl ? .forceRightToLeft : .forceLeftToRight
            UIButton.appearance().semanticContentAttribute = isRtl ? .forceRightToLeft : .forceLeftToRight
            UITextView.appearance().semanticContentAttribute = isRtl ? .forceRightToLeft : .forceLeftToRight
            UITextField.appearance().semanticContentAttribute = isRtl ? .forceRightToLeft : .forceLeftToRight
            UISwitch.appearance().semanticContentAttribute = isRtl ? .forceRightToLeft : .forceLeftToRight
            UITableView.appearance().semanticContentAttribute = isRtl ? .forceRightToLeft : .forceLeftToRight
            UILabel.appearance().semanticContentAttribute = isRtl ? .forceRightToLeft : .forceLeftToRight
            self.locale = Locale(identifier: selectedLanguage)
            return
        }
    }
    
}
