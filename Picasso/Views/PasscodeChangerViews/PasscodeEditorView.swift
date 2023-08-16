//
//  PasscodeEditorView.swift
//  DebToIPA
//
//  Created by exerhythm on 15.10.2022.
//

import SwiftUI
import Photos

struct PasscodeEditorView: View {
    @State private var ipadView: Bool = false
    
    @State private var showingImagePicker = false
    @State private var faces: [UIImage?] = [UIImage?](repeating: nil, count: 12)
    @State private var changedFaces: [Bool] = [Bool](repeating: false, count: 12)
    @State private var canChange = false // needed to make sure it does not reset the size on startup
    @State private var changingFaceN = 0
    @State private var isBig = false
    @State private var customSize: [String] = [String(KeySize.small.rawValue), String(KeySize.small.rawValue)]
    @State private var currentSize: Int = 0
    //@State private var sizeButtonState = KeySizeState.small
    @State private var isImporting = false
    @State private var isExporting = false
    @State private var showingSaved = false
    
    @State private var directoryType: TelephonyDirType = TelephonyDirType.passcode
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    
    @State private var sizeLimit: [Int] = [PasscodeSizeLimit.min.rawValue, PasscodeSizeLimit.max.rawValue] // the limits of the custom size (max, min)
    
    let fm = FileManager.default
    
    var body: some View {
        GeometryReader { proxy in
            //let minSize = min(proxy.size.width, proxy.size.height)
            ZStack(alignment: .center) {
                Image(uiImage: UIImage(named: "wallpaper")!)//WallpaperGetter.lockscreen() ?? UIImage(named: "wallpaper")!)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .scaleEffect(1.5)
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .offset(y: UIApplication.shared.windows[0].safeAreaInsets.top)
                MaterialView(.light)
                    .brightness(-0.4)
                    .ignoresSafeArea()
                
                //                Rectangle()
                //                    .background(Material.ultraThinMaterial)
                //                    .ignoresSafeArea()
                //                    .preferredColorScheme(.dark)
                
                VStack {
                    Text((directoryType == .passcode) ? "Passcode Face Editor" : "Dialer Face Editor")
                        .foregroundColor(.white)
                        .font(.title2)
                        .padding(1)
                    Text("Tap on any key to edit \nits appearance")
                        .foregroundColor(.white)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .lineSpacing(-4)
                    
                    VStack(spacing: 16) {
                        if directoryType == .passcode {
                            ForEach((0...2), id: \.self) { y in
                                HStack(spacing: 22) {
                                    ForEach((0...2), id: \.self) { x in
                                        PasscodeKeyView(face: faces[y * 3 + x + 1], action: { showPicker(y * 3 + x + 1) }, ipadView: ipadView)
                                    }
                                }
                            }
                            HStack(spacing: 22) {
                                // zero key
                                PasscodeKeyView(face: faces[0], action: { showPicker(0) }, ipadView: ipadView)
                            }
                        } else {
                            ForEach((0...3), id: \.self) { y in
                                HStack(spacing: 22) {
                                    ForEach((0...2), id: \.self) { x in
                                        let num = y * 3 + x + 1
                                        if num == 11 {
                                            PasscodeKeyView(face: faces[0], action: { showPicker(0) }, ipadView: ipadView)
                                        } else if num == 12 {
                                            PasscodeKeyView(face: faces[num-1], action: { showPicker(num-1) }, ipadView: ipadView)
                                        } else {
                                            PasscodeKeyView(face: faces[num], action: { showPicker(num) }, ipadView: ipadView)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.top, 16)
                }
                .offset(x: 0, y: -35)
                VStack {
                    Spacer()
                    if currentSize == -1 {
                        HStack {
                            TextField("X", text: $customSize[0])
                                .foregroundColor(.white)
                                .multilineTextAlignment(.trailing)
                                .padding(.horizontal, 5)
                                .font(.system(size: 25))
                                .minimumScaleFactor(0.5)
                                .frame(width: 100, height: 40)
                                .textFieldStyle(PlainTextFieldStyle())
                            Text("x")
                                .foregroundColor(.white)
                                .font(.title2)
                                .padding(5)
                            TextField("Y", text: $customSize[1])
                                .foregroundColor(.white)
                                .padding(.horizontal, 5)
                                .font(.system(size: 25))
                                .minimumScaleFactor(0.5)
                                .frame(width: 100, height: 40)
                                .textFieldStyle(PlainTextFieldStyle())
                        }
                        .padding(.bottom, 70)
                    }
                }
                
                VStack {
                    Spacer()
                    HStack {
                        Button("Reset faces") {
                            do {
                                try PasscodeKeyFaceManager.reset(directoryType)
                                if directoryType == .passcode {
                                    respring()
                                } else {
                                    UIApplication.shared.alert(title: NSLocalizedString("Dialer keys successfully cleared!", comment: ""), body: NSLocalizedString("Please close and reopen the Phone app.", comment: ""))
                                }
                            } catch {
                                UIApplication.shared.alert(body: NSLocalizedString("An error occured.", comment: "") + " \(error)")
                            }
                        }
                        Spacer()
                        Button("Choose size") {
                            // create and configure alert controller
                            let alert = UIAlertController(title: NSLocalizedString("Choose a size", comment: "Choose a size for passcode keys"), message: "", preferredStyle: .actionSheet)
                            
                            // create the actions
                            let defaultAction = UIAlertAction(title: NSLocalizedString("Default", comment: "Default passcode size"), style: .default) { (action) in
                                // set the size back to default
                                currentSize = PasscodeKeyFaceManager.getDefaultFaceSize()
                                
                                askToUpdate()
                            }
                            
                            let smallAction = UIAlertAction(title: NSLocalizedString("Small", comment: "Small passcode keys"), style: .default) { (action) in
                                // set the size to small
                                customSize[0] = String(KeySize.small.rawValue)
                                customSize[1] = String(KeySize.small.rawValue)
                                currentSize = -2
                                
                                askToUpdate()
                            }
                            
                            let bigAction = UIAlertAction(title: NSLocalizedString("Big", comment: "Big passcode keys"), style: .default) { (action) in
                                // set the size to big
                                customSize[0] = String(KeySize.big.rawValue)
                                customSize[1] = String(KeySize.big.rawValue)
                                currentSize = -2
                                
                                askToUpdate()
                            }
                            
                            let customAction = UIAlertAction(title: NSLocalizedString("Custom", comment: "Custom size for passcode keys"), style: .default) { (action) in
                                // ask the user for a custom size
                                let sizeAlert = UIAlertController(title: NSLocalizedString("Enter Key Dimensions", comment: "dimensions for passcode keys"), message: NSLocalizedString("Min:", comment: "Minimum passcode key size") + "\(sizeLimit[0]), " + NSLocalizedString("Max:", comment: "Maximum passcode key size") + " \(sizeLimit[1])", preferredStyle: .alert)
                                // bring up the text prompts
                                sizeAlert.addTextField { (textField) in
                                    // text field for width
                                    textField.placeholder = NSLocalizedString("Width", comment: "Width of passcode keys")
                                }
                                sizeAlert.addTextField { (textField) in
                                    // text field for height
                                    textField.placeholder = NSLocalizedString("Height", comment: "Height of passcode keys")
                                }
                                sizeAlert.addAction(UIAlertAction(title: NSLocalizedString("Confirm", comment: ""), style: .default) { (action) in
                                    // set the sizes
                                    // check if they entered something and if it is in bounds
                                    let width: Int = Int(sizeAlert.textFields?[0].text! ?? "-1") ?? -1
                                    let height: Int = Int(sizeAlert.textFields?[1].text! ?? "-1") ?? -1
                                    if (width >= sizeLimit[0] && width <= sizeLimit[1]) && (height >= sizeLimit[0] && height <= sizeLimit[1]) {
                                        // good to go
                                        customSize[0] = String(width)
                                        customSize[1] = String(height)
                                        currentSize = -1
                                        
                                        askToUpdate()
                                    } else {
                                        // alert that it was not a valid size
                                        UIApplication.shared.alert(body: NSLocalizedString("Not a valid size!", comment: "Not a valid size input for passcode keys"))
                                    }
                                })
                                sizeAlert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel) { (action) in
                                    // cancel the process
                                })
                                UIApplication.shared.windows.first?.rootViewController?.present(sizeAlert, animated: true, completion: nil)
                            }
                            
                            // determine which to put a check on
                            if currentSize > 0 {
                                defaultAction.setValue(true, forKey: "checked")
                            } else if currentSize == -2 && Int(customSize[0]) == Int(KeySize.small.rawValue) && Int(customSize[1]) == Int(KeySize.small.rawValue) {
                                smallAction.setValue(true, forKey: "checked")
                            } else if currentSize == -2 && Int(customSize[0]) == Int(KeySize.big.rawValue) && Int(customSize[1]) == Int(KeySize.big.rawValue) {
                                bigAction.setValue(true, forKey: "checked")
                            } else {
                                customAction.setValue(true, forKey: "checked")
                            }
                            
                            let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel) { (action) in
                                // cancels the action
                            }
                            
                            // add the actions
                            alert.addAction(defaultAction)
                            alert.addAction(smallAction)
                            alert.addAction(bigAction)
                            alert.addAction(customAction)
                            alert.addAction(cancelAction)
                            
                            let view: UIView = UIApplication.shared.windows.first!.rootViewController!.view
                            // present popover for iPads
                            alert.popoverPresentationController?.sourceView = view // prevents crashing on iPads
                            alert.popoverPresentationController?.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.maxY, width: 0, height: 0) // show up at center bottom on iPads
                            
                            // present the alert
                            UIApplication.shared.windows.first?.rootViewController?.present(alert, animated: true)
                        }
                        Spacer()
                        Button("Remove all") {
                            do {
                                try PasscodeKeyFaceManager.removeAllFaces(directoryType)
                                faces = try PasscodeKeyFaceManager.getFaces(directoryType, colorScheme: colorScheme)
                            } catch {
                                UIApplication.shared.alert(body: NSLocalizedString("An error occured.", comment: "") + " \(error)")
                            }
                        }
                    }
                    .foregroundColor(.white)
                    .padding(32)
                }
                
                // MARK: Change directory type arrows
                if directoryType == .passcode {
                    HStack {
                        Spacer()
                        Button(action: {
                            directoryType = .dialer
                            ipadView = PasscodeKeyFaceManager.getDefaultFaceSize() == KeySize.small.rawValue ? true : false
                            currentSize = PasscodeKeyFaceManager.getDefaultFaceSize()
                            do {
                                faces = try PasscodeKeyFaceManager.getFaces(directoryType, colorScheme: colorScheme)
                                
                                if let faces = UserDefaults.standard.array(forKey: "changedFaces") as? [Bool] {
                                    changedFaces = faces
                                }
                            } catch {
                                UIApplication.shared.alert(body: NSLocalizedString("An error occured.", comment: "") + " \(error)")
                            }
                        }) {
                            Image(systemName: "arrow.right.square")
                        }
                        .font(.system(size: 30))
                        .padding(10)
                    }
                } else if directoryType == .dialer {
                    HStack {
                        Button(action: {
                            directoryType = .passcode
                            ipadView = PasscodeKeyFaceManager.getDefaultFaceSize() == KeySize.small.rawValue ? true : false
                            currentSize = PasscodeKeyFaceManager.getDefaultFaceSize()
                            do {
                                faces = try PasscodeKeyFaceManager.getFaces(directoryType, colorScheme: colorScheme)
                                
                                if let faces = UserDefaults.standard.array(forKey: "changedFaces") as? [Bool] {
                                    changedFaces = faces
                                }
                            } catch {
                                UIApplication.shared.alert(body: NSLocalizedString("An error occured.", comment: "") + " \(error)")
                            }
                        }) {
                            Image(systemName: "arrow.left.square")
                        }
                        .font(.system(size: 30))
                        .padding(10)
                        Spacer()
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // import button
            HStack {
                Button(action: {
                    if #available(iOS 15, *) {
                        // ask whether they are importing from file or saved
                        // create and configure alert controller
                        let alert = UIAlertController(title: NSLocalizedString("Import Passcode Theme", comment: "Header for importing passcode theme"), message: NSLocalizedString("From where do you want to import from?", comment: "Where to import passcode theme from"), preferredStyle: .actionSheet)
                        
                        // create the actions
                        let filesAction = UIAlertAction(title: NSLocalizedString("Files", comment: "Import passcode theme from files"), style: .default) { (action) in
                            // open file importer
                            isImporting = true
                        }
                        
                        let savedAction = UIAlertAction(title: NSLocalizedString("Saved", comment: "Import passcode theme from saved"), style: .default) { (action) in
                            // import from saved passcode files
                            showingSaved = true
                        }
                        
                        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel) { (action) in
                            // cancels the action
                        }
                        
                        // add the actions
                        alert.addAction(filesAction)
                        alert.addAction(savedAction)
                        alert.addAction(cancelAction)
                        
                        let view: UIView = UIApplication.shared.windows.first!.rootViewController!.view
                        // present popover for iPads
                        alert.popoverPresentationController?.sourceView = view // prevents crashing on iPads
                        alert.popoverPresentationController?.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.maxY, width: 0, height: 0) // show up at center bottom on iPads
                        
                        // present the alert
                        UIApplication.shared.windows.first?.rootViewController?.present(alert, animated: true)
                    } else {
                        isImporting = true
                    }
                }) {
                    Image(systemName: "square.and.arrow.down")
                }
                .foregroundColor(.blue)
                
                // export key
                Button(action: {
                    do {
                        let archiveURL: URL? = try PasscodeKeyFaceManager.exportFaceTheme(directoryType)
                        // show share menu
                        let avc = UIActivityViewController(activityItems: [archiveURL!], applicationActivities: nil)
                        let view: UIView = UIApplication.shared.windows.first!.rootViewController!.view
                        avc.popoverPresentationController?.sourceView = view // prevents crashing on iPads
                        avc.popoverPresentationController?.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.maxY, width: 0, height: 0) // show up at center bottom on iPads
                        UIApplication.shared.windows.first?.rootViewController?.present(avc, animated: true)
                    } catch {
                        UIApplication.shared.alert(body: NSLocalizedString("An error occured while exporting key face.", comment: "Passcode export error"))
                    }
                }) {
                    Image(systemName: "square.and.arrow.up")
                }
                .foregroundColor(.blue)
            }
        }
        .sheet(isPresented: $isImporting) {
            DocumentPicker(
                types: [
                    //.folder
                    UTType(filenameExtension: "passthm") ?? .zip
                ]
            ) { result in
                verifySize()
                if result.first == nil { UIApplication.shared.alert(body: NSLocalizedString("Couldn't get url of file. Did you select it?", comment: "")); return }
                let url: URL = result.first!
                do {
                    // try appying the themes
                    try PasscodeKeyFaceManager.setFacesFromTheme(url, directoryType, colorScheme: colorScheme, keySize: CGFloat(currentSize), customX: CGFloat(Int(customSize[0]) ?? 150), customY: CGFloat(Int(customSize[1]) ?? 150))
                    faces = try PasscodeKeyFaceManager.getFaces(directoryType, colorScheme: colorScheme)
                } catch { UIApplication.shared.alert(body: error.localizedDescription) }
            }
        }
        .sheet(isPresented: $showingSaved) {
            SavedPasscodesView(isVisible: $showingSaved, faces: $faces, dir: directoryType)
        }
        .onAppear {
            ipadView = PasscodeKeyFaceManager.getDefaultFaceSize() == KeySize.small.rawValue ? true : false
            currentSize = PasscodeKeyFaceManager.getDefaultFaceSize()
            do {
                faces = try PasscodeKeyFaceManager.getFaces(directoryType, colorScheme: colorScheme)
                
                if let faces = UserDefaults.standard.array(forKey: "changedFaces") as? [Bool] {
                    changedFaces = faces
                }
            } catch {
                UIApplication.shared.alert(body: NSLocalizedString("An error occured.", comment: "") + " \(error)")
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePickerView(image: $faces[changingFaceN], didChange: $canChange)
        }
        .onChange(of: faces[changingFaceN] ?? UIImage()) { newValue in
            print(newValue)
            if canChange {
                canChange = false
                // reset the size if too big or small
                verifySize()
                
                do {
                    try PasscodeKeyFaceManager.setFace(newValue, for: PasscodeKeyFaceManager.CharacterTable[changingFaceN], directoryType, colorScheme: colorScheme, keySize: CGFloat(currentSize), customX: CGFloat(Int(customSize[0]) ?? 150), customY: CGFloat(Int(customSize[1]) ?? 150))
                    faces[changingFaceN] = try PasscodeKeyFaceManager.getFace(for: PasscodeKeyFaceManager.CharacterTable[changingFaceN], mask: (colorScheme == .light), directoryType)
                } catch {
                    UIApplication.shared.alert(body: NSLocalizedString("An error occured while changing key face.", comment: "") + " \(error)")
                }
            }
        }
    }
    func showPicker(_ n: Int) {
        changingFaceN = n
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            DispatchQueue.main.async {
                showingImagePicker = status == .authorized
            }
        }
    }
    
    func askToUpdate() {
        let updateAlert = UIAlertController(title: NSLocalizedString("Apply for all?", comment: "Header for apply passcode key size for all"), message: NSLocalizedString("Would you like to apply this size for all currently active keys? Otherwise, it will only apply to new faces.", comment: "Message for apply passcode key size for all"), preferredStyle: .alert)
        
        updateAlert.addAction(UIAlertAction(title: NSLocalizedString("Yes", comment: "Confirm apply for all (passcode keys)"), style: .default) { (action) in
            // apply to all
            do {
                try PasscodeKeyFaceManager.setFacesFromTheme(try PasscodeKeyFaceManager.telephonyUIURL(directoryType), directoryType, colorScheme: colorScheme, keySize: CGFloat(-1), customX: CGFloat(Int(customSize[0]) ?? 150), customY: CGFloat(Int(customSize[1]) ?? 150))
                faces = try PasscodeKeyFaceManager.getFaces(directoryType, colorScheme: colorScheme)
            } catch {
                UIApplication.shared.alert(body: NSLocalizedString("An error occured when applying face sizes.", comment: "") + " \(error)")
            }
        })
        
        updateAlert.addAction(UIAlertAction(title: NSLocalizedString("No", comment: "Decline apply for all (passcode keys)"), style: .cancel) { (action) in
            // don't apply
        })
        UIApplication.shared.windows.first?.rootViewController?.present(updateAlert, animated: true, completion: nil)
    }
    
    func verifySize() {
        if (Int(customSize[0]) ?? 152 > sizeLimit[1]) {
            // above max size
            customSize[0] = String(sizeLimit[1])
        } else if (Int(customSize[0]) ?? 152 < sizeLimit[0]) {
            // below min size
            customSize[0] = String(sizeLimit[0])
        }
        
        if (Int(customSize[1]) ?? 152 > sizeLimit[1]) {
            // above max size
            customSize[1] = String(sizeLimit[1])
        } else if (Int(customSize[1]) ?? 152 < sizeLimit[0]) {
            // below min size
            customSize[1] = String(sizeLimit[0])
        }
    }
}

struct PasscodeKeyView: View {
    var face: UIImage?
    var action: () -> ()
    var ipadView: Bool
    
    var body: some View {
        Button {
            action()
        } label: {
            ZStack {
                Circle()
                    .fill(Color(UIColor(red: 1, green: 1, blue: 1, alpha: 0.12)))
                    .frame(width: 78, height: 78) // background circle
                Circle()
                    .fill(Color(UIColor(red: 1, green: 1, blue: 1, alpha: 0))) // hidden circle for image
                if face == nil {
                    Image(systemName: "plus")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    if ipadView {
                        // scale correctly for ipad
                        Image(uiImage: face!)
                            .resizable()
                            .frame(width: CGFloat(Float(face!.size.width)/2.1), height: CGFloat(Float(face!.size.height)/2.1))
                    } else {
                        // normal (for phones)
                        Image(uiImage: face!)
                            .resizable()
                            .frame(width: CGFloat(Float(face!.size.width)/3), height: CGFloat(Float(face!.size.height)/3))
                    }
                }
            }
            .frame(width: 80, height: 80)
        }
    }
}



struct PasscodeEditorView_Previews: PreviewProvider {
    static var previews: some View {
        PasscodeEditorView()
    }
}
