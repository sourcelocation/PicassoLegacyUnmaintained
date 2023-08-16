//
//  LoginView.swift
//  Evyrest
//
//  Created by exerhythm on 30.11.2022.
//

import SwiftUI

struct LoginView: View {
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) var openURL
    
    var onLogin: () -> ()
    
    @State var username = ""
    @State var password = ""
    
    @StateObject var sourceRepoFetcher = SourcedRepoFetcher.shared
    
    var body: some View {
        VStack {
            Spacer()
            HStack(alignment: .center, spacing: 20) {
                Image("AppIcon-preview")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 64)
                Text("Welcome to\nPicasso")
                    .font(.system(size: 32, weight: .bold))
                    .multilineTextAlignment(.leading)
            }
            HStack {
                Image(systemName: "lanyardcard")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(.accentColor)
                    .frame(height: 24)
                Text("Please log in into your Sourced Repo account to continue")
                    .padding(10)
            }
            TextField("Email", text: $username)
                .textFieldStyle(.roundedBorder)
                .padding(4)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                .autocorrectionDisabled(true)
            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 4)
                .autocorrectionDisabled(true)
            
            Spacer()
            Button("Forgot password?") {
                openURL(.init(string: "https://repo.sourceloc.net/skill-issue")!)
            }
            .padding(4)
            Button(action: {
                Task {
                    do {
                        try await sourceRepoFetcher.login(username: username, password: password)
//                        try await sourceRepoFetcher.linkDevice()
                        dismiss()
                        
                        onLogin()
                    } catch {
                        DispatchQueue.main.async {
                            UIApplication.shared.alert(body: "\(error.localizedDescription)")
                        }
                    }
                }
            }) {
                Text("Log in")
                    .padding(12)
                    .frame(maxWidth: .infinity)
                    .background(Color.accentColor)
                    .foregroundColor(.init(uiColor14: .systemBackground))
                    .cornerRadius(12)
            }
        }
        .padding()
        .frame(maxWidth: 325, maxHeight: .infinity)
        .interactiveDismissDisabled()
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(onLogin: {})
    }
}
