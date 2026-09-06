import AppKit
import Combine
import Foundation

@MainActor
final class DownloadManager: ObservableObject {
    static let shared = DownloadManager()

    @Published var lastFileURL: URL?
    @Published var lastError: String?

    func chooseDestination(suggestedFilename: String, completion: @escaping (URL?) -> Void) {
        let panel = NSSavePanel()
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = suggestedFilename
        panel.directoryURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
        panel.begin { [weak self] response in
            Task { @MainActor in
                if response == .OK, let url = panel.url {
                    self?.lastFileURL = url
                    completion(url)
                } else {
                    completion(nil)
                }
            }
        }
    }

    func didFinish() {
        lastError = nil
        if let url = lastFileURL {
            NSWorkspace.shared.activateFileViewerSelecting([url])
        }
    }

    func didFail(_ error: Error) {
        lastError = error.localizedDescription
    }
}
