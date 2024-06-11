//
//  File.swift
//
//
//  Created by Mirna Olvera on 5/19/24.
//

import Foundation
import GCDWebServers

class WebServer {
    static var shared = WebServer()
    var fileServer: FileServer
    var file: URL?

    init(fileServer: FileServer = FileServer.sharedInstance) {
        self.fileServer = fileServer
    }

    func setUpWebServer() {
        guard !fileServer.server.isRunning else {
            return
        }

        let scriptDir = Bundle.module.path(forResource: "scripts", ofType: nil)

        guard let scriptDir = scriptDir else {
            return
        }

        fileServer.registerGETHandlerForDirectory("/", directoryPath: scriptDir, indexFilename: "reader.html")

        fileServer.registerHandlerForMethod("GET",
                                            module: "api",
                                            resource: "book",
                                            handler: getBookHandler)
        do {
            try fileServer.start()
        } catch {}
    }

    private func getBookHandler(_ req: GCDWebServerRequest?) -> GCDWebServerDataResponse? {
        guard let file else {
            return nil
        }

        let data = try? Data(contentsOf: file)

        guard let data else {
            print("Failed to read data from book url")
            return nil
        }

        return GCDWebServerDataResponse(data: data, contentType: "application/octet-stream")
    }
}
