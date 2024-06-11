//
//  UploadFileView.swift
//  Read
//
//  Created by Mirna Olvera on 1/27/24.
//

import OSLog
import SReader
import SwiftUI

struct UploadFileView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(AppTheme.self) var theme
    
    @State private var showFilePicker = false
    @State private var filesToProcess = [URL]()
    
    @State private var totalBytes: Double = 0.0
    @State private var image: UIImage?
    @State private var offset: CGFloat = .zero
    
    var showFileProcessingView: Bool {
        filesToProcess.isEmpty == false
    }
    
    init() {
        MetadataExtractor.shared.loadMetadataExtractor()
    }
    
    var uploadCard: some View {
        VStack(spacing: 18) {
            WrappingStackLayout {
                ForEach(SReaderFileTypes.allCases, id: \.self) { type in
                    TagItem(name: ".\(type.rawValue.uppercased())", small: true)
                }
            }
            
            Spacer()
            
            Text("Add files from your device.")
                .font(.subheadline)
                .foregroundStyle(.gray)
            
            Button("Select Files") {
                showFilePicker = true
            }
            .buttonStyle(.main)
            .frame(maxWidth: 120)
        }
        .frame(maxHeight: 198)
        .padding()
        .padding(.vertical, 12)
        .background(Color(uiColor: .secondarySystemBackground))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(theme.tintColor, style: StrokeStyle(lineWidth: 2, dash: [8]))
                .opacity(0.2)
        }
        .clipShape(.rect(cornerRadius: 16))
        .padding(.horizontal, 24)
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if showFileProcessingView {
                    FileList(filesToProcess: $filesToProcess, totalBytes: $totalBytes)
                        
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
                Logger.general.info("No file selected: \(failure.localizedDescription)")
            }
        }
    }
}

#Preview {
    VStack {}
        .sheet(isPresented: .constant(true)) {
            UploadFileView()
        }
        .environment(AppTheme.shared)
}
