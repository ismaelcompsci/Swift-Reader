@testable import DownloadManager
import XCTest

let testURL2 = URL(string: "https://w.wallhaven.cc/full/l8/wallhaven-l8v3ey.png")!

let mb512 = URL(string: "http://ipv4.download.thinkbroadband.com/512MB.zip")!
let mb200 = URL(string: "http://ipv4.download.thinkbroadband.com/200MB.zip")!
let mb50 = URL(string: "http://ipv4.download.thinkbroadband.com/50MB.zip")!
let mb10 = URL(string: "http://ipv4.download.thinkbroadband.com/10MB.zip")!
let mb5 = URL(string: "http://ipv4.download.thinkbroadband.com/5MB.zip")!

final class DownloadManagerTests: XCTestCase {
    private var observation: NSKeyValueObservation?
    var downloader = Downloader()

    func testFirstItemInQueueStartsDownloadingAutomatically() throws {
        let download = downloader.manager.append(mb512)

        XCTAssertEqual(download.status, .downloading)
    }

    func testConcurrentDownloads() throws {
        downloader.manager.maxConcurrentDownloads = 2

        let download1 = downloader.manager.append(mb512)
        let download2 = downloader.manager.append(mb200)
        let download3 = downloader.manager.append(mb50)

        downloader.manager.append(download1)
        downloader.manager.append(download2)
        downloader.manager.append(download3)

        let taskState1 = downloader.tasks[download1.id]!
        let taskState2 = downloader.tasks[download2.id]!
        let taskState3 = downloader.tasks[download3.id]!

        let countExp = expectation(description: "concurrency")

        // swiftformat:disable:next redundantSelf
        withContinousObservation(of: self.downloader.tasks) { _ in
            if self.downloader.tasks.count == 3 {
                countExp.fulfill()
            }
        }

        waitForExpectations(timeout: 3)

        let exp = expectation(description: "concurrency")
        exp.assertForOverFulfill = false
        exp.expectedFulfillmentCount = 3

        withContinousObservation(of: download1.status) { status in
            if status == .downloading {
                exp.fulfill()
            }
        }

        withContinousObservation(of: download2.status) { status in
            if status == .downloading {
                exp.fulfill()
            }
        }

        withContinousObservation(of: download3.status) { status in
            if status == .idle {
                exp.fulfill()
            }
        }

        waitForExpectations(timeout: 6)

        let taskExp = expectation(description: "running")
        taskExp.assertForOverFulfill = false

        observation = taskState1.observe(\.state, options: [.initial]) { task, _ in
            if task.state == .running {
                taskExp.fulfill()
            }
        }

        waitForExpectations(timeout: 1)

        XCTAssertEqual(downloader.requestedURLs, [mb512, mb200, mb50])

        XCTAssertEqual(taskState1.state, .running)
        XCTAssertEqual(taskState2.state, .running)
        XCTAssertEqual(taskState3.state, .suspended)
    }

    func testDownloadDuplicateURLReplacesFinishedDownload() throws {
        let download = downloader.manager.append(testURL2)
        downloader.manager.append(download)

        let exp = expectation(description: "finished")
        exp.assertForOverFulfill = false

        withContinousObservation(of: download.status) { status in
            if status == .finished {
                exp.fulfill()
            }
        }

        // how long the download takes
        // depends on internet speed
        waitForExpectations(timeout: 10)

        let dupe = downloader.manager.append(mb512)
        downloader.manager.append(dupe)

        XCTAssertEqual(dupe.status, .downloading)
    }

    func testPause() throws {
        let download = downloader.manager.append(mb512)
        let task = downloader.tasks[download.id]!

        downloader.manager.pause(download)

        let exp = expectation(description: "task changes to canceling")
        exp.assertForOverFulfill = false

        observation = task.observe(\.state, options: [.initial]) { task, _ in
            if task.state == .canceling || task.state == .completed {
                exp.fulfill()
            }
        }

        waitForExpectations(timeout: 1)

        XCTAssertEqual(download.status, .paused)
    }

    func testPauseFinishedDownloadHasNoEffect() throws {
        let download = downloader.manager.append(mb512)
        download.status = .finished
        downloader.manager.pause(download)
        XCTAssertEqual(download.status, .finished)
    }

    func testResume() throws {
        let download1 = downloader.manager.append(mb512)
        let download2 = downloader.manager.append(mb200)

        XCTAssertEqual(download1.status, .downloading)
        XCTAssertEqual(download2.status, .idle)

        // pause downloads
        downloader.manager.pause(download1)
        downloader.manager.pause(download2)

        XCTAssertEqual(download1.status, .paused)
        XCTAssertEqual(download2.status, .paused)

        downloader.manager.resume(download1)

        let task = downloader.tasks[download1.id]!

        XCTAssertEqual(task.state, .running)
        XCTAssertEqual(download1.status, .downloading)
        XCTAssertEqual(download2.status, .paused)
    }

    func testCancel() throws {
        let download = downloader.manager.append(mb512)

        downloader.manager.remove(download)

        let task = downloader.tasks[download.id]!
        let exp = expectation(description: "task changes to canceling")
        exp.assertForOverFulfill = false

        observation = task.observe(\.state, options: [.initial]) { task, _ in

            if task.state == .canceling || task.state == .completed {
                exp.fulfill()
            }
        }

        waitForExpectations(timeout: 0.5)

        XCTAssertEqual(downloader.manager.downloadQueue.downloads, [])
    }

    func testCancelRemovesDownloadFromQueue() throws {
        let download = downloader.manager.append(mb512)

        let task = downloader.tasks[download.id]!
        downloader.manager.remove(download)

        let exp = expectation(description: "task changes to canceling")
        exp.assertForOverFulfill = false

        observation = task.observe(\.state, options: [.initial]) { task, _ in
            if task.state == .canceling || task.state == .completed {
                exp.fulfill()
            }
        }

        waitForExpectations(timeout: 0.5)

        XCTAssertEqual(downloader.manager.downloadQueue.downloads, [])
    }

    func testCancelStartsDownloadingNextItemInQueue() throws {
        let download = downloader.manager.append(mb512)
        let download2 = downloader.manager.append(mb200)

        downloader.manager.remove(download)

        XCTAssertEqual(downloader.manager.downloadQueue.downloads, [download2])
        XCTAssertEqual(download2.status, .downloading)
    }

    func testPauseStartsDownloadingNextItemInQueue() throws {
        let download = downloader.manager.append(mb512)
        _ = downloader.manager.append(mb200)

        downloader.manager.pause(download)

        XCTAssertEqual(downloader.manager.downloadQueue.downloads.map { $0.status }, [.paused, .downloading])
    }
}

func withContinousObservation<T>(of value: @escaping @autoclosure () -> T, execute: @escaping (T) -> Void) {
    withObservationTracking {
        execute(value())
    } onChange: {
        Task { @MainActor in
            withContinousObservation(of: value(), execute: execute)
        }
    }
}
