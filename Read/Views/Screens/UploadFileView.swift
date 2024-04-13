//
//  UploadFileView.swift
//  Read
//
//  Created by Mirna Olvera on 1/27/24.
//

import QuickLookThumbnailing
import RealmSwift
import SwiftReader
import SwiftUI
import WrappingHStack

func randomString(length: Int) -> String {
    let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    return String((0 ..< length).map { _ in letters.randomElement()! })
}

func getRandomURL() -> URL {
    return URL(string: "\(randomString(length: 5)).pdf")!
}

struct ImportFileListItem: View {
    var file: URL
    
    @State private var image: UIImage?
    
    var thumbnail: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "xmark")
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .aspectRatio(contentMode: .fit)
        .frame(width: 62, height: 62 * 1.77)
    }
    
    var body: some View {
        HStack {
            thumbnail
            
            VStack(alignment: .leading) {
                Text(file.lastPathComponent)
                Text("\(ByteCountFormatter.string(fromByteCount: Int64(file.size), countStyle: .file))")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
            }
            .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .task {
            let _ = file.startAccessingSecurityScopedResource()
            let size = CGSize(width: 68, height: 62 * 1.77)
            let request = QLThumbnailGenerator.Request(fileAt: file,
                                                       size: size,
                                                       scale: 1,
                                                       representationTypes: .all)

            let thumb = try? await QLThumbnailGenerator.shared.generateBestRepresentation(for: request)

            image = thumb?.uiImage
            
            file.stopAccessingSecurityScopedResource()
        }
    }
}

struct UploadFileView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(AppTheme.self) var theme
    @Environment(Toaster.self) var toaster
    
    @State private var showFilePicker = false
    @State private var filesToProcess = [URL]()
    @State private var processingBooks = false
    @State private var totalBytes: Double = 0.0
    @State private var image: UIImage?
    @State private var offset: CGFloat = .zero
    
    var showFileProcessingView: Bool {
        filesToProcess.isEmpty == false
    }
    
    init() {
        let _ = HeadlessWebView.shared.greet()
    }
    
    var uploadCard: some View {
        VStack(spacing: 18) {
            WrappingHStack(SupportedFileTypes.allCases, id: \.self, alignment: .center) { type in
                TagItem(name: ".\(type.rawValue.uppercased())", small: true)
            }
            
            Spacer()
            
            Text("Add files from your device.")
                .font(.subheadline)
                .foregroundStyle(.gray)
            
            SRButton(text: "Select Files") {
                showFilePicker = true
            }
            .frame(maxWidth: 120)
        }
        .frame(maxHeight: 198)
        .padding()
        .padding(.vertical, 12)
        .background(Color.backgroundSecondary)
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(theme.tintColor, style: StrokeStyle(lineWidth: 1, dash: [5]))
                .opacity(0.2)
        }
        .clipShape(.rect(cornerRadius: 16))
        .padding(.horizontal, 24)
    }
    
    var fileListView: some View {
        ScrollView {
            LazyVStack(pinnedViews: .sectionFooters) {
                Section {
                    ForEach(filesToProcess, id: \.self) { file in
                        ImportFileListItem(file: file)
                            .padding(.horizontal, 12)
                        
                        if filesToProcess.last != file {
                            Divider()
                                .padding(.horizontal, 24)
                        }
                    }
                } header: {
                    HStack {
                        Text("Uploads \(filesToProcess.count)")
                    
                        Spacer()
                    
                        Text("\(ByteCountFormatter.string(fromByteCount: Int64(totalBytes), countStyle: .file))")
                    }
                    .textCase(.uppercase)
                    .font(.system(size: 12))
                    .foregroundStyle(.gray)
                    .padding(.horizontal, 28)
                    
                } footer: {
                    SRButton(systemName: "square.and.arrow.down.on.square", onPress: { self.processBooks() })
                        .clipShape(.circle)
                        .disabled(processingBooks)
                }
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if showFileProcessingView {
                    fileListView
                        
                } else {
                    uploadCard
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("Upload a book")
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    SRXButton {
                        dismiss()
                    }
                }
            }
        }
        .fileImporter(isPresented: $showFilePicker, allowedContentTypes: fileTypes, allowsMultipleSelection: true) { result in
            switch result {
            case .success(let selectedFileUrls):
                filesToProcess = selectedFileUrls
                for fileUrl in selectedFileUrls {
                    totalBytes += fileUrl.size
                }
            case .failure(let failure):
                // SHOW TOAST
                print("No file selected: \(failure.localizedDescription)")
            }
        }
    }
    
    func processBooks() {
        Task {
            var failedImports = [URL]()
            processingBooks = true

            for url in filesToProcess {
                do {
                    try await BookImporter.shared.process(for: url)
                } catch {
                    failedImports.append(url)
                }
                
                filesToProcess.removeAll(where: { $0 == url })
                totalBytes -= url.size
            }
            
            if failedImports.isEmpty == false {
                toaster.presentToast(
                    message: "Failed to import \(failedImports.count) books.",
                    type: .error
                )
            }

            processingBooks = false
            dismiss()
        }
    }
}

#Preview {
    VStack {}
        .sheet(isPresented: .constant(true)) {
            UploadFileView()
        }
        .preferredColorScheme(.dark)
        .environment(AppTheme.shared)
}
