//
//  ToolsManager.swift
//  Picasso
//
//  Created by lemin on 1/4/23.
//

import UIKit
import MacDirtyCowSwift
import Dynamic

// get the user defaults for a boolean key
func getDefaultBool(forKey: String, defaultValue: Bool = false) -> Bool {
    let defaults = UserDefaults.standard
    
    return defaults.object(forKey: forKey) as? Bool ?? defaultValue
}

func getDefaultStr(forKey: String, defaultValue: String = "Visible") -> String {
    let defaults = UserDefaults.standard
    
    return defaults.string(forKey: forKey) ?? defaultValue
}

// set a user defaults value for a boolean key
func setDefaultBoolean(forKey: String, value: Bool) {
    let defaults = UserDefaults.standard
    
    defaults.set(value, forKey: forKey)
}

func respring() {
    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    KFD.kclose()
    
    let animator = UIViewPropertyAnimator(duration: 0.5, dampingRatio: 1) {
        let windows: [UIWindow] = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
        
        for window in windows {
            window.alpha = 0
            window.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }
    }
    
    animator.addCompletion { _ in
        if UserDefaults.standard.string(forKey: "RespringType") ?? "Frontboard" == "Backboard" {
            restartBackboard()
        } else {
            restartFrontboard()
        }
        
        sleep(2) // give the springboard some time to restart before exiting
        exit(0)
    }
    
    animator.startAnimation()
}

func exitGracefully() {
    UIControl().sendAction(#selector(URLSessionTask.suspend), to: UIApplication.shared, for: nil)
    Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
        exit(0)
    }
}

var connection: NSXPCConnection?

func remvoeIconCache() {
    print("removing icon cache")
    if connection == nil {
        let myCookieInterface = NSXPCInterface(with: ISIconCacheServiceProtocol.self)
        connection = Dynamic.NSXPCConnection(machServiceName: "com.apple.iconservices", options: []).asObject as? NSXPCConnection
        connection!.remoteObjectInterface = myCookieInterface
        connection!.resume()
        print("Connection: \(connection!)")
    }
    
    (connection!.remoteObjectProxy as AnyObject).clearCachedItems(forBundeID: nil) { (a, b) in // passing nil to remove all icon cache
        print("Successfully responded (\(a), \(b ?? "(null)"))")
    }
}

func createStatusBarDateTag() {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = UserDefaults.standard.string(forKey: "DateFormat") ?? "MM/dd"
    
    let newStr: String = dateFormatter.string(from: Date())
    
    if (newStr + " ▶").utf8CString.count <= 256 {
        // set the date
        StatusManager.sharedInstance().setCrumb(newStr)
        if StatusManager.sharedInstance().isMDCMode() {
            // if mdc then apply and respring
            if FileManager.default.fileExists(atPath: "/var/mobile/Library/SpringBoard/statusBarOverridesEditing") {
                do {
                    let _ = try FileManager.default.replaceItemAt(URL(fileURLWithPath: "/var/mobile/Library/SpringBoard/statusBarOverrides"), withItemAt: URL(fileURLWithPath: "/var/mobile/Library/SpringBoard/statusBarOverridesEditing"))
                    restartFrontboard()
                } catch {
                    UIApplication.shared.alert(body: "\(error)")
                }
                
            }
        }
    } else {
        UIApplication.shared.alert(body: "Length error!")
    }
}

//func rebuildIconCache() throws {
//    let fm = FileManager.default
//    for path in try! fm.contentsOfDirectory(atPath: "/var/containers/Shared/SystemGroup/systemgroup.com.apple.lsd.iconscache/Library/Caches/com.apple.IconsCache/") {
//        print(path)
//    }
//    for url in try! fm.contentsOfDirectory(at: URL(fileURLWithPath: "/var/containers/Shared/SystemGroup/systemgroup.com.apple.lsd.iconscache/Library/Caches/com.apple.IconsCache"), includingPropertiesForKeys: nil) {
//        let path = url.path
//        print(path)
//
//        let fd = open(path, O_RDONLY | O_CLOEXEC)
//        let originalFileSize = lseek(fd, 0, SEEK_END)
//
//        KFD.overwriteFile(at: path, with: Data(repeating: 11, count: Int(originalFileSize)))
//
////        // open and map original font
////        if fd == -1 {
////            throw "Could not open target file"
////        }
////        defer { close(fd) }
////
////        lseek(fd, 0, SEEK_SET)
////
////
////        unaligned_copy_switch_race(fd, 0, Data(repeating: 11, count: Int(originalFileSize - 1)).withUnsafeBytes { p in p.baseAddress }, Int(originalFileSize - 1))
//    }
//}

enum SpringBoardOptions: String, CaseIterable {
    case DockHidden = "DockHidden"
    case HomeBarHidden = "HomeBar"
    case FolderBGHidden = "FolderBGHidden"
    case FolderBlurDisabled = "FolderBlurDisabled"
    case SwitcherBlurDisabled = "SwitcherBlurDisabled"
    case CCModuleBackgroundDisabled = "CCModuleBackgroundDisabled"
    case PodBackgroundDisabled = "PodBackgroundDisabled"
    case NotifBackgroundDisabled = "NotifBackgroundDisabled"
    case ShortcutBanner = "ShortcutBanner"
}

let replacementPaths: [String: [String]] = [
    SpringBoardOptions.DockHidden.rawValue: ["CoreMaterial.framework/dockDark.materialrecipe", "CoreMaterial.framework/dockLight.materialrecipe"],
    SpringBoardOptions.HomeBarHidden.rawValue: ["MaterialKit.framework/Assets.car"],
    SpringBoardOptions.FolderBGHidden.rawValue: ["SpringBoardHome.framework/folderLight.materialrecipe", "SpringBoardHome.framework/folderDark.materialrecipe", "SpringBoardHome.framework/folderDarkSimplified.materialrecipe"],
    SpringBoardOptions.FolderBlurDisabled.rawValue: ["SpringBoardHome.framework/folderExpandedBackgroundHome.materialrecipe", "SpringBoardHome.framework/folderExpandedBackgroundHomeSimplified.materialrecipe"],
    SpringBoardOptions.SwitcherBlurDisabled.rawValue: ["SpringBoard.framework/homeScreenBackdrop-application.materialrecipe", "SpringBoard.framework/homeScreenBackdrop-switcher.materialrecipe"],
    SpringBoardOptions.CCModuleBackgroundDisabled.rawValue: ["CoreMaterial.framework/modules.materialrecipe"],
    SpringBoardOptions.PodBackgroundDisabled.rawValue: ["SpringBoardHome.framework/podBackgroundViewLight.visualstyleset", "SpringBoardHome.framework/podBackgroundViewDark.visualstyleset"],
    SpringBoardOptions.NotifBackgroundDisabled.rawValue: ["CoreMaterial.framework/plattersDark.materialrecipe", "CoreMaterial.framework/platters.materialrecipe"],
    SpringBoardOptions.ShortcutBanner.rawValue: ["SpringBoard.framework/BannersAuthorizedBundleIDs.plist"]
]

enum OverwritingFileTypes {
    case springboard
    case cc
    case plist
    case audio
    case region
}

// reset the device subtype
func resetDeviceSubType() -> Bool {
    var canUseStandardMethod: [String] = ["10,3", "10,4", "10,6", "11,2", "11,4", "11,6", "11,8", "12,1", "12,3", "12,5", "13,1", "13,2", "13,3", "13,4", "14,4", "14,5", "14,2", "14,3", "14,7", "14,8", "15,2"]
    let predefinedSubtypes: [String: Int] = [
        "iPhone8,1": 568,
        "iPhone8,2": 570,
        "iPhone8,4": 568,
        "iPhone9,1": 569,
        "iPhone9,3": 569,
        "iPhone9,2": 570,
        "iPhone9,4": 570,
        "iPhone10,1": 569,
        "iPhone10,4": 569,
        "iPhone10,2": 570,
        "iPhone10,5": 570,
        "iPhone14,6": 569
    ]
    for (i, v) in canUseStandardMethod.enumerated() {
        canUseStandardMethod[i] = "iPhone" + v
    }
    
    var deviceSubType: Int = -1
    let deviceModel: String = UIDevice().machineName

    print("Device Model: " + deviceModel)
    if canUseStandardMethod.contains(deviceModel) {
        // can use device bounds
        deviceSubType = Int(UIScreen.main.nativeBounds.height)
    } else if predefinedSubtypes[deviceModel] != nil {
        deviceSubType = predefinedSubtypes[deviceModel]!
    } else {//else if specialCases[deviceModel] != nil {
        //deviceSubType = specialCases[deviceModel]!
        let url: URL? = URL(string: "https://raw.githubusercontent.com/leminlimez/Picasso/main/DefaultSubTypes.json")
        if url != nil {
            // get the data of the file
            let task = URLSession.shared.dataTask(with: url!) { data, response, error in
                guard let data = data else {
                    print("No data to decode")
                    return
                }
                guard let subtypeData = try? JSONSerialization.jsonObject(with: data, options: []) else {
                    print("Couldn't decode json data")
                    return
                }
                
                // check if all the files exist
                if  let subtypeData = subtypeData as? Dictionary<String, AnyObject>, let deviceTypes = subtypeData["Default_SubTypes"] as? [String: Int] {
                    if deviceTypes[deviceModel] != nil {
                        // successfully found subtype
                        deviceSubType = deviceTypes[deviceModel] ?? -1
                    }
                }
            }
            task.resume()
        }
    }
    
    // set the subtype
    print("Device SubType: " + String(deviceSubType))
    if deviceSubType > 0 {
        UserDefaults.standard.set(deviceSubType, forKey: "OriginalDeviceSubType")
        return true
    } else {
        print("Could not get the device subtype")
    }
    return false
}

func overwriteFile<Value>(typeOfFile: OverwritingFileTypes, fileIdentifier: String, _ value: Value) -> Bool {
    // find the path and replace the file
    // springboard option
    if typeOfFile == OverwritingFileTypes.springboard {
        // springboard tweak being applied
        if replacementPaths[fileIdentifier] != nil {
            var succeeded = true
            for path in replacementPaths[fileIdentifier]! {
                if fileIdentifier == "HomeBar" && value as? Bool == false {
                    if let url: URL = Bundle.main.url(forResource: "HomeBarAssets", withExtension: "car") {
                        do {
                            let replacementCar = try Data(contentsOf: url)
                            try KFD.overwriteFile(at: "/System/Library/PrivateFrameworks/" + path, with: replacementCar)
                        } catch {
                            print(error.localizedDescription)
                            succeeded = false
                        }
                    } else {
                        print("Home bar file not found!")
                        return false
                    }
                } else {
                    let randomGarbage = Data("###".utf8)
                    try? KFD.overwriteFile(at: "/System/Library/PrivateFrameworks/" + path, with: randomGarbage)
                }
            }
            return succeeded
        }
    
    // audio option
    } else if typeOfFile == OverwritingFileTypes.audio {
        do {
            let path = AudioFiles.getAudioPath(attachment: fileIdentifier)
            if path != nil {
                if value as! String == "Off" {
                    // disable the audio
                    let randomGarbage = Data("###".utf8)
                    try KFD.overwriteFile(at: "/System/Library/Audio/" + path!, with: randomGarbage)
                } else {
                    // replace the audio data
                    let newData = AudioFiles.getNewAudioData(soundName: value as! String)
                    if newData != nil {
                        try KFD.overwriteFile(at: "/System/Library/Audio/" + path!, with: newData!)
                    } else if let customAudioData = AudioFiles.getCustomAudioData(soundName: value as! String) {
                        try KFD.overwriteFile(at: "/System/Library/Audio/" + path!, with: customAudioData)
                    }
                }
            }
            return true
        } catch {
            return false
        }
        
    // setting cc modules transparency
    } else if typeOfFile == OverwritingFileTypes.cc {
        if replacementPaths[fileIdentifier] != nil {
            do {
                let path: String = replacementPaths[fileIdentifier]![0]
                let plistData = try Data(contentsOf: URL(fileURLWithPath: "/System/Library/PrivateFrameworks/" + path))
                let originalSize = plistData.count
                var plist = try PropertyListSerialization.propertyList(from: plistData, options: [], format: nil) as! [String: Any]
                
                // set the transparency of the modules
                if var firstLevel = plist["baseMaterial"] as? [String : Any], var secondLevel = firstLevel["materialFiltering"] as? [String: Any], var thirdLevel = secondLevel["colorMatrix"] as? [String: Any] {
                    for (i, _) in thirdLevel {
                        thirdLevel[i] = 0
                    }
                    secondLevel["colorMatrix"] = thirdLevel
                    firstLevel["materialFiltering"] = secondLevel
                    plist["baseMaterial"] = firstLevel
                }
                
                // overwrite the plist
                var newData = try PropertyListSerialization.data(fromPropertyList: plist, format: .binary, options: 0)
                // add data if too small
                // while loop to make data match because recursive function didn't work
                // very slow, will hopefully improve
                var newDataSize = newData.count
                var added = originalSize - newDataSize
                var count = 0
                while newDataSize != originalSize && count < 50 {
                    count += 1
                    plist.updateValue(String(repeating: "#", count: added), forKey: "#")
                    do {
                        newData = try PropertyListSerialization.data(fromPropertyList: plist, format: .binary, options: 0)
                    } catch {
                        newDataSize = -1
                        break
                    }
                    newDataSize = newData.count
                    if count < 5 {
                        // max out this method at 5 if it isn't working
                        added += originalSize - newDataSize
                    } else {
                        if newDataSize > originalSize {
                            added -= 1
                        } else if newDataSize < originalSize {
                            added += 1
                        }
                    }
                }
                
                if originalSize == newData.count {
                    try KFD.overwriteFile(at: "/System/Library/PrivateFrameworks/" + path, with: newData)
                    return true
                } else {
                    print("File sizes didn't match!")
                    return false
                }
            } catch {
                print(error.localizedDescription)
            }
        }
        
    // modifying a plist
    } else if typeOfFile == OverwritingFileTypes.plist {
        if replacementPaths[fileIdentifier] != nil {
            let path: String = replacementPaths[fileIdentifier]![0]
            let plistData = try! Data(contentsOf: URL(fileURLWithPath: "/System/Library/PrivateFrameworks/" + path))
            let plist = try! PropertyListSerialization.propertyList(from: plistData, options: [], format: nil) as! [String]
            
            var newPlist = plist
            // nullify the file
            for (i, v) in plist.enumerated() {
                newPlist[i] = String(repeating: "#", count: v.count)
            }
            
            // overwrite the plist
            let newData = try! PropertyListSerialization.data(fromPropertyList: newPlist, format: .binary, options: 0)
            do {
                try KFD.overwriteFile(at: "/System/Library/PrivateFrameworks/" + path, with: newData)
            } catch {
                return false
            }
            return true
        }
    } else if typeOfFile == OverwritingFileTypes.region {
        let startPath = "/Library/RegionFeatures/RegionFeatures_"
        let devices = ["iphone", "audio"]
        let succeeded = true
        
        for dev in devices {
            let newData: Data = Data(base64Encoded: regionEncodes[dev]!)!
            try? KFD.overwriteFile(at: startPath + dev + ".txt", with: newData)
        }
        return succeeded
    }
    return false
}

