//
//  ExportButton.swift
//  screenshotter
//

import SwiftUI
import AppKit
import Combine

struct ExportButton: View {
    let action: () -> Void
    let isEnabled: Bool

    @State private var isExporting = false

    var body: some View {
        Button(action: {
            if isEnabled {
                action()
            }
        }) {
            HStack(spacing: 10) {
                if isExporting {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .semibold))
                }

                Text(isExporting ? "Exporting..." : "Export All Screenshots")
            }
        }
        .buttonStyle(LargeTealButtonStyle())
        .disabled(!isEnabled || isExporting)
        .opacity(isEnabled ? 1.0 : 0.5)
        .help(isEnabled ? "Export screenshots for all App Store sizes" : "Add a screenshot first")
    }

    func setExporting(_ exporting: Bool) {
        isExporting = exporting
    }
}

// MARK: - Export Handler

class ExportHandler: ObservableObject {
    @Published var isExporting = false
    @Published var showSuccessAlert = false
    @Published var exportedCount = 0
    @Published var exportedImageCount = 0
    @Published var exportError: String?

    private let compositor = ImageCompositor()

    func exportAll(project: ScreenshotProject) {
        guard project.hasImage else { return }

        // Save current settings to the current screenshot before exporting
        project.saveCurrentSettingsToScreenshot()

        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.message = "Choose a folder to save App Store screenshots"
        panel.prompt = "Export Here"

        guard panel.runModal() == .OK, let folderURL = panel.url else {
            return
        }

        let screenshotItems = project.screenshots
        exportError = nil
        isExporting = true

        // Start accessing security-scoped resource for sandboxed app
        let didStartAccessing = folderURL.startAccessingSecurityScopedResource()

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else {
                if didStartAccessing {
                    folderURL.stopAccessingSecurityScopedResource()
                }
                return
            }

            var exportedURLs: [URL] = []
            let useSubfolders = screenshotItems.count > 1

            for (index, screenshotItem) in screenshotItems.enumerated() {
                let targetFolder = useSubfolders
                    ? folderURL.appendingPathComponent("Screenshot \(index + 1)")
                    : folderURL

                if useSubfolders {
                    do {
                        try FileManager.default.createDirectory(at: targetFolder, withIntermediateDirectories: true, attributes: nil)
                    } catch {
                        continue
                    }
                }

                exportedURLs.append(contentsOf: self.compositor.exportAllSizes(screenshotItem: screenshotItem, to: targetFolder))
            }

            // Stop accessing security-scoped resource
            if didStartAccessing {
                folderURL.stopAccessingSecurityScopedResource()
            }

            DispatchQueue.main.async {
                self.isExporting = false
                self.exportedCount = exportedURLs.count
                self.exportedImageCount = screenshotItems.count

                if exportedURLs.isEmpty {
                    self.exportError = "Failed to export images"
                } else {
                    self.showSuccessAlert = true
                    // Open folder in Finder
                    NSWorkspace.shared.selectFile(exportedURLs.first?.path, inFileViewerRootedAtPath: folderURL.path)
                }
            }
        }
    }
}
