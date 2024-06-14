//
//  DownloadManagerExampleApp.swift
//  DownloadManagerExample
//
//  Created by Mirna Olvera on 4/10/24.
//

import DownloadManager
import SwiftUI

@main
struct DownloadManagerExampleApp: App {
    @State var downloader = Downloader()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(downloader)
        }
    }
}
