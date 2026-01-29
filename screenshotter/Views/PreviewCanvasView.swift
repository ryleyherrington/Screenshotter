//
//  PreviewCanvasView.swift
//  screenshotter
//

import SwiftUI

struct PreviewCanvasView: View {
    @ObservedObject var project: ScreenshotProject
    private let compositor = ImageCompositor()

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background pattern (checkerboard for transparency)
                CheckerboardBackground()

                // Canvas background
                backgroundFill

                if project.hasImage {
                    // Live preview
                    previewContent(in: geometry.size)
                } else {
                    // Empty state
                    emptyStateView
                }
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
    }

    @ViewBuilder
    private func previewContent(in containerSize: CGSize) -> some View {
        let previewSize = calculatePreviewSize(containerSize: containerSize)

        ZStack {
            backgroundFill
                .frame(width: previewSize.width, height: previewSize.height)
                .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)

            // Composite preview
            if let previewImage = generatePreview(size: previewSize) {
                Image(nsImage: previewImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: previewSize.width, height: previewSize.height)
            }
        }
    }

    @ViewBuilder
    private var backgroundFill: some View {
        if project.backgroundStyle == .gradient {
            let points = GradientHelpers.unitPoints(for: project.backgroundGradientAngle)
            LinearGradient(
                colors: [project.backgroundGradientStart, project.backgroundGradientEnd],
                startPoint: points.start,
                endPoint: points.end
            )
        } else {
            project.backgroundColor
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 64))
                .foregroundColor(.secondary.opacity(0.5))

            Text("Drop a screenshot to preview")
                .font(.title2)
                .foregroundColor(.secondary)

            Text("Drag an image from Finder or the iOS Simulator")
                .font(.caption)
                .foregroundColor(.secondary.opacity(0.7))
        }
    }

    private func calculatePreviewSize(containerSize: CGSize) -> CGSize {
        // Get target aspect ratio based on device type (use portrait as reference)
        let targetAspectRatio: CGFloat
        switch project.deviceType {
        case .iPhone:
            targetAspectRatio = 1284.0 / 2778.0  // Portrait iPhone aspect ratio
        case .iPad:
            targetAspectRatio = 2048.0 / 2732.0  // Portrait iPad aspect ratio
        }

        let padding: CGFloat = 60
        let availableWidth = containerSize.width - padding * 2
        let availableHeight = containerSize.height - padding * 2

        let widthBasedHeight = availableWidth / targetAspectRatio
        let heightBasedWidth = availableHeight * targetAspectRatio

        if widthBasedHeight <= availableHeight {
            return CGSize(width: availableWidth, height: widthBasedHeight)
        } else {
            return CGSize(width: heightBasedWidth, height: availableHeight)
        }
    }

    private func generatePreview(size: CGSize) -> NSImage? {
        // Use a standard export size for preview generation to get proper scaling
        let referenceSize: CGSize
        switch project.deviceType {
        case .iPhone:
            referenceSize = CGSize(width: 1284, height: 2778)
        case .iPad:
            referenceSize = CGSize(width: 2048, height: 2732)
        }

        // Generate at reference size then scale for display
        let exportSize = ExportSize(
            width: Int(referenceSize.width),
            height: Int(referenceSize.height),
            deviceType: project.deviceType,
            displayName: "Preview"
        )

        return compositor.generateComposite(project: project, exportSize: exportSize)
    }
}

// MARK: - Checkerboard Background

struct CheckerboardBackground: View {
    let squareSize: CGFloat = 10

    var body: some View {
        Canvas { context, size in
            let rows = Int(ceil(size.height / squareSize))
            let cols = Int(ceil(size.width / squareSize))

            for row in 0..<rows {
                for col in 0..<cols {
                    let isLight = (row + col) % 2 == 0
                    let rect = CGRect(
                        x: CGFloat(col) * squareSize,
                        y: CGFloat(row) * squareSize,
                        width: squareSize,
                        height: squareSize
                    )
                    context.fill(
                        Path(rect),
                        with: .color(isLight ? Color.gray.opacity(0.1) : Color.gray.opacity(0.15))
                    )
                }
            }
        }
    }
}
