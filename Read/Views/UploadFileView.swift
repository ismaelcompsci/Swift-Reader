//
//  UploadFileView.swift
//  Read
//
//  Created by Mirna Olvera on 1/27/24.
//

import RealmSwift
import SwiftUI
import WrappingHStack

struct UploadFileView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appColor: AppColor
    @Environment(\.verticalSizeClass) var verticalSizeClass: UserInterfaceSizeClass?
    @Environment(\.horizontalSizeClass) var horizontalSizeClass: UserInterfaceSizeClass?

    @ObservedResults(Book.self) var books

    @State private var showFilePicker: Bool = false
    @State var fileUrls: [URL] = .init()
    @State private var totalBytes = 0.0
    @State private var processingBook = false

    private var hasFilesToProccess: Bool {
        fileUrls.count > 0
    }

    // needed
    let hello = HeadlessWebView.shared.greet()

    var fileList: some View {
        VStack {
            List {
                ForEach(fileUrls, id: \.self) { file in

                    HStack {
                        VStack(alignment: .leading) {
                            Text(file.lastPathComponent)
                            Text("\(ByteCountFormatter.string(fromByteCount: Int64(file.size), countStyle: .file))")
                                .font(.subheadline)
                                .foregroundStyle(.gray)
                        }
                    }
                    .listRowBackground(Color.accentBackground)
                    .contextMenu {
                        Button("Remove", systemImage: "trash.fill", role: .destructive) {
                            guard let urlIndex = fileUrls.firstIndex(where: { url in
                                url.lastPathComponent == file.lastPathComponent
                            }) else {
                                print("file not found")
                                return
                            }

                            fileUrls.remove(at: urlIndex)
                        }
                    }
                }
                .onDelete(perform: removeFile)
            }
            .scrollIndicators(ScrollIndicatorVisibility.hidden)
            Spacer()
                .frame(maxHeight: 24)

            VStack(alignment: .center) {
                Text("\(fileUrls.count) files")

                Text("\(ByteCountFormatter.string(fromByteCount: Int64(totalBytes), countStyle: .file))")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
            }
            .frame(maxWidth: .infinity)

            Button {
                processBooks()
            } label: {
                if processingBook {
                    ProgressView()
                        .padding()
                        .foregroundStyle(.white)
                        .tint(appColor.accent)
                        .background(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                } else {
                    Text("Add \(fileUrls.count == 1 ? "book" : "books")")
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .foregroundStyle(.white)
                        .background(appColor.accent)
                        .clipShape(.capsule)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .disabled(processingBook)
        }
    }

    var fileUploadCard: some View {
        GeometryReader { geo in
            VStack(alignment: .center) {
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .strokeBorder(appColor.accent, style: StrokeStyle(lineWidth: 1, dash: [5]))
                        .opacity(0.5)
                        .zIndex(10)

                    VStack {
                        // MARK: Upload File Button

                        WrappingHStack(SupportedFileTypes.allCases, id: \.self, alignment: .center) { type in
                            Text(".\(type.rawValue.uppercased())")
                                .font(.system(size: 10))
                                .lineLimit(1)
                                .padding(.vertical, 2)
                                .padding(.horizontal, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 24)
                                        .stroke(Color.gray.opacity(0.7), lineWidth: 1)
                                )
                                .padding(2)
                        }
                        .frame(maxWidth: geo.size.width * 0.7, maxHeight: .infinity, alignment: .center)

                        Text("Add files from your phone")
                            .font(.subheadline)
                            .foregroundStyle(.gray)

                        AppButton(text: "Select Files") {
                            showFilePicker = true
                        }
                        .frame(maxWidth: 120, maxHeight: .infinity, alignment: .top)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.backgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                }
                .transition(.move(edge: .bottom))
                .frame(maxHeight: horizontalSizeClass == .compact ? geo.size.height * 0.35 : geo.size.height * 0.5, alignment: .bottomTrailing)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                // MARK: Header

                Spacer()

                if hasFilesToProccess {
                    // MARK: Files to Process List

                    fileList

                } else {
                    // MARK: File Upload Card

                    fileUploadCard
                }

                Spacer()
            }
            .padding(14)
            .fileImporter(isPresented: $showFilePicker, allowedContentTypes: fileTypes, allowsMultipleSelection: true) { result in
                switch result {
                case .success(let selectedFileUrls):
                    fileUrls = selectedFileUrls
                    for fileUrl in fileUrls {
                        totalBytes += fileUrl.size
                    }
                case .failure(let failure):
                    print("No file selected: \(failure.localizedDescription)")
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("Upload a book")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    }
                    label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16))
                            .foregroundStyle(appColor.accent.opacity(0.7))
                    }
                }
            }
        }
    }

    func processBooks() {
        Task {
            processingBook = true
            for url in fileUrls {
                // made async instead of closure so that a large number of books are not being proccessed at the same time
                if let metadata = try? await BookMetadataExtractor.shared.parseBook(from: url) {
                    let book = Book()

                    book.title = metadata.title ?? "Untitled"
                    book.summary = metadata.description ?? ""
                    book.coverPath = metadata.bookCover
                    book.bookPath = metadata.bookPath

                    _ = metadata.subject?.map { item in
                        let newTag = Tag()
                        newTag.name = item
                        book.tags.append(newTag)
                    }

                    _ = metadata.author.map { author in
                        author.map { author in
                            let newAuthor = Author()
                            newAuthor.name = author.name ?? "Unknown Author"
                            book.authors.append(newAuthor)
                        }
                    }

                    book.processed = true
                    $books.append(book)

                    totalBytes -= url.size

                    if let fileIndex = fileUrls.firstIndex(of: url) {
                        fileUrls.remove(at: fileIndex)
                    }
                }
            }
            processingBook = false
            fileUrls = []
            dismiss()
        }
    }

    func removeFile(_ set: IndexSet) {
        withAnimation {
            fileUrls.remove(atOffsets: set)
        }
    }
}

#Preview {
    UploadFileView(fileUrls: [URL(fileURLWithPath: "book.epub"), URL(fileURLWithPath: "otherBOok.epub")])
        .preferredColorScheme(.dark)
}
