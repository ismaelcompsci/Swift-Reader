//
//  DownloadManagerView.swift
//  Read
//
//  Created by Mirna Olvera on 4/15/24.
//

import DownloadManager
import SwiftUI

struct DownloadManagerView: View {
    @Environment(BookDownloader.self) var downloader

    func downloadItemState(_ download: Download) -> some View {
        HStack {
            switch download.status {
            case .idle:
                Image(systemName: "stopwatch")
            case .downloading:
                Text("\(Int(download.progress.fraction * 100))%")
            case .paused:
                Image(systemName: "pause.fill")
                Text("paused")
            case .finished:
                Image(systemName: "checkmark.cirlce")
            case .failed(let error):
                Image(systemName: "x.circle")
            }
        }
        .font(.footnote)
    }

    func getDownloadColor(_ download: Download) -> Color {
        switch download.status {
        case .idle:
            return .secondary
        case .downloading:
            return .primary
        case .paused:
            return .secondary
        case .finished:
            return .green
        case .failed(let error):
            Log("download error: \(error.localizedDescription)")
            return .red
        }
    }

    func downloadItem(_ download: Download) -> some View {
        let downloadInfo = downloader.bookInfo[download.id]
        let color = getDownloadColor(download)

        return Group {
            if let downloadInfo = downloadInfo {
                VStack(alignment: .leading) {
                    Text("\(downloadInfo.title)")
                        .lineLimit(1)

                    HStack(alignment: .center) {
                        downloadItemState(download)

                        Spacer()

                        Button {
                            if download.status == .paused {
                                downloader.resume(download)
                            } else {
                                downloader.pause(download)
                            }
                        } label: {
                            Image(
                                systemName: download.status == .paused ? "play.fill" : "pause.fill"
                            )
                            .frame(width: 22, height: 22)
                            .foregroundStyle(.primary)
                        }
                    }
                    .animation(.easeInOut, value: download.status)
                }
                .foregroundStyle(color)
            } else {
                EmptyView()
            }
        }
    }

    var body: some View {
        VStack {
            List {
                ForEach(downloader.queue) { download in
                    downloadItem(download)
                }
                .onDelete(perform: onDelete)
            }
        }
        .navigationTitle("Download Queue \(downloader.queue.count)")
        .navigationBarTitleDisplayMode(.large)
    }

    func onDelete(_ indexSet: IndexSet) {
        for index in indexSet {
            let download = downloader.queue[index]

            downloader.cancel(download)
        }
    }
}

#Preview {
    @State var downloader = BookDownloader()

    return NavigationView {
        DownloadManagerView()
            .task {
                downloader.bookInfo["d1"] = BookInfo(title: "Download 1", downloadLinks: [])

                downloader.download(
                    with: "d1",
                    for: URL(string: "https://bit.ly/1GB-testfile")!
                )

                downloader.bookInfo["d2"] = BookInfo(title: "Download 2", downloadLinks: [])
                downloader.download(
                    with: "d2",
                    for: URL(string: "https://bit.ly/1GB-testfile")!
                )

                downloader.bookInfo["d3"] = BookInfo(title: "Download 3", downloadLinks: [])
                downloader.download(
                    with: "d3",
                    for: URL(string: "https://bit.ly/1GB-testfile")!
                )
            }
    }
    .preferredColorScheme(.dark)
    .environment(downloader)
}
