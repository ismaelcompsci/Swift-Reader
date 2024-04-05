//
//  SourceDownloadButton.swift
//  Read
//
//  Created by Mirna Olvera on 4/3/24.
//

import SwiftUI

struct SourceDownloadButton: View {
    @EnvironmentObject var appColor: AppColor
    @Environment(BookDownloader.self) var bookDownloader

    var downloadUrls: [DownloadInfo]
    var downloadable: Bool
    var book: SourceBook?
    var itemId: String

    @State var selected: DownloadInfo?
    @State var download: Download?

    var filename: String {
        if let selected = selected {
            return "\(itemId)\(selected.filetype)"
        }
        return "\(itemId)"
    }

    init(
        downloadUrls: [DownloadInfo],
        downloadable: Bool,
        book: SourceBook? = nil,
        itemId: String
    ) {
        self.downloadUrls = downloadUrls
        self.downloadable = downloadable
        self.book = book
        self.itemId = itemId

        self._selected = State(initialValue: downloadUrls.first ?? nil)
    }

    var body: some View {
        HStack {
            Button {
                downloadFile()
            } label: {
                HStack(spacing: 8) {
                    if download?.status == .downloading {
                        ProgressView()

                        Text("\(Int((download?.progress.fraction ?? 0) * 100))%")

                    } else {
                        Text(self.downloadable ? "Download \(selected?.filetype ?? "")" : "Download Unavailable")
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .frame(height: 32)
            .disabled(!downloadable || download?.status == .downloading)
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
                .tint(.white)
            }

            Menu {
                ForEach(downloadUrls.indices, id: \.self) { index in
                    Button {
                        selected = downloadUrls[index]
                    } label: {
                        if selected?.link == downloadUrls[index].link {
                            Label {
                                Text("Server \(index)")
                            } icon: {
                                Image(systemName: "checkmark")
                            }

                        } else {
                            Text("Server \(index)")
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
            .tint(.white)
        }
        .task {
            download = bookDownloader.queue.first(where: { $0.id == itemId })
        }
        .onReceive(bookDownloader.manager.onQueueDidChange) { queue in
            download = queue.first(where: { $0.id == itemId })
        }
        .onReceive(bookDownloader.manager.onDownloadFinished, perform: downloadFinished)
    }

    func downloadFinished(_ finished: DownloadManager.OnDownloadFinished) {
        let (download, location) = finished
        // add to library
    }

    func downloadFile() {
        if let id = book?.id, let selected, let url = URL(string: selected.link) {
            bookDownloader.download(with: id, for: url)
        }
    }
}

#Preview {
    SourceDownloadButton(
        downloadUrls: [],
        downloadable: false,
        itemId: ""
    )
}
