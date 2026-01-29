//
//  DropZoneView.swift
//  screenshotter
//

import SwiftUI
import UniformTypeIdentifiers

struct DropZoneView: View {
    @ObservedObject var project: ScreenshotProject
    @State private var isDragging = false

    var body: some View {
        VStack(spacing: 16) {
            if project.hasImage {
                thumbnailStrip

                HStack {
                    Text("\(project.importedImages.count)/\(ScreenshotProject.maxImages) images loaded")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Button("Clear All") {
                        withAnimation {
                            project.clearImages()
                        }
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.red)
                    .font(.caption)
                }
            }

            dropZone
        }
        .onDrop(of: [.fileURL, .image], isTargeted: $isDragging) { providers in
            handleDrop(providers: providers)
        }
        .animation(.easeInOut(duration: 0.2), value: isDragging)
    }

    private var dropZone: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    isDragging ? Color.tealPrimary : Color.gray.opacity(0.4),
                    style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                )
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isDragging ? Color.tealPrimary.opacity(0.1) : Color.clear)
                )

            VStack(spacing: 12) {
                Image(systemName: "photo.badge.plus")
                    .font(.system(size: 36))
                    .foregroundColor(isDragging ? .tealPrimary : .secondary)

                Text(project.hasImage ? "Drop more screenshots here" : "Drop screenshot here")
                    .font(.headline)
                    .foregroundColor(isDragging ? .tealPrimary : .primary)

                Text(project.importedImages.count >= ScreenshotProject.maxImages
                     ? "Maximum of \(ScreenshotProject.maxImages) images"
                     : "or click to browse")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(height: 150)
        .onTapGesture {
            openFilePicker()
        }
        .opacity(project.importedImages.count >= ScreenshotProject.maxImages ? 0.6 : 1.0)
    }

    private var thumbnailStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(Array(project.importedImages.enumerated()), id: \.offset) { index, image in
                    ZStack(alignment: .topTrailing) {
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 80)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(index == project.selectedImageIndex ? Color.tealPrimary : Color.clear, lineWidth: 2)
                            )
                            .shadow(radius: 2)
                            .onTapGesture {
                                project.selectedImageIndex = index
                            }

                        Button {
                            withAnimation {
                                project.removeImage(at: index)
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                                .padding(4)
                                .background(Circle().fill(Color.black.opacity(0.6)))
                        }
                        .buttonStyle(.plain)
                        .padding(4)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        let remainingSlots = ScreenshotProject.maxImages - project.importedImages.count
        guard remainingSlots > 0 else { return false }

        var handled = false
        for provider in providers.prefix(remainingSlots) {
            handled = loadImage(from: provider) || handled
        }

        return handled
    }

    private func loadImage(from provider: NSItemProvider) -> Bool {
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

    private func openFilePicker() {
        let remainingSlots = ScreenshotProject.maxImages - project.importedImages.count
        guard remainingSlots > 0 else { return }

        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg, .heic, .tiff]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.message = "Select up to \(remainingSlots) screenshot(s)"

        if panel.runModal() == .OK {
            let images = panel.urls.compactMap { NSImage(contentsOf: $0) }
            if !images.isEmpty {
                project.addImages(images)
            }
        }
    }
}
