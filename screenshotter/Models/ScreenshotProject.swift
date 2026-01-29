//
//  ScreenshotProject.swift
//  screenshotter
//

import SwiftUI
import AppKit
import Combine

enum TextPosition: String, CaseIterable, Codable {
    case above = "Above"
    case below = "Below"
}

enum DeviceType: String, CaseIterable, Codable {
    case iPhone = "iPhone"
    case iPad = "iPad"

    var frameImageNamePortrait: String {
        switch self {
        case .iPhone:
            return "iPhone 17 Pro - Deep Blue - Portrait"
        case .iPad:
            return "iPad Air 13\" - M2 - Space Gray - Portrait"
        }
    }

    var frameImageNameLandscape: String {
        switch self {
        case .iPhone:
            return "iPhone 17 Pro - Deep Blue - Landscape"
        case .iPad:
            return "iPad Air 13\" - M2 - Space Gray - Landscape"
        }
    }

    var displayName: String {
        rawValue
    }
}

enum BackgroundStyle: String, CaseIterable, Codable {
    case solid = "Solid"
    case gradient = "Gradient"
}

// MARK: - Codable Color Helper

struct CodableColor: Codable, Equatable {
    var red: Double
    var green: Double
    var blue: Double
    var alpha: Double

    init(_ color: Color) {
        let nsColor = NSColor(color).usingColorSpace(.deviceRGB) ?? NSColor.white
        self.red = Double(nsColor.redComponent)
        self.green = Double(nsColor.greenComponent)
        self.blue = Double(nsColor.blueComponent)
        self.alpha = Double(nsColor.alphaComponent)
    }

    init(red: Double, green: Double, blue: Double, alpha: Double = 1.0) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    var color: Color {
        Color(red: red, green: green, blue: blue, opacity: alpha)
    }

    static let white = CodableColor(red: 1, green: 1, blue: 1)
    static let black = CodableColor(red: 0, green: 0, blue: 0)
    static let tealPrimary = CodableColor(red: 0.078, green: 0.722, blue: 0.651)
}

// MARK: - Screenshot Item Settings (per-screenshot customization)

struct ScreenshotItemSettings: Codable, Equatable {
    var titleText: String = "Your Title Here"
    var subtitleText: String = "Subtitle goes here"
    var titleFontSize: CGFloat = 128
    var subtitleFontSize: CGFloat = 94
    var textPosition: TextPosition = .above
    var textColor: CodableColor = .black
    var screenshotYOffset: CGFloat = 0
    var deviceType: DeviceType = .iPhone
    var backgroundStyle: BackgroundStyle = .solid
    var backgroundColor: CodableColor = .white
    var backgroundGradientStart: CodableColor = .white
    var backgroundGradientEnd: CodableColor = .tealPrimary
    var backgroundGradientAngle: CGFloat = 45
}

// MARK: - Screenshot Item

struct ScreenshotItem: Identifiable {
    let id: UUID
    var image: NSImage
    var settings: ScreenshotItemSettings

    init(image: NSImage, settings: ScreenshotItemSettings = ScreenshotItemSettings()) {
        self.id = UUID()
        self.image = image
        self.settings = settings
    }

    // Convenience accessors
    var titleText: String {
        get { settings.titleText }
        set { settings.titleText = newValue }
    }

    var subtitleText: String {
        get { settings.subtitleText }
        set { settings.subtitleText = newValue }
    }
}

// MARK: - Project Configuration (for JSON export/import)

struct ProjectConfiguration: Codable {
    var screenshots: [ScreenshotConfiguration]
    var exportDate: Date?

    struct ScreenshotConfiguration: Codable {
        var id: String
        var imageName: String
        var settings: ScreenshotItemSettings
    }
}

// MARK: - Screenshot Project

class ScreenshotProject: ObservableObject {
    static let maxImages = 5

    @Published var screenshots: [ScreenshotItem] = []

    // Current editing values (bound to UI)
    @Published var titleText: String = "Your Title Here"
    @Published var subtitleText: String = "Subtitle goes here"
    @Published var titleFontSize: CGFloat = 128
    @Published var subtitleFontSize: CGFloat = 94
    @Published var textPosition: TextPosition = .above
    @Published var textColor: Color = .black
    @Published var screenshotYOffset: CGFloat = 0
    @Published var deviceType: DeviceType = .iPhone
    @Published var backgroundStyle: BackgroundStyle = .solid
    @Published var backgroundColor: Color = .white
    @Published var backgroundGradientStart: Color = .white
    @Published var backgroundGradientEnd: Color = .tealPrimary
    @Published var backgroundGradientAngle: CGFloat = 45

    private var _selectedImageIndex: Int = 0
    var selectedImageIndex: Int {
        get { _selectedImageIndex }
        set {
            // Save current settings to current screenshot before switching
            saveCurrentSettingsToScreenshot()
            _selectedImageIndex = newValue
            // Load settings from new screenshot
            loadSettingsFromCurrentScreenshot()
        }
    }

    var hasImage: Bool {
        !screenshots.isEmpty
    }

    var selectedImage: NSImage? {
        guard !screenshots.isEmpty else { return nil }
        let clampedIndex = max(0, min(selectedImageIndex, screenshots.count - 1))
        return screenshots[clampedIndex].image
    }

    var selectedScreenshot: ScreenshotItem? {
        guard !screenshots.isEmpty else { return nil }
        let clampedIndex = max(0, min(selectedImageIndex, screenshots.count - 1))
        return screenshots[clampedIndex]
    }

    // MARK: - Settings Sync

    func saveCurrentSettingsToScreenshot() {
        guard !screenshots.isEmpty && _selectedImageIndex < screenshots.count else { return }
        screenshots[_selectedImageIndex].settings = ScreenshotItemSettings(
            titleText: titleText,
            subtitleText: subtitleText,
            titleFontSize: titleFontSize,
            subtitleFontSize: subtitleFontSize,
            textPosition: textPosition,
            textColor: CodableColor(textColor),
            screenshotYOffset: screenshotYOffset,
            deviceType: deviceType,
            backgroundStyle: backgroundStyle,
            backgroundColor: CodableColor(backgroundColor),
            backgroundGradientStart: CodableColor(backgroundGradientStart),
            backgroundGradientEnd: CodableColor(backgroundGradientEnd),
            backgroundGradientAngle: backgroundGradientAngle
        )
    }

    func loadSettingsFromCurrentScreenshot() {
        guard !screenshots.isEmpty && _selectedImageIndex < screenshots.count else { return }
        let settings = screenshots[_selectedImageIndex].settings
        titleText = settings.titleText
        subtitleText = settings.subtitleText
        titleFontSize = settings.titleFontSize
        subtitleFontSize = settings.subtitleFontSize
        textPosition = settings.textPosition
        textColor = settings.textColor.color
        screenshotYOffset = settings.screenshotYOffset
        deviceType = settings.deviceType
        backgroundStyle = settings.backgroundStyle
        backgroundColor = settings.backgroundColor.color
        backgroundGradientStart = settings.backgroundGradientStart.color
        backgroundGradientEnd = settings.backgroundGradientEnd.color
        backgroundGradientAngle = settings.backgroundGradientAngle
    }

    // Convenience property for backward compatibility
    var importedImages: [NSImage] {
        screenshots.map { $0.image }
    }

    func addImages(_ images: [NSImage]) {
        guard !images.isEmpty else { return }
        // Save current settings before adding
        saveCurrentSettingsToScreenshot()

        for image in images {
            guard screenshots.count < Self.maxImages else { break }
            // New screenshots get default settings
            screenshots.append(ScreenshotItem(image: image))
        }
        if !screenshots.isEmpty {
            _selectedImageIndex = screenshots.count - 1
            loadSettingsFromCurrentScreenshot()
        }
    }

    func removeImage(at index: Int) {
        guard screenshots.indices.contains(index) else { return }
        screenshots.remove(at: index)

        if screenshots.isEmpty {
            _selectedImageIndex = 0
        } else if index < selectedImageIndex {
            _selectedImageIndex = max(0, _selectedImageIndex - 1)
        } else if _selectedImageIndex >= screenshots.count {
            _selectedImageIndex = screenshots.count - 1
        }
        loadSettingsFromCurrentScreenshot()
    }

    func clearImages() {
        screenshots.removeAll()
        _selectedImageIndex = 0
    }

    func reset() {
        clearImages()
        titleText = "Your Title Here"
        subtitleText = "Subtitle goes here"
        titleFontSize = 128
        subtitleFontSize = 94
        textPosition = .above
        textColor = .black
        screenshotYOffset = 0
        deviceType = .iPhone
        backgroundStyle = .solid
        backgroundColor = .white
        backgroundGradientStart = .white
        backgroundGradientEnd = .tealPrimary
        backgroundGradientAngle = 45
    }

    // MARK: - JSON Export/Import

    func exportConfiguration() -> ProjectConfiguration {
        saveCurrentSettingsToScreenshot()

        let screenshotConfigs = screenshots.enumerated().map { index, item in
            ProjectConfiguration.ScreenshotConfiguration(
                id: item.id.uuidString,
                imageName: "screenshot_\(index + 1).png",
                settings: item.settings
            )
        }

        return ProjectConfiguration(
            screenshots: screenshotConfigs,
            exportDate: Date()
        )
    }

    func exportConfigurationJSON() -> String? {
        let config = exportConfiguration()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        guard let data = try? encoder.encode(config) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func importConfiguration(_ config: ProjectConfiguration) {
        // Update settings for existing screenshots that match by index
        for (index, screenshotConfig) in config.screenshots.enumerated() {
            guard index < screenshots.count else { continue }
            screenshots[index].settings = screenshotConfig.settings
        }

        // Reload current screenshot settings
        loadSettingsFromCurrentScreenshot()
    }

    func importConfigurationJSON(_ json: String) -> Bool {
        guard let data = json.data(using: .utf8) else { return false }

        let decoder = JSONDecoder()
        guard let config = try? decoder.decode(ProjectConfiguration.self, from: data) else { return false }

        importConfiguration(config)
        return true
    }
}
