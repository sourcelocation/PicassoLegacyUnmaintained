//
//  RootView.swift
//  Picasso
//
//  Created by lemin on 1/6/23.
//

import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
//            ThemesView()
//                .tabItem {
//                    Label("Audio", systemImage: "speaker.wave.2.fill")
//                }
            ToolsView()
                .tabItem {
                    Label("Tools", systemImage: "wrench.and.screwdriver.fill")
                }
//            if #available(iOS 15.0, *) {
//                ThemesView()
//                    .tabItem {
//                        Label("Themes", systemImage: "paintbrush")
//                    }
//            }
//            SpringBoardView()
//                .tabItem {
//                    Label("SpringBoard", systemImage: "snowflake")
//                }
            /*AudioView()
                .tabItem {
                    Label("Audio", systemImage: "speaker.wave.2.fill")
                }*/
            if #available(iOS 15.0, *) {
                ThemesExploreView()
                    .tabItem {
                        Label("Explore", systemImage: "safari")
                    }
            }
//            PasscodeEditorView()
//                .tabItem {
//                    Label("Passcode", systemImage: "key")
//                }
//            LockView()
//                .tabItem {
//                    Label("Lock", systemImage: "lock")
//                }
//            OtherModsView()
//                .tabItem {
//                    Label("Misc.", systemImage: "hammer")
//                }
        }
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}
