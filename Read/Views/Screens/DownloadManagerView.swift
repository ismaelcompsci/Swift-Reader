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
            case .finished:
                Image(systemName: "checkmark.cirlce")
            case .failed(let error):
                Image(systemName: "x.circle")
            }
        }
        .font(.footnote)
        .transition(.opacity.combined(with: .blurReplace))
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
            return .red
        }
    }

    func downloadItem(_ download: Download) -> some View {
        let downloadInfo = downloader.bookInfo[download.id]!
        let color = getDownloadColor(download)

        return VStack(alignment: .leading) {
            Text("\(downloadInfo.title)")
                .lineLimit(1)

            downloadItemState(download)
        }
        .foregroundStyle(color)
    }

    var body: some View {
        VStack {
            List {
                ForEach(downloader.queue) { download in
                    let downloadInfo = downloader.bookInfo[download.id]
                    if let downloadInfo = downloadInfo {
                        downloadItem(download)

                    } else {
                        EmptyView()
                    }
                }
                .onDelete(perform: onDelete)
            }
        }
        .navigationTitle("Download Queue")
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
    VStack {
        DownloadManagerView()
    }
    .preferredColorScheme(.dark)
}
