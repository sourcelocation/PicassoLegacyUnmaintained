//
//  MacDirtyCowSwift.swift
//  MacDirtyCowSwift
//
//  Created by sourcelocation on 08/02/2023.
//

import Foundation
import UIKit

public class KFD {
    public enum KFDOverwriteError: Error, LocalizedError {
        case unknown
        case ram
        case corruption
        
        public var errorDescription: String? {
            switch self {
            case .unknown:
                return "MacDirtyCow exploit failed. Restart the app and try again."
            case .ram:
                return "Mandela Pro ran out of memory and for your safety disabled overwriting files using MacDirtyCow. Please close some apps running in background, reopen Mandela Pro and try again."
            case .corruption:
                return "⚠️IMPORTANT⚠️\nMacDirtyCow corrupted an asset catalog. This will lead to a bootloop if the steps are not followed. FOLLOW CAREFULLY: Close all your background apps, then reopen Mandela Pro for fixing. Then you can try again."
            }
        }
    }
    
    public static var isKFDSafe: Bool = true
    
    public static var kfd: UInt64 = 0
    static private var puaf_pages_options = [16, 32, 64, 128, 256, 512, 1024, 2048]
    static private var puaf_pages_index = 7
    static private var puaf_pages = 0
    
    static private var puaf_method_options = ["physpuppet", "smith"]
    static public var puaf_method = 1
    
    static private var kread_method_options = ["kqueue_workloop_ctl", "sem_open"]
    static private var kread_method = 1
    
    static private var kwrite_method_options = ["dup", "sem_open"]
    static private var kwrite_method = 1
    
    public static func kopen() {
        puaf_pages = puaf_pages_options[puaf_pages_index]
        kfd = do_kopen(UInt64(puaf_pages), UInt64(puaf_method), UInt64(kread_method), UInt64(kwrite_method))
        print("kfd = \(kfd)")
        do_fun()
    }
    
    public static func kclose() {
        do_kclose()
    }
    
    /// unlockDataAtEnd - Unlocked the data at overwrite end. Used when replacing files inside app bundle
    public static func overwriteFile(at path: String, with data: Data, unlockDataAtEnd: Bool = false, multipleIterations: Bool = false) throws {
            print("attempting to write at \(path)")
            let cPathTo = path.withCString { ptr in
                return strdup(ptr)
            }
            let tmpURL = URL.temporaryDirectory.appending(component: "tmp")
            try data.write(to: tmpURL)

            let cPathFrom = tmpURL.path.withCString { ptr in
                return strdup(ptr)
            }
            
            funVnodeOverwrite2(cPathTo!, cPathFrom)

//        if !isMDCSafe {
//            throw MDCOverwriteError.ram
//        }
//
//        let var_vnode = getVnodeVar()
//        print("[i] / vnode: \(var_vnode)");
//        let orig_to_v_data = createFolderAndRedirect(var_vnode);
//
//        try data.write(to: URL(fileURLWithPath: path))
//
//        // cleanup
//        UnRedirectAndRemoveFolder(orig_to_v_data);
    }
    
//    public static func writeData(_ data: Data, toPath path: String) throws {
//        try overwriteFile(at: path, with: data)
//    }
//
    
    public static func mounted(_ path: String) -> URL {
        return URL.documentsDirectory.appending(component: "mounted/").appending(component: path)
    }
    
    private static var orig_to_v_data: UInt64 = 0
    public static func mountVar() {
        let var_vnode = getVnodeVar()
        print("[i] / vnode: \(var_vnode)");
        orig_to_v_data = createFolderAndRedirect(var_vnode);
    }
    public static func unmountVar() {
        UnRedirectAndRemoveFolder(orig_to_v_data);
        
    }

    
//    public static func toggleCatalogCorruption(at path: String, corrupt: Bool) throws {
//        let fd = open(path, O_RDONLY | O_CLOEXEC)
//        guard fd != -1 else { throw "Could not open target file" }
//        defer { close(fd) }
//
//        let buffer = UnsafeMutablePointer<Int>.allocate(capacity: 0x4000)
//        let n = read(fd, buffer, 0x4000)
//        var byteArray = [UInt8](Data(bytes: buffer, count: n))
//
//
//        let treeBytes: [UInt8] = [0,0,0,0, 0x74,0x72,0x65,0x65, 0,0,0]
//        let corruptBytes: [UInt8] = [67, 111, 114, 114, 117, 112, 116, 84, 104, 105, 76]
//
//        let findBytes = corrupt ? treeBytes : corruptBytes
//        let replaceBytes = corrupt ? corruptBytes : treeBytes
//
//        var startIndex = 0
//        while startIndex <= byteArray.count - findBytes.count {
//            let endIndex = startIndex + findBytes.count
//            let subArray = Array(byteArray[startIndex..<endIndex])
//
//            if subArray == findBytes {
//                byteArray.replaceSubrange(startIndex..<endIndex, with: replaceBytes)
//                startIndex += replaceBytes.count
//            } else {
//                startIndex += 1
//            }
//        }
//
//        let overwriteSucceeded = byteArray.withUnsafeBytes { dataChunkBytes in
//            return unaligned_copy_switch_race(
//                fd, 0, dataChunkBytes.baseAddress, dataChunkBytes.count, true)
//        }
//        print("overwriteSucceeded = \(overwriteSucceeded)")
//    }
}


extension String: LocalizedError {
    public var errorDescription: String? { return self }
}
