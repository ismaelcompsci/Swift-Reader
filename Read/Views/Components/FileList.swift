//
//  FileList.swift
//  Read
//
//  Created by Mirna Olvera on 4/18/24.
//

@preconcurrency import QuickLookThumbnailing
import SwiftUI

struct FileListItem: View {
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

struct FileList: View {
    @Environment(\.dismiss) var dismiss
    @Environment(Toaster.self) var toaster
    @Environment(AppTheme.self) var theme
    
    @State private var processingBooks = false
    
    @Binding var filesToProcess: [URL]
    @Binding var totalBytes: Double
    
    var body: some View {
        ScrollView {
            LazyVStack(pinnedViews: .sectionFooters) {
                Section {
                    ForEach(filesToProcess, id: \.self) { file in
                        FileListItem(file: file)
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
                    .font(.caption)
                    .foregroundStyle(.gray)
                    .padding(.horizontal, 28)
                    
                } footer: {
                    Button {
                        self.processBooks()
                    } label: {
                        Label("Add Books", systemImage: "plus.circle")
                    }
                    .buttonStyle(.main)
                    .frame(maxWidth: 164)
                    .disabled(processingBooks)
                }
            }
        }
    }
    
    func processBooks() {
        Task {
            var failedImports = [URL]()
            processingBooks = true

            for url in filesToProcess {
                do {
                    try await BookManager.shared.process(for: url)
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
    FileList(filesToProcess: .constant([]), totalBytes: .constant(0))
        .environment(AppTheme.shared)
        .environment(Toaster.shared)
}
