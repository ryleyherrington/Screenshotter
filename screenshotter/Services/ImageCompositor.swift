//
//  ImageCompositor.swift
//  screenshotter

import AppKit
import SwiftUI

class ImageCompositor {
    struct CompositeConfig {
        let screenshot: NSImage
        let deviceFrameName: String
        let titleText: String
        let subtitleText: String
        let titleFontSize: CGFloat
        let subtitleFontSize: CGFloat
        let textPosition: TextPosition
        let screenshotYOffset: CGFloat
        let backgroundColor: NSColor
        let backgroundStyle: BackgroundStyle
        let backgroundGradientStart: NSColor
        let backgroundGradientEnd: NSColor
        let backgroundGradientAngle: CGFloat
        let textColor: NSColor
        let targetSize: CGSize
    }

    // MARK: - Main Composite Function

    /// Generate composite using project's current UI values (for live preview)
    func generateComposite(project: ScreenshotProject, exportSize: ExportSize) -> NSImage? {
        guard let screenshot = project.selectedImage else { return nil }

        let deviceFrameName = exportSize.isPortrait
            ? project.deviceType.frameImageNamePortrait
            : project.deviceType.frameImageNameLandscape

        let config = CompositeConfig(
            screenshot: screenshot,
            deviceFrameName: deviceFrameName,
            titleText: project.titleText,
            subtitleText: project.subtitleText,
            titleFontSize: project.titleFontSize,
            subtitleFontSize: project.subtitleFontSize,
            textPosition: project.textPosition,
            screenshotYOffset: project.screenshotYOffset,
            backgroundColor: NSColor(project.backgroundColor),
            backgroundStyle: project.backgroundStyle,
            backgroundGradientStart: NSColor(project.backgroundGradientStart),
            backgroundGradientEnd: NSColor(project.backgroundGradientEnd),
            backgroundGradientAngle: project.backgroundGradientAngle,
            textColor: NSColor(project.textColor),
            targetSize: exportSize.size
        )

        return renderComposite(config: config)
    }

    /// Generate composite for a specific screenshot item with its own settings (for export)
    func generateComposite(screenshotItem: ScreenshotItem, exportSize: ExportSize) -> NSImage? {
        let settings = screenshotItem.settings

        let deviceFrameName = exportSize.isPortrait
            ? settings.deviceType.frameImageNamePortrait
            : settings.deviceType.frameImageNameLandscape

        let config = CompositeConfig(
            screenshot: screenshotItem.image,
            deviceFrameName: deviceFrameName,
            titleText: settings.titleText,
            subtitleText: settings.subtitleText,
            titleFontSize: settings.titleFontSize,
            subtitleFontSize: settings.subtitleFontSize,
            textPosition: settings.textPosition,
            screenshotYOffset: settings.screenshotYOffset,
            backgroundColor: NSColor(settings.backgroundColor.color),
            backgroundStyle: settings.backgroundStyle,
            backgroundGradientStart: NSColor(settings.backgroundGradientStart.color),
            backgroundGradientEnd: NSColor(settings.backgroundGradientEnd.color),
            backgroundGradientAngle: settings.backgroundGradientAngle,
            textColor: NSColor(settings.textColor.color),
            targetSize: exportSize.size
        )

        return renderComposite(config: config)
    }

    func generatePreview(project: ScreenshotProject, previewSize: CGSize) -> NSImage? {
        guard let screenshot = project.selectedImage else { return nil }

        let deviceFrameName = project.deviceType.frameImageNamePortrait

        // Use the @Published titleText/subtitleText for live preview
        let config = CompositeConfig(
            screenshot: screenshot,
            deviceFrameName: deviceFrameName,
            titleText: project.titleText,
            subtitleText: project.subtitleText,
            titleFontSize: project.titleFontSize,
            subtitleFontSize: project.subtitleFontSize,
            textPosition: project.textPosition,
            screenshotYOffset: project.screenshotYOffset,
            backgroundColor: NSColor(project.backgroundColor),
            backgroundStyle: project.backgroundStyle,
            backgroundGradientStart: NSColor(project.backgroundGradientStart),
            backgroundGradientEnd: NSColor(project.backgroundGradientEnd),
            backgroundGradientAngle: project.backgroundGradientAngle,
            textColor: NSColor(project.textColor),
            targetSize: previewSize
        )

        return renderComposite(config: config)
    }

    // MARK: - Core Rendering

    private func renderComposite(config: CompositeConfig) -> NSImage? {
        let size = config.targetSize
        let isPortrait = size.height > size.width

        // Create the output image at exact pixel dimensions (1x scale, not Retina 2x)
        let outputImage = NSImage(size: size)

        let bitmapRep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(size.width),
            pixelsHigh: Int(size.height),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        )!
        bitmapRep.size = size

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmapRep)

        guard let context = NSGraphicsContext.current?.cgContext else {
            NSGraphicsContext.restoreGraphicsState()
            return nil
        }

        // 1. Fill background
        let backgroundRect = CGRect(origin: .zero, size: size)
        if config.backgroundStyle == .gradient,
           let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: [config.backgroundGradientStart.cgColor, config.backgroundGradientEnd.cgColor] as CFArray,
            locations: [0, 1]
           ) {
            let points = GradientHelpers.cgPoints(for: config.backgroundGradientAngle, in: backgroundRect)
            context.saveGState()
            context.addRect(backgroundRect)
            context.clip()
            context.drawLinearGradient(gradient, start: points.start, end: points.end, options: [])
            context.restoreGState()
        } else {
            context.setFillColor(config.backgroundColor.cgColor)
            context.fill(backgroundRect)
        }

        // 2. Calculate layout
        let layout = calculateLayout(config: config, canvasSize: size, isPortrait: isPortrait)

        // 3. Draw device frame with screenshot inside
        drawDeviceWithScreenshot(context: context, config: config, layout: layout)

        // 4. Draw text
        drawText(config: config, layout: layout)

        NSGraphicsContext.restoreGraphicsState()
        outputImage.addRepresentation(bitmapRep)
        return outputImage
    }

    // MARK: - Layout Calculation

    private struct Layout {
        var deviceFrameRect: CGRect
        var screenshotRect: CGRect
        var titleRect: CGRect
        var subtitleRect: CGRect
        var textAreaHeight: CGFloat
        var scaleFactor: CGFloat
    }

    private func calculateLayout(config: CompositeConfig, canvasSize: CGSize, isPortrait: Bool) -> Layout {
        // Get device frame image to determine aspect ratio
        guard let deviceFrame = NSImage(named: config.deviceFrameName) else {
            // Fallback layout without device frame
            return Layout(
                deviceFrameRect: CGRect(x: canvasSize.width * 0.1, y: canvasSize.height * 0.2,
                                       width: canvasSize.width * 0.8, height: canvasSize.height * 0.6),
                screenshotRect: CGRect(x: canvasSize.width * 0.15, y: canvasSize.height * 0.25,
                                      width: canvasSize.width * 0.7, height: canvasSize.height * 0.5),
                titleRect: .zero,
                subtitleRect: .zero,
                textAreaHeight: canvasSize.height * 0.15,
                scaleFactor: 1.0
            )
        }

        let frameSize = deviceFrame.size

        // Calculate how much space to reserve for text
        let textAreaRatio: CGFloat = 0.18
        let textAreaHeight = canvasSize.height * textAreaRatio
        let deviceAreaHeight = canvasSize.height - textAreaHeight

        // Scale device frame to fit in device area
        let maxDeviceWidth = canvasSize.width * 0.85
        let maxDeviceHeight = deviceAreaHeight * 0.95

        let widthScale = maxDeviceWidth / frameSize.width
        let heightScale = maxDeviceHeight / frameSize.height
        let scaleFactor = min(widthScale, heightScale)

        let scaledFrameWidth = frameSize.width * scaleFactor
        let scaledFrameHeight = frameSize.height * scaleFactor

        // Position device frame
        let deviceX = (canvasSize.width - scaledFrameWidth) / 2
        var deviceY: CGFloat

        if config.textPosition == .above {
            // Text above: device at bottom
            deviceY = (deviceAreaHeight - scaledFrameHeight) / 2
        } else {
            // Text below: device at top
            deviceY = textAreaHeight + (deviceAreaHeight - scaledFrameHeight) / 2
        }

        // Apply Y offset to move entire device up/down
        deviceY += config.screenshotYOffset * scaleFactor

        let deviceFrameRect = CGRect(x: deviceX, y: deviceY, width: scaledFrameWidth, height: scaledFrameHeight)

        // Calculate screenshot rect inside device frame
        // These values position the screenshot within the device frame's screen area
        let insetRatioX: CGFloat = 0.048
        let insetRatioTop: CGFloat = 0.022
        let insetRatioBottom: CGFloat = 0.022

        let screenshotRect = CGRect(
            x: deviceFrameRect.minX + scaledFrameWidth * insetRatioX,
            y: deviceFrameRect.minY + scaledFrameHeight * insetRatioBottom,
            width: scaledFrameWidth * (1 - 2 * insetRatioX),
            height: scaledFrameHeight * (1 - insetRatioTop - insetRatioBottom)
        )

        // Calculate text positions
        let textY: CGFloat
        if config.textPosition == .above {
            textY = deviceAreaHeight + textAreaHeight * 0.3
        } else {
            textY = textAreaHeight * 0.3
        }

        let titleRect = CGRect(x: 0, y: textY + config.subtitleFontSize * scaleFactor + 10,
                               width: canvasSize.width, height: config.titleFontSize * scaleFactor * 1.5)
        let subtitleRect = CGRect(x: 0, y: textY,
                                  width: canvasSize.width, height: config.subtitleFontSize * scaleFactor * 1.5)

        return Layout(
            deviceFrameRect: deviceFrameRect,
            screenshotRect: screenshotRect,
            titleRect: titleRect,
            subtitleRect: subtitleRect,
            textAreaHeight: textAreaHeight,
            scaleFactor: scaleFactor
        )
    }

    // MARK: - Drawing

    private func drawDeviceWithScreenshot(context: CGContext, config: CompositeConfig, layout: Layout) {
        // Draw screenshot first (it goes behind the frame)
        // Y offset is already applied to device frame position in calculateLayout

        // Calculate corner radii
        // Outer radius matches device frame's outer corners
        let outerCornerRadius: CGFloat = config.deviceFrameName.contains("iPhone") ? 68 : 25
        let scaledOuterRadius = outerCornerRadius * layout.scaleFactor
        let outerRadiusAdjust: CGFloat = (config.deviceFrameName.contains("iPhone") ? 8 : 4) * layout.scaleFactor
        let adjustedOuterRadius = scaledOuterRadius + outerRadiusAdjust

        // Inner radius for the screen area (slightly smaller)
        let innerCornerRadius: CGFloat = config.deviceFrameName.contains("iPhone") ? 55 : 18
        let scaledInnerRadius = innerCornerRadius * layout.scaleFactor
        let insetAdjust: CGFloat = (config.deviceFrameName.contains("iPhone") ? 8 : 5) * layout.scaleFactor
        let adjustedScreenshotRect = layout.screenshotRect.insetBy(dx: insetAdjust, dy: insetAdjust)
        let adjustedInnerRadius = scaledInnerRadius + insetAdjust * 0.5

        // First, clip to the device frame's outer bounds to catch any overflow
        context.saveGState()
        let outerClipPath = CGPath(roundedRect: layout.deviceFrameRect, cornerWidth: adjustedOuterRadius, cornerHeight: adjustedOuterRadius, transform: nil)
        context.addPath(outerClipPath)
        context.clip()

        // Then clip to the inner screenshot area
        let innerClipPath = CGPath(roundedRect: adjustedScreenshotRect, cornerWidth: adjustedInnerRadius, cornerHeight: adjustedInnerRadius, transform: nil)
        context.addPath(innerClipPath)
        context.clip()

        // Draw screenshot maintaining aspect ratio
        let screenshot = config.screenshot
        let screenshotAspect = screenshot.size.width / screenshot.size.height
        let rectAspect = adjustedScreenshotRect.width / adjustedScreenshotRect.height

        var drawRect: CGRect
        if screenshotAspect > rectAspect {
            // Screenshot is wider - fit to height
            let height = adjustedScreenshotRect.height
            let width = height * screenshotAspect
            let x = adjustedScreenshotRect.midX - width / 2
            drawRect = CGRect(x: x, y: adjustedScreenshotRect.minY, width: width, height: height)
        } else {
            // Screenshot is taller - fit to width
            let width = adjustedScreenshotRect.width
            let height = width / screenshotAspect
            let y = adjustedScreenshotRect.midY - height / 2
            drawRect = CGRect(x: adjustedScreenshotRect.minX, y: y, width: width, height: height)
        }

        screenshot.draw(in: drawRect)
        context.restoreGState()

        // Draw device frame on top (this covers any remaining edge artifacts)
        if let deviceFrame = NSImage(named: config.deviceFrameName) {
            deviceFrame.draw(in: layout.deviceFrameRect)
        }
    }

    private func drawText(config: CompositeConfig, layout: Layout) {
        let scaledTitleSize = config.titleFontSize * layout.scaleFactor
        let scaledSubtitleSize = config.subtitleFontSize * layout.scaleFactor

        // Title
        if !config.titleText.isEmpty {
            let titleFont = NSFont.systemFont(ofSize: scaledTitleSize, weight: .bold)
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: titleFont,
                .foregroundColor: config.textColor
            ]

            let titleString = NSAttributedString(string: config.titleText, attributes: titleAttributes)
            let titleSize = titleString.size()
            let titleX = (layout.titleRect.width - titleSize.width) / 2
            let titlePoint = CGPoint(x: titleX, y: layout.titleRect.minY)
            titleString.draw(at: titlePoint)
        }

        // Subtitle
        if !config.subtitleText.isEmpty {
            let subtitleFont = NSFont.systemFont(ofSize: scaledSubtitleSize, weight: .medium)
            let subtitleAttributes: [NSAttributedString.Key: Any] = [
                .font: subtitleFont,
                .foregroundColor: config.textColor.withAlphaComponent(0.8)
            ]

            let subtitleString = NSAttributedString(string: config.subtitleText, attributes: subtitleAttributes)
            let subtitleSize = subtitleString.size()
            let subtitleX = (layout.subtitleRect.width - subtitleSize.width) / 2
            let subtitlePoint = CGPoint(x: subtitleX, y: layout.subtitleRect.minY)
            subtitleString.draw(at: subtitlePoint)
        }
    }

    // MARK: - Export

    /// Export all sizes for a screenshot item using its own settings (including device type)
    func exportAllSizes(screenshotItem: ScreenshotItem, to folderURL: URL) -> [URL] {
        var exportedURLs: [URL] = []

        // Only export sizes for the screenshot's device type
        let sizes = ExportSizes.sizes(for: screenshotItem.settings.deviceType)

        for size in sizes {
            if let image = generateComposite(screenshotItem: screenshotItem, exportSize: size) {
                let fileURL = folderURL.appendingPathComponent(size.fileName)
                if saveImage(image, to: fileURL) {
                    exportedURLs.append(fileURL)
                }
            }
        }

        return exportedURLs
    }

    private func saveImage(_ image: NSImage, to url: URL) -> Bool {
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            return false
        }

        do {
            try pngData.write(to: url)
            return true
        } catch {
            print("Failed to save image: \(error)")
            return false
        }
    }
}
