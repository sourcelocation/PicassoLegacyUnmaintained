//
//  ThemesView.swift
//  TrollTools
//
//  Created by exerhythm on 19.10.2022.
//

import MacDirtyCowSwift
import SwiftUI
import UniformTypeIdentifiers

@available(iOS 15, *)
struct ThemesView: View {
    @ObservedObject var themeManager = ThemeManager.shared
    
    @AppStorage("showCancelButtonOnThemingEnd") var showCancelButtonOnThemingEnd = false
    
    @State private var isImporting = false
    @State var isSelectingCustomIcons = false
    @State var isShowingSettings = false
    @State var easterEgg = false
    
    @State var wallpaper: UIImage?
    @State var defaultWallpaper = false
    
    private var gridItemLayout = [GridItem(.adaptive(minimum: 160))]
    
    var body: some View {
        ZStack {
            NavigationView {
                Group {
                    if themeManager.themes.count == 0 {
                        Text("No themes found. Download themes in the Explore tab,\nor import them using the button in the top right corner (Themes have to contain icons in the format of <id>.png).")
                            .padding()
                            .background(Color(uiColor14: .secondarySystemBackground))
                            .multilineTextAlignment(.center)
                            .cornerRadius(16)
                            .font(.footnote)
                            .foregroundColor(Color(uiColor14: .secondaryLabel))
                    } else {
                        ScrollView {
                            LazyVGrid(columns: gridItemLayout, spacing: 8) {
                                ForEach(themeManager.themes, id: \.name) { theme in
                                    ThemeView(theme: theme, wallpaper: wallpaper!, defaultWallpaper: defaultWallpaper)
                                        .contextMenu {
                                            Button {
                                                
                                                let alert = UIAlertController(title: NSLocalizedString("Rename theme", comment: "Entering new theme name"), message: "", preferredStyle: .alert)
                                                alert.addTextField { (textField) in
                                                    textField.placeholder = NSLocalizedString("New theme name", comment: "")
                                                }
                                                alert.addAction(UIAlertAction(title: NSLocalizedString("Rename", comment: ""), style: .default) { (action) in
                                                    do {
                                                        guard let name = alert.textFields![0].text else { return }
                                                        try themeManager.renameImportedTheme(id: theme.id, newName: name)
                                                    } catch {
                                                        UIApplication.shared.alert(body: error.localizedDescription)
                                                    }
                                                })
                                                alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel))
                                                UIApplication.shared.windows.first?.rootViewController?.present(alert, animated: true, completion: nil)
                                            } label: {
                                                Label("Rename", systemImage: "pencil")
                                            }
                                            
                                            Button {
                                                do {
                                                    try themeManager.removeImportedTheme(theme: theme)
                                                } catch {
                                                    UIApplication.shared.alert(body: error.localizedDescription)
                                                }
                                            } label: {
                                                Label("Remove theme", systemImage: "trash")
                                            }
                                        }
                                }
                            }
                            .padding()
                            
                            VStack {
                                HStack {
                                    VStack {
                                        Text(easterEgg ? "Wait, it's all TrollTools?" : "Picasso \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")")
                                            .multilineTextAlignment(.center)
                                        Text(easterEgg ? "Always has been" : "Download themes in Themes tab.")
                                            .font(.caption)
                                            .multilineTextAlignment(.center)
                                            .foregroundColor(.secondary)
                                    }
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .padding(10)
                                    .background(Color(uiColor14: .secondarySystemBackground))
                                    .cornerRadius(16)
                                    .onTapGesture {
                                        easterEgg.toggle()
                                        if easterEgg {
                                            Haptic.shared.notify(.warning)
                                        } else {
                                            Haptic.shared.notify(.success)
                                        }
                                    }
                                    VStack {
                                        HStack {
                                            Text("Alternatives")
                                                .font(.headline)
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.7)
                                                .padding(4)

                                            Text("· \(themeManager.iconOverrides.count)")
                                                .font(.headline)
                                                .foregroundColor(Color.secondary)
                                            Spacer()
                                        }
                                        NavigationLink(destination: IconOverridesView()) {
                                            Text("Change")
                                                .frame(maxWidth: .infinity)
                                                .padding(10)
                                                .background(Color(uiColor14: UIColor.tertiarySystemBackground))
                                                .cornerRadius(8)
                                                .foregroundColor(.init(uiColor14: .label))
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(10)
                                    .background(Color(uiColor14: .secondarySystemBackground))
                                    .cornerRadius(16)
                                }
                                
                                
                                Button("Rebuild Icon Cache") {
                                    UIApplication.shared.alert(title: NSLocalizedString("Scheduling a rebuild", comment: "rebuilding icon cache"), body: "", withButton: false)
                                    remvoeIconCache()
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: {
                                        respring()
                                    })
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .padding(10)
                                .background(Color(uiColor14: .secondarySystemBackground))
                                .cornerRadius(16)
                                
                                Toggle("Test: theme all icons using 1 icon", isOn: $themeManager.testThemeAllIcons) // 2
                                    .padding()
                            }
                            .padding(.bottom, 80)
                            .padding(.horizontal)
                        }
//                        .padding(.horizontal, 6)
                    }
                }
//                .padding()
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            isShowingSettings = true
                        }) {
                            Image(systemName: "gearshape")
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            isImporting = true
                        }) {
                            Image(systemName: "square.and.arrow.down")
                        }
                    }
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(role: .destructive, action: {
                            UIApplication.shared.confirmAlert(title: NSLocalizedString("Full reset", comment: "header for resetting all icons"), body: NSLocalizedString("All app icons will be reverted to their original appearance. Are you sure you want to continue? (Reboot may be required)", comment: "resetting all icons"), onOK: {
                                themeManager.preferedThemes = []
                                applyChanges()
                            }, noCancel: false)
                        }) {
                            Image(systemName: "arrow.counterclockwise")
                        }
                    }
                }
                .navigationTitle("Themes")
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .sheet(isPresented: $isImporting) {
                DocumentPicker(types: [
                    .folder
                    //UTType(filenameExtension: "theme") ?? .zip
                ]) { result in
                    if result.first == nil { UIApplication.shared.alert(body: NSLocalizedString("Couldn't get url of file. Did you select it?", comment: "")); return }
                    let url: URL = result.first!
                    if themeManager.themes.contains(where: { t in
                        t.name == url.deletingPathExtension().lastPathComponent
                    }) {
                        UIApplication.shared.alert(body: NSLocalizedString("Theme with the name \(url.deletingPathExtension().lastPathComponent) already exists. Please rename the folder.", comment: "failed to select icon"))
                        return
                    }
                    do {
                        try themeManager.importTheme(from: url)
                    } catch { UIApplication.shared.alert(body: error.localizedDescription) }
                }
            }
            .sheet(isPresented: $isShowingSettings) {
                ThemingSettingsView()
            }
            .onAppear {
                wallpaper = UIImage(named: "wallpaper") ?? UIImage(systemName: "xmark")
                defaultWallpaper = true
                
//                // Old version check
//                var shouldReset = false
//                for themeURL in (try? FileManager.default.contentsOfDirectory(at: themesDir, includingPropertiesForKeys: nil)) ?? [] {
//                    for icons in (try? FileManager.default.contentsOfDirectory(at: themeURL, includingPropertiesForKeys: nil)) ?? [] {
//                        if icons.lastPathComponent == "IconBundles" {
//                            shouldReset = true
//                            break
//                        }
//                    }
//                }
//                if shouldReset {
//                    UIApplication.shared.confirmAlert(title: "Theme reset required", body: "Due to major changes to the engine, a reset of themes is required.", onOK: {
//                        try? FileManager.default.removeItem(at: themesDir)
//                        UserDefaults.standard.set(nil, forKey: "themes")
//                        UserDefaults.standard.set(nil, forKey: "currentThemeIDs")
//                        removeThemes(removeWebClips: false)
//                    }, noCancel: true)
//                }
            }
            
            VStack {
                Spacer()
                Button(action: {
                    applyChanges()
                }) {
                    if themeManager.themes.count > 0 {
                        Text("Apply themes")
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(8)
                            .padding(.horizontal)
                            .padding(.vertical, 16)
                            .foregroundColor(.white)
                            .opacity(themeManager.preferedThemes.count > 0 ? 1 : 0)
                            .disabled(themeManager.preferedThemes.count == 0)
                            .animation(.spring().speed(1.5), value: $themeManager.preferedThemes.count)
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            themeManager.refreshThemes()
        }
    }
    func applyChanges() {
        func apply() {
            let timeStart = Date()
            DispatchQueue.global(qos: .userInitiated).async {
                UIApplication.shared.alert(title: NSLocalizedString("Starting...", comment: ""), body: NSLocalizedString("Please wait", comment: ""), animated: false, withButton: false)
                do {
                    let errors = try themeManager.applyChanges(progress: { str in
                        UIApplication.shared.change(title: NSLocalizedString("In progress...", comment: ""), body: str)
                    })
                    
                    func showSuccess() {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: {
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                            UIApplication.shared.confirmAlert(title: NSLocalizedString("Success", comment: ""), body: NSLocalizedString("⚠️⬇ PLEASE READ ⬇⚠️\n\n After the phone resprings, please *reopen Picasso* to fix apps not functioning properly\n\nElapsed time: \(Double(Int(-timeStart.timeIntervalSinceNow * 100.0)) / 100.0)s", comment: "IMPORTANT alert when icons finish applying"), confirmTitle: NSLocalizedString("Understood, Respring", comment: "Shown after successful theme set."), onOK: {
                                respring()
                            }, noCancel: !showCancelButtonOnThemingEnd)
                        })
                    }
                    
                    UIApplication.shared.change(title: NSLocalizedString("In progress...", comment: ""), body: NSLocalizedString("Scheduling icon cache reset...", comment: ""))
                    remvoeIconCache()
                    print("finished")

                    UIApplication.shared.dismissAlert(animated: false)
                    
                    if errors.isEmpty {
                        showSuccess()
                    } else {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: {
                            UIApplication.shared.confirmAlert(title: "Success, but some errors occured", body: errors.joined(separator: "\n\n"), onOK: {
                                showSuccess()
                            }, noCancel: true)
                        })
                    }
                } catch { UIApplication.shared.change(body: error.localizedDescription) }
            }
        }
        
        UIImpactFeedbackGenerator(style: .light).impactOccurred(); apply()
    }
}


@available(iOS 15, *)
struct ThemesView_Previews: PreviewProvider {
    static var previews: some View {
        ThemesView()
    }
}
