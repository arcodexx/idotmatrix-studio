import SwiftUI

struct DivoomLibraryView: View {
    @ObservedObject var client = DivoomClient.shared
    @ObservedObject var viewModel = ViewModel.shared

    @State private var email = ""
    @State private var password = ""
    @State private var showingLogin = false
    @State private var loginError: String?
    @State private var isLoggingIn = false

    @State private var selectedCategory: DivoomCategory = .recommend
    @State private var files: [DivoomFile] = []
    @State private var isLoading = false
    @State private var currentPage = 1
    @State private var errorMsg: String?
    @State private var hasMorePages = true

    // Grid layout
    let columns = [
        GridItem(.adaptive(minimum: 160))
    ]

    var body: some View {
        VStack {
            // Header
            HStack {
                Text("Divoom Community Library")
                    .bold()

                Spacer()

                if client.isLoggedIn {
                    Text("Recommended")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Button("Sign Out") {
                        client.isLoggedIn = false
                        client.currentUser = nil
                        UserDefaults.standard.removeObject(forKey: "divoom_email")
                        UserDefaults.standard.removeObject(forKey: "divoom_password")
                        files.removeAll()
                    }
                    .font(.caption)
                    .buttonStyle(.borderless)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 8)
                }
            }
            .padding()

            if !client.isLoggedIn {
                // Login View
                VStack(spacing: 16) {
                    Image(systemName: "globe.americas.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.blue.gradient)

                    Text("Divoom Community Gallery")
                        .font(.title2.bold())

                    Text("Browse and stream thousands of community pixel art animations directly to your LED display.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 380)

                    VStack(spacing: 10) {
                        TextField("Divoom Account Email", text: $email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 320)

                        SecureField("Divoom Password", text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 320)
                    }
                    .padding(.top, 4)

                    if let err = loginError {
                        Text(err)
                            .font(.caption)
                            .foregroundColor(.red)
                    }

                    Button(action: login) {
                        if isLoggingIn {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Text("Sign In")
                                .frame(width: 120)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isLoggingIn || email.isEmpty || password.isEmpty)

                    Divider()
                        .frame(width: 320)
                        .padding(.vertical, 8)

                    VStack(spacing: 8) {
                        Text("Don't have a Divoom account? Download the app to register:")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 20) {
                            Link(destination: URL(string: "https://apps.apple.com/us/app/divoom-pixel-art-community/id1237452417")!) {
                                Label("iOS App Store", systemImage: "applelogo")
                                    .font(.caption)
                            }

                            Link(destination: URL(string: "https://play.google.com/store/apps/details?id=com.divoom.Divoom")!) {
                                Label("Google Play (Android)", systemImage: "play.circle")
                                    .font(.caption)
                            }
                        }
                    }
                }
                .padding(30)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Gallery View
                ScrollView {
                    if isLoading && files.isEmpty {
                        ProgressView("Loading...")
                            .padding()
                    } else {
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(files) { file in
                                DivoomGalleryItemView(file: file, viewModel: viewModel)
                            }

                            // Pagination trigger
                            if !files.isEmpty && !isLoading {
                                Color.clear
                                    .frame(height: 20)
                                    .onAppear {
                                        loadMore()
                                    }
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .onChange(of: selectedCategory) { _ in
            reloadGallery()
        }
        .onChange(of: client.isLoggedIn) { loggedIn in
            if loggedIn && files.isEmpty {
                reloadGallery()
            }
        }
        .task {
            if client.isLoggedIn {
                if files.isEmpty {
                    reloadGallery()
                }
            } else if let emailToUse = UserDefaults.standard.string(forKey: "divoom_email"),
                       let passToUse = UserDefaults.standard.string(forKey: "divoom_password"),
                       !emailToUse.isEmpty, !passToUse.isEmpty {
                self.email = emailToUse
                self.password = passToUse
                isLoggingIn = true
                do {
                    _ = try await client.login(email: emailToUse, password: passToUse)
                    await MainActor.run {
                        self.isLoggingIn = false
                        reloadGallery()
                    }
                } catch {
                    await MainActor.run {
                        self.isLoggingIn = false
                        loginError = error.localizedDescription
                    }
                }
            }
        }
    }
    // MARK: - Actions

    func login() {
        isLoggingIn = true
        loginError = nil
        Task {
            do {
                _ = try await client.login(email: email, password: password)
                await MainActor.run {
                    isLoggingIn = false
                    reloadGallery()
                }
            } catch {
                await MainActor.run {
                    isLoggingIn = false
                    loginError = error.localizedDescription
                }
            }
        }
    }

    func reloadGallery() {
        files = []
        currentPage = 1
        hasMorePages = true
        loadMore()
    }

    func loadMore() {
        guard !isLoading && hasMorePages else { return }
        isLoading = true

        Task {
            do {
                let newFiles = try await client.fetchFiles(category: selectedCategory, page: currentPage)
                await MainActor.run {
                    if newFiles.isEmpty {
                        hasMorePages = false
                    } else {
                        files.append(contentsOf: newFiles)
                        currentPage += 1
                    }
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMsg = error.localizedDescription
                    isLoading = false
                    print("Gallery error: \(error)")
                }
            }
        }
    }
}

struct DivoomGalleryItemView: View {
    let file: DivoomFile
    @ObservedObject var viewModel: ViewModel

    @State private var previewUrl: URL?
    @State private var isConverting = false
    @State private var errorMsg: String?
    @State private var isSaved = false

    var body: some View {
        VStack {
            // Preview / Placeholder Area
            ZStack {
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: 160)
                    .cornerRadius(8)

                if let previewUrl = previewUrl {
                    // Show Animated GIF
                    GifView(url: previewUrl)
                        .frame(height: 160)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    // Loading / Placeholder / Error
                    if errorMsg != nil {
                         Image(systemName: "exclamationmark.triangle")
                             .foregroundStyle(.gray)
                    } else {
                         VStack {
                              ProgressView()
                                  .controlSize(.small)
                         }
                    }
                }
            }
            .onAppear { // Auto load
                if previewUrl == nil {
                    loadPreview()
                }
            }

            Text(file.fileName)
                .font(.caption)
                .lineLimit(1)
                .truncationMode(.tail)

            if previewUrl != nil {
                HStack {
                    Button("Send") {
                        sendToDevice()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)

                    // TODO: Add Save Button
                    if isSaved {
                        Label("Saved", systemImage: "checkmark")
                            .foregroundStyle(.green)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().stroke(Color.green))
                            .controlSize(.small)
                            .font(.caption)
                    } else {
                        Button("Save") {
                            saveToAssets()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
            }
        }
        .frame(width: 180)
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.2)))
    }

    func saveToAssets() {
        guard let url = previewUrl, let data = try? Data(contentsOf: url) else { return }
        AssetManager.shared.saveGif(name: file.fileName, data: data)
        withAnimation {
            isSaved = true
        }
    }

    func loadPreview() {
        guard !isConverting else { return }
        isConverting = true

        Task {
            // Use constructed URL fallback
            guard let url = file.constructedUrl else {
                isConverting = false
                return
            }

            if let convertedUrl = await viewModel.convertDivoomFile(url: url) {
                await MainActor.run {
                    self.previewUrl = convertedUrl
                    self.isConverting = false
                }
            } else {
                 await MainActor.run {
                     self.isConverting = false
                     self.errorMsg = "Failed" // Set Error
                 }
            }
        }
    }

    func sendToDevice() {
        guard let url = previewUrl else { return }
        Task {
            if let data = try? Data(contentsOf: url) {
                await viewModel.sendGif(data)
            }
        }
    }
}
