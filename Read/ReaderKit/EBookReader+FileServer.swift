//
//  EBookReader+FileServer.swift
//  Read
//
//  Created by Mirna Olvera on 3/5/24.
//

import GCDWebServers

class FileServer {
    let server: GCDWebServer

    static let FileServerSharedInstance = FileServer()

    class var sharedInstance: FileServer {
        return FileServerSharedInstance
    }

    var base: String {
        return "http://localhost:\(server.port)"
    }

    /// A random, transient token used for authenticating requests.
    /// Other apps are able to make requests to our local Web server,
    /// so this prevents them from accessing any resources.
    fileprivate let sessionToken = UUID().uuidString

    init() {
        self.server = GCDWebServer()
    }

    @discardableResult
    func start() throws -> Bool {
        GCDWebServer.setLogLevel(4)
        if !server.isRunning {
            try server.start(options: [
                GCDWebServerOption_Port: 6571,
                GCDWebServerOption_BindToLocalhost: true,
                GCDWebServerOption_AutomaticallySuspendInBackground: true,
            ])
        }
        return server.isRunning
    }

    /// Convenience method to register a resource in the main bundle. Will be mounted at $base/$module/$resource
    func registerMainBundleResource(_ resource: String, module: String) {
        if let path = Bundle.main.path(forResource: resource, ofType: nil) {
            server.addGETHandler(
                forPath: "/\(module)/\(resource)",
                filePath: path,
                isAttachment: false,
                cacheAge: UInt.max,
                allowRangeRequests: true
            )
        }
    }

    func registerGETHandlerForDirectory(
        _ basePath: String,
        directoryPath: String,
        indexFilename: String?
    ) {
        server.addGETHandler(forBasePath: basePath, directoryPath: directoryPath, indexFilename: indexFilename, cacheAge: UInt.max, allowRangeRequests: false)
    }

    /// Convenience method to register a dynamic handler. Will be mounted at $base/$module/$resource
    func registerHandlerForMethod(
        _ method: String,
        module: String,
        resource: String,
        handler: @escaping (_ request: GCDWebServerRequest?) -> GCDWebServerResponse?
    ) {
        // Prevent serving content if the requested host isn't a safelisted local host.
        let wrappedHandler = { (request: GCDWebServerRequest?) -> GCDWebServerResponse? in
            guard let request = request,
                  self.isValidURL(url: request.url)
            else { return GCDWebServerResponse(statusCode: 403) }

            return handler(request)
        }
        server.addHandler(
            forMethod: method,
            path: "/\(module)/\(resource)",
            request: GCDWebServerRequest.self,
            processBlock: wrappedHandler
        )
    }

    func isValidURL(url: URL) -> Bool {
        url.absoluteString.hasPrefix(base)
    }
}
