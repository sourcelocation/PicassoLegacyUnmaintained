//
//  ThemeManager.swift
//  TrollTools
//
//  Created by exerhythm on 19.10.2022.
//

import UIKit
import ZIPFoundation

var rawThemesDir: URL = {
#if targetEnvironment(simulator)
    FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(".DO-NOT-DELETE-Picasso/.PicassoRawThemes/")
#else
    URL(fileURLWithPath: "/var/mobile/.DO-NOT-DELETE-Picasso/.PicassoRawThemes/")
#endif
}()

var processedThemesDir: URL = {
#if targetEnvironment(simulator)
    FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(".DO-NOT-DELETE-Picasso/.PicassoProcessedThemes/")
#else
    URL(fileURLWithPath: "/var/mobile/.DO-NOT-DELETE-Picasso/.PicassoProcessedThemes/")
#endif
}()

var originalIconsDir: URL = {
#if targetEnvironment(simulator)
    FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(".DO-NOT-DELETE-Picasso/.OriginalIconsBackup/")
#else
    URL(fileURLWithPath: "/var/mobile/.DO-NOT-DELETE-Picasso/.OriginalIconsBackup/")
#endif
}()

var catalogBackupsDir: URL = {
#if targetEnvironment(simulator)
    FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(".DO-NOT-DELETE-Picasso/.CatalogBackups/")
#else
    URL(fileURLWithPath: "/var/mobile/.DO-NOT-DELETE-Picasso/.CatalogBackups/")
#endif
}()

var themingInProgress = false

class ThemeManager: ObservableObject {
    
    static let shared = ThemeManager()
    
    let fm = FileManager.default
    
    var catalogThemeManager = CatalogThemeManager()
    
    @Published var testThemeAllIcons = false
    
    @Published var themes: [Theme] = []
    
    @Published var preferedThemes: [Theme] = []
    
    var preferedIcons: [String : ThemedIcon] {
        get {
            var res: [String : ThemedIcon] = [:]
            for theme in preferedThemes {
                if let icons = try? fm.contentsOfDirectory(at: theme.url, includingPropertiesForKeys: nil) {
                    for icon in icons {
                        let appID = appIDFromIcon(url: icon)
                        res[appID] = .init(appID: appID, themeName: theme.name)
                    }
                }
            }
            for (overridenAppID, themeName) in iconOverrides {
                res[overridenAppID] = .init(appID: overridenAppID, themeName: themeName)
            }
            return res
        }
    }
    
    var iconOverrides: [String : String] {
        get { return UserDefaults.standard.dictionary(forKey: "iconOverrides") as? [String : String] ?? [:] }
        set { UserDefaults.standard.set(newValue, forKey: "iconOverrides") }
    }
    var currentThemedIcons: [ThemedIcon] {
        get { guard let data = UserDefaults.standard.data(forKey: "currentThemedIcons") else { return [] }; return (try? JSONDecoder().decode([ThemedIcon].self, from: data)) ?? [] }
        set { guard let data = try? JSONEncoder().encode(newValue) else { return }; UserDefaults.standard.set(data, forKey: "currentThemedIcons") }
    }
    
    // MARK: - Set theme
    func applyChanges(progress: (String) -> ()) throws -> [String] {
        let appChanges = try neededChanges()
        
        return try catalogThemeManager.applyChanges(appChanges, progress: { (percentage, appName) in
            progress("\(Int(percentage * 100))% done\n\nChanging \(appName) icon")
        })
    }
    
    func neededChanges() throws -> [AppIconChange] {
        let apps = try ApplicationManager.getApps()
        var appChanges: [AppIconChange] = []
        let preferedIcons = preferedIcons
        
        for app in apps {
            guard fm.fileExists(atPath: app.assetsCatalogURL().path) || !app.pngIconPaths.isEmpty else { continue }
            
            if testThemeAllIcons {
                appChanges.append(.init(app: app, icon: preferedIcons.first!.value ))
            } else {
                
                if let themedIcon = preferedIcons[app.bundleIdentifier] {
                    // add app to changes to be themed
                    appChanges.append(.init(app: app, icon: themedIcon))
                } else if app.bundleIdentifier == "com.apple.mobiletimer", let themedIcon = preferedIcons["ClockIconBackgroundSquare"] {
                    // add app to changes to be themed
                    appChanges.append(.init(app: app, icon: themedIcon))
                } else {
                    var bundleComponents = app.bundleIdentifier.components(separatedBy: ".")
                    bundleComponents.removeLast()
                    if let themedIcon = preferedIcons[bundleComponents.joined(separator: ".")] {
                        // sideloaded apps
                        appChanges.append(.init(app: app, icon: themedIcon))
                    } else {
                        // restore
                        appChanges.append(.init(app: app, icon: nil))
                    }
                }
            }
        }
        
        
        return appChanges
    }
    
    // MARK: - Getting icons
    func icons(forAppIDs appIDs: [String], from theme: Theme) throws -> [UIImage?] {
        appIDs.map { try? icon(forAppID: $0, from: theme) }
    }
    func icon(forAppID appID: String, from theme: Theme) throws -> UIImage {
        guard let image = UIImage(contentsOfFile: theme.url.appendingPathComponent(appID).path + ".png") else { throw "Couldn't open image" }
        return image
    }
    func icon(forAppID appID: String, fromThemeWithName name: String) throws -> UIImage {
        return try icon(forAppID: appID, from: Theme(name: name, iconCount: 1))
    }
    
    func importTheme(from importURL: URL) throws {
        var name = importURL.deletingPathExtension().lastPathComponent
        var finalURL = importURL
        try? fm.createDirectory(at: rawThemesDir, withIntermediateDirectories: true)
        let themeURL = rawThemesDir.appendingPathComponent(name)
        
        if importURL.lastPathComponent.contains(".theme") {
            // unzip
            let unzipURL = fm.temporaryDirectory.appendingPathComponent("theme_unzip")
            try? fm.removeItem(at: unzipURL)
            try fm.unzipItem(at: importURL, to: unzipURL)
            
            for folder in (try? fm.contentsOfDirectory(at: unzipURL, includingPropertiesForKeys: nil)) ?? [] {
                if folder.deletingPathExtension().lastPathComponent == "IconBundles" {
                    name = importURL.deletingPathExtension().lastPathComponent
                    finalURL = folder
                    break
                }
            }
        }
        
        try? fm.removeItem(at: themeURL)
        try fm.createDirectory(at: themeURL, withIntermediateDirectories: true)
        
        for icon in (try? fm.contentsOfDirectory(at: finalURL, includingPropertiesForKeys: nil)) ?? [] {
            guard !icon.lastPathComponent.contains(".DS_Store") else { continue }
            try? fm.copyItem(at: icon, to: themeURL.appendingPathComponent(appIDFromIcon(url: icon) + ".png"))
        }
        refreshThemes()
    }
    
    
    func renameImportedTheme(id: UUID, newName: String) throws {
        guard let i = themes.firstIndex(where: { t in t.id == id }) else { throw "Theme not found" }
        try fm.moveItem(at: themes[i].url, to: themes[i].url.deletingLastPathComponent().appendingPathComponent(newName))
        refreshThemes()
    }
    
    func removeImportedTheme(theme: Theme) throws {
        try? fm.removeItem(at: theme.cacheURL)
        try fm.removeItem(at: theme.url)
        refreshThemes()
    }
    
    // MARK: - Utils
    private func iconFileEnding(iconFilename: String) -> String {
        if iconFilename.contains("-large.png") {
            return "-large"
        } else if iconFilename.contains("@2x.png") {
            return"@2x"
        } else if iconFilename.contains("@3x.png") {
            return "@3x"
        } else {
            return ""
        }
    }
//    func installedApplicationsNames() throws -> [String: String] {
//        guard let apps = LSApplicationWorkspace.default().allApplications() else { throw "Couldn't get apps" }
//        return apps.reduce(into: [String: String]()) {
//            let applicationIdentifier = $1.applicationIdentifier
//            let displayName = $1.localizedName()
//            $0[applicationIdentifier ?? ""] = displayName
//        }
//    }
    private func appIDFromIcon(url: URL) -> String {
        return url.deletingPathExtension().lastPathComponent.replacingOccurrences(of: iconFileEnding(iconFilename: url.lastPathComponent), with: "")
    }
    private func iconURL(appID: String, in theme: Theme) -> URL {
        return theme.url.appendingPathComponent(appID + ".png")
    }
    
    private func getThemes() -> [Theme] {
        let contents = (try? fm.contentsOfDirectory(at: rawThemesDir, includingPropertiesForKeys: nil)) ?? []
        
        return contents.map { .init(name: $0.lastPathComponent, iconCount: ((try? fm.contentsOfDirectory(at: $0, includingPropertiesForKeys: nil)) ?? []).count )}
    }
    
    func refreshThemes() {
        themes = getThemes()
    }
}


struct Theme: Codable, Identifiable, Equatable {
    var id = UUID()
    
    var name: String
    var iconCount: Int
    var url: URL { // Documents/ImportedThemes/Theme.theme
        return rawThemesDir.appendingPathComponent(name /*+ ".theme"*/)
    }
    var cacheURL: URL { // Documents/ImportedThemes/Theme.theme
        return processedThemesDir.appendingPathComponent(name /*+ ".theme"*/)
    }
    
    static func == (lhs: Theme, rhs: Theme) -> Bool {
        return lhs.name == rhs.name
    }
}

enum IconThemingMethod: String {
    case webclips, appIcons
}

struct ThemedIcon: Codable {
    var appID: String
    var themeName: String
    var rawThemeIconURL: URL {
        rawThemesDir.appendingPathComponent(themeName).appendingPathComponent(appID + ".png")
    }
    func cachedThemeIconURL(fileName: String) -> URL {
        processedThemesDir.appendingPathComponent(themeName).appendingPathComponent(appID + "----" + fileName)
    }
}
