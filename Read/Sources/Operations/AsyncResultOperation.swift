//
//  AsyncResultOperation.swift
//  Read
//
//  Created by Mirna Olvera on 4/30/24.
//

import Foundation

class AsyncResultOperation<Success, Failure>: AsyncOperation where Failure: Error {
    private(set) var result: Result<Success, Failure>? {
        didSet {
            guard let result = result else { return }
            onResult?(result)
        }
    }

    var onResult: ((_ result: Result<Success, Failure>) -> Void)?

    override final func finish() {
        guard !isCancelled else { return super.finish() }
        fatalError("Make use of finish(with:) instead to ensure a result")
    }

    func finish(with result: Result<Success, Failure>) {
        self.result = result
        super.finish()
    }

    override func cancel() {
        fatalError("Make use of cancel(with:) instead to ensure a result")
    }

    func cancel(with error: Failure) {
        result = .failure(error)
        super.cancel()
    }
}
