//
//  SourceDownloadButton.swift
//  Read
//
//  Created by Mirna Olvera on 4/3/24.
//

import DownloadManager
import SwiftUI

struct Butt: View {
    @Environment(AppTheme.self) var theme
    @Environment(BookDownloader.self) var bookDownloader
    @Environment(Toaster.self) var toaster

    var book: SourceBook

    var body: some View {
        Text("HELO")
    }
}

struct SourceDownloadButton: View {
    @Environment(AppTheme.self) var theme
    @Environment(BookDownloader.self) var bookDownloader
    @Environment(Toaster.self) var toaster

    var book: SourceBook

    @State var selected: DownloadInfo?
    @State var download: Download?

    var filename: String {
        if let selected = selected {
            return "\(book.id)\(selected.filetype)"
        }
        return "\(book.id)"
    }

    var downloadable: Bool {
        book.bookInfo.downloadLinks.isEmpty == false
    }

    init(
        book: SourceBook
    ) {
        self.book = book
        self._selected = State(initialValue: book.bookInfo.downloadLinks.first ?? nil)
    }

    var body: some View {
        HStack {
            Button {
                downloadFile()
            } label: {
                HStack(spacing: 8) {
                    if downloadable == true {
                        switch download?.status {
                        case .idle:
                            Text("Queued...")
                        case .downloading:
                            ProgressView()
                            Text("\(Int((download?.progress.fraction ?? 0) * 100))%")
                        case .paused:
                            Image(systemName: "pause.fill")
                            Text("paused")
                        case .finished:
                            Text("")
                        case .failed:
                            Text("Failed")
                        case nil:
                            Text("Download")
                        }
                    } else {
                        Text("Download unavailable")
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .frame(height: 32)
            .disabled(!downloadable || (download != nil && download?.status != .finished))
            .clipShape(.rect(cornerRadius: 10))
            .buttonStyle(.borderedProminent)
            .animation(
                .spring(dampingFraction: 0.5).speed(
                    3
                ),
                value: download?.status == .downloading
            )

            if download?.status == .downloading {
                Button {
                    if let download {
                        bookDownloader.cancel(download)
                    }
                } label: {
                    Image(systemName: "xmark")
                }
                .frame(width: 32, height: 32)
                .background(.thickMaterial)
                .clipShape(.rect(cornerRadius: 10))
                .transition(.move(edge: .trailing).combined(with: .opacity))
                .tint(.primary)
            }

            Menu {
                ForEach(book.bookInfo.downloadLinks.indices, id: \.self) { index in
                    Button {
                        selected = book.bookInfo.downloadLinks[index]
                        download = nil
                    } label: {
                        let url = URL(string: book.bookInfo.downloadLinks[index].link)
                        let host = url?.host() ?? "Server"

                        if selected?.link == book.bookInfo.downloadLinks[index].link {
                            Label {
                                Text("\(host) \(index)")
                            } icon: {
                                Image(systemName: "checkmark")
                            }

                        } else {
                            Text("\(host) \(index)")
                        }
                    }
                }
            } label: {
                Image(systemName: "arrow.down.circle")
                    .frame(width: 32, height: 32)
                    .background(.thickMaterial)
                    .clipShape(.rect(cornerRadius: 10))
            }
            .disabled(!downloadable || download?.status == .downloading)
            .tint(.primary)
        }
        .task {
            download = bookDownloader.queue.first(where: { $0.id == book.id })
        }
        .onReceive(bookDownloader.manager.onQueueDidChange) { queue in
            download = queue.first(where: { $0.id == book.id })
        }
    }

    func downloadFile() {
        if let selected, let url = URL(string: selected.link) {
            bookDownloader.bookInfo[book.id] = book.bookInfo
            bookDownloader.download(with: book.id, for: url)
        }
    }
}

#Preview {
    SourceDownloadButton(
        book: SourceBook(
            id: "",
            bookInfo: BookInfo(
                title: "tes",
                author: "e",
                desc: nil,
                image: nil,
                tags: nil,
                downloadLinks: []
            )
        )
    )
}
