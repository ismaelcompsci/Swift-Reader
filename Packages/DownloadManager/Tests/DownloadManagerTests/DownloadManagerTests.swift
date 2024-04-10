@testable import DownloadManager
import XCTest

let testURL1 = URL(string: "https://w.wallhaven.cc/full/85/wallhaven-858lz1.png")!
let testURL2 = URL(string: "https://w.wallhaven.cc/full/l8/wallhaven-l8v3ey.png")!
let testURL3 = URL(string: "https://w.wallhaven.cc/full/vq/wallhaven-vqrmj8.jpg")!
let testURL4 = URL(string: "https://w.wallhaven.cc/full/o5/wallhaven-o5e3r5.jpg")!
let testURL5 = URL(string: "https://w.wallhaven.cc/full/we/wallhaven-werowr.png")!

let mb512 = URL(string: "http://ipv4.download.thinkbroadband.com/512MB.zip")!
let mb200 = URL(string: "http://ipv4.download.thinkbroadband.com/200MB.zip")!
let mb50 = URL(string: "http://ipv4.download.thinkbroadband.com/50MB.zip")!
let mb10 = URL(string: "http://ipv4.download.thinkbroadband.com/10MB.zip")!
let mb5 = URL(string: "http://ipv4.download.thinkbroadband.com/5MB.zip")!

let testURLS = [
    testURL1,
    testURL2,
    testURL3,
    testURL4,
    testURL5,
]

final class DownloadManagerTests: XCTestCase {
    private var observation: NSKeyValueObservation?
    var downloader = Downloader()

    func testFirstItemInQueueStartsDownloadingAutomatically() throws {
        let download = downloader.manager.append(mb512)

        waitForChanges(to: \.status, on: download, timeout: 1)

        XCTAssertEqual(download.status, .downloading)
    }

    func testConcurrentDownloads() throws {
        downloader.manager.maxConcurrentDownloads = 2

        let download1 = downloader.manager.append(mb512)
        let download2 = downloader.manager.append(mb512)
        let download3 = downloader.manager.append(mb512)

        downloader.manager.append(download1)
        downloader.manager.append(download2)
        downloader.manager.append(download3)

        waitForChanges(to: \.status, on: download1, timeout: 1)

        XCTAssertEqual(downloader.tasks[download1.id]?.state, .running)
        XCTAssertEqual(downloader.tasks[download2.id]?.state, .running)
        XCTAssertEqual(downloader.tasks[download3.id]?.state, .suspended)
    }

    func testDownloadDuplicateURLReplacesFinishedDownload() throws {
        let download = downloader.manager.append(testURL2)
        downloader.manager.append(download)

        let exp = expectation(description: "finished")
        withContinousObservation(of: download) { d in
            if d.status == .finished {
                exp.fulfill()
            }
        }

        waitForExpectations(timeout: 10)

        let dupe = downloader.manager.append(testURL2)
        downloader.manager.append(dupe)

        waitForChanges(to: \.status, on: dupe, timeout: 10)

        XCTAssertEqual(dupe.status, .downloading)
    }

    func testPause() throws {
        let download = downloader.manager.append(mb512)
        let task = downloader.tasks[download.id]!

        waitForChanges(to: \.status, on: download)
        downloader.manager.pause(download)

        let exp = expectation(description: "task changes to canceling")

        observation = task.observe(\.state, options: [.initial]) { task, _ in
            if task.state == .canceling || task.state == .completed {
                exp.fulfill()
            }
        }

        waitForExpectations(timeout: 1)

        XCTAssertEqual(download.status, .paused)
    }

    func testPauseFinishedDownloadHasNoEffect() throws {
        let download = downloader.manager.append(testURL1)
        download.status = .finished
        downloader.manager.pause(download)
        XCTAssertEqual(download.status, .finished)
    }

    func testResume() throws {
        let download1 = downloader.manager.append(mb512)
        let download2 = downloader.manager.append(mb200)

        // wait for status to change to download
        waitForChanges(to: \.status, on: download1)

        XCTAssertEqual(download1.status, .downloading)
        XCTAssertEqual(download2.status, .downloading)

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

        waitForChanges(to: \.status, on: download, timeout: 2)
        XCTAssertEqual(download.status, .downloading)

        downloader.manager.remove(download)

        let task = downloader.tasks[download.id]!
        let exp = expectation(description: "task changes to canceling")
        observation = task.observe(\.state, options: [.initial]) { task, _ in
            if task.state == .canceling || task.state == .completed {
                exp.fulfill()
            }
        }

        waitForExpectations(timeout: 0.5)
    }

    func testCancelRemovesDownloadFromQueue() throws {
        let download = downloader.manager.append(mb512)

        waitForChanges(to: \.status, on: download)
        XCTAssertEqual(download.status, .downloading)

        let task = downloader.tasks[download.id]!
        downloader.manager.remove(download)

        let exp = expectation(description: "task changes to canceling")
        observation = task.observe(\.state, options: [.initial]) { task, _ in
            if task.state == .canceling || task.state == .completed {
                exp.fulfill()
            }
        }

        waitForExpectations(timeout: 0.5)

        XCTAssertEqual(downloader.manager.downloadQueue.downloads, [])
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
