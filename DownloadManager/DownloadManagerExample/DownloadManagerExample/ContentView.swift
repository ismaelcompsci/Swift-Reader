//
//  ContentView.swift
//  DownloadManagerExample
//
//  Created by Mirna Olvera on 4/10/24.
//

import DownloadManager
import SwiftUI

private enum Constants {
    static let httpbin = URL(string: "https://httpbin.org")!
    static let downloadCount = 10
    /// Max httpbin file size (~100kb).
    static let maxFileSize = 102_400
}

struct ContentView: View {
    @Environment(Downloader.self) var downloader

    var body: some View {
        VStack {
            List {
                ForEach(downloader.queue) { download in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("\(download.id)")
                            Spacer()
                            Text("\(Int(download.progress.fraction * 100))%")
                        }
                        .lineLimit(1)
                        .font(.system(size: 16))

                        VStack(alignment: .leading, spacing: 8) {
                            let state = download.status

                            Group {
                                switch state {
                                case .downloading:
                                    ProgressView()
                                        .scaleEffect(0.8)
                                case .paused:
                                    Image(systemName: "pause")
                                case .failed(let err):
                                    let _ = print("ERROR: ", err.localizedDescription)
                                    Image(systemName: "x.circle")
                                case .finished:
                                    Image(systemName: "checkmark")
                                default:
                                    Spacer()
                                        .frame(width: 24, height: 24)
                                }
                            }
                            .frame(width: 24, height: 24)

                            ProgressView(value: download.progress.fraction, total: 1.0)
                        }
                    }
                    .padding(.vertical, 8)
                    .transition(.slide)
                }
            }
            .animation(.easeInOut, value: downloader.queue)
        }
        .padding()
        .onAppear {
            let urlsToDownload = (0 ..< Constants.downloadCount).map { _ in
                let size = Int.random(in: 1_000 ... Constants.maxFileSize)
                return Constants.httpbin.appendingPathComponent("/bytes/\(size)")
            }

            for url in urlsToDownload {
                downloader.download(url: url)
            }
        }
    }
}

#Preview {
    @State var d = Downloader()

    return ContentView()
        .environment(d)
        .preferredColorScheme(.dark)
}
