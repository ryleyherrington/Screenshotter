//
//  ContentView.swift
//  screenshotter
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var project = ScreenshotProject()
    @StateObject private var exportHandler = ExportHandler()
    @State private var isDraggingOnWindow = false
    @State private var showConfigExportSuccess = false
    @State private var showConfigImportSuccess = false
    @State private var showConfigImportError = false

    var body: some View {
        HStack(spacing: 0) {
            // Left: Control Panel
            ControlPanelView(project: project) {
                exportHandler.exportAll(project: project)
            }

            Divider()

            // Right: Preview Canvas
            PreviewCanvasView(project: project)
                .frame(minWidth: 500)
        }
        .frame(minWidth: 1000, minHeight: 700)
        .onDrop(of: [.fileURL, .image], isTargeted: $isDraggingOnWindow) { providers in
            handleWindowDrop(providers: providers)
        }
        .overlay(
            // Full-window drop indicator
            Group {
                if isDraggingOnWindow {
                    ZStack {
                        Rectangle()
                            .fill(Color.tealPrimary.opacity(0.1))

                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(Color.tealPrimary, style: StrokeStyle(lineWidth: 3, dash: [10, 5]))
                            .padding(20)

                        VStack(spacing: 12) {
                            Image(systemName: "photo.badge.plus")
                                .font(.system(size: 48))
                                .foregroundColor(.tealPrimary)

                            Text("Drop screenshots here")
                                .font(.title2)
                                .fontWeight(.medium)
                                .foregroundColor(.tealPrimary)
                        }
                    }
                }
            }
        )
        .alert("Export Complete", isPresented: $exportHandler.showSuccessAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            let fileCount = exportHandler.exportedCount
            let imageCount = exportHandler.exportedImageCount
            let screenshotLabel = imageCount == 1 ? "screenshot" : "screenshots"
            Text("Successfully exported \(fileCount) files from \(imageCount) \(screenshotLabel).")
        }
        .alert("Export Error", isPresented: .constant(exportHandler.exportError != nil)) {
            Button("OK", role: .cancel) {
                exportHandler.exportError = nil
            }
        } message: {
            Text(exportHandler.exportError ?? "An unknown error occurred")
        }
        .alert("Configuration Exported", isPresented: $showConfigExportSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Configuration saved successfully.")
        }
        .alert("Configuration Imported", isPresented: $showConfigImportSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Configuration loaded successfully.")
        }
        .alert("Import Error", isPresented: $showConfigImportError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Failed to import configuration. Please check the file format.")
        }
        .onReceive(NotificationCenter.default.publisher(for: .exportAllSizes)) { _ in
            exportHandler.exportAll(project: project)
        }
        .onReceive(NotificationCenter.default.publisher(for: .exportConfiguration)) { _ in
            exportConfiguration()
        }
        .onReceive(NotificationCenter.default.publisher(for: .importConfiguration)) { _ in
            importConfiguration()
        }
    }

    // MARK: - Configuration Export/Import

    private func exportConfiguration() {
        guard let json = project.exportConfigurationJSON() else { return }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "screenshotter_config.json"
        panel.message = "Save screenshot configuration"

        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            try json.write(to: url, atomically: true, encoding: .utf8)
            showConfigExportSuccess = true
        } catch {
            print("Failed to save configuration: \(error)")
        }
    }

    private func importConfiguration() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.message = "Select a screenshot configuration file"

        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            let json = try String(contentsOf: url, encoding: .utf8)
            if project.importConfigurationJSON(json) {
                showConfigImportSuccess = true
            } else {
                showConfigImportError = true
            }
        } catch {
            print("Failed to load configuration: \(error)")
            showConfigImportError = true
        }
    }

    // MARK: - Drag and Drop

    private func handleWindowDrop(providers: [NSItemProvider]) -> Bool {
        let remainingSlots = ScreenshotProject.maxImages - project.importedImages.count
        guard remainingSlots > 0 else { return false }

        var handled = false
        for provider in providers.prefix(remainingSlots) {
            handled = loadImage(from: provider) || handled
        }

        return handled
    }

    private func loadImage(from provider: NSItemProvider) -> Bool {
        // Try to load as file URL first (for files dragged from Finder)
        if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            provider.loadDataRepresentation(forTypeIdentifier: UTType.fileURL.identifier) { data, error in
                guard let data = data, error == nil,
                      let url = URL(dataRepresentation: data, relativeTo: nil),
                      let image = NSImage(contentsOf: url) else { return }

                DispatchQueue.main.async {
                    project.addImages([image])
                }
            }
            return true
        }

        // Try to load as PNG
        if provider.hasItemConformingToTypeIdentifier(UTType.png.identifier) {
            provider.loadDataRepresentation(forTypeIdentifier: UTType.png.identifier) { data, error in
                guard let data = data, error == nil,
                      let image = NSImage(data: data) else { return }

                DispatchQueue.main.async {
                    project.addImages([image])
                }
            }
            return true
        }

        // Try to load as any image
        if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
            provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, error in
                guard let data = data, error == nil,
                      let image = NSImage(data: data) else { return }

                DispatchQueue.main.async {
                    project.addImages([image])
                }
            }
            return true
        }

        return false
    }
}

#Preview {
    ContentView()
}
