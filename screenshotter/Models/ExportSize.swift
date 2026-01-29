//
//  ExportSize.swift
//  screenshotter
//

import Foundation
import CoreGraphics

struct ExportSize: Identifiable, Hashable {
    let id = UUID()
    let width: Int
    let height: Int
    let deviceType: DeviceType
    let displayName: String

    var size: CGSize {
        CGSize(width: width, height: height)
    }

    var isPortrait: Bool {
        height > width
    }

    var isLandscape: Bool {
        width > height
    }

    var fileName: String {
        let orientation = isPortrait ? "portrait" : "landscape"
        return "\(deviceType.rawValue)_\(width)x\(height)_\(orientation).png"
    }

    var aspectRatio: CGFloat {
        CGFloat(width) / CGFloat(height)
    }
}

struct ExportSizes {
    // iPhone (6.5" & 6.9" displays)
    static let iPhone_1284x2778 = ExportSize(width: 1284, height: 2778, deviceType: .iPhone, displayName: "iPhone 6.5\" Portrait")
    static let iPhone_2778x1284 = ExportSize(width: 2778, height: 1284, deviceType: .iPhone, displayName: "iPhone 6.5\" Landscape")
    static let iPhone_1242x2688 = ExportSize(width: 1242, height: 2688, deviceType: .iPhone, displayName: "iPhone 6.5\" Alt Portrait")
    static let iPhone_2688x1242 = ExportSize(width: 2688, height: 1242, deviceType: .iPhone, displayName: "iPhone 6.5\" Alt Landscape")

    // iPad (12.9" & 13" displays)
    static let iPad_2064x2752 = ExportSize(width: 2064, height: 2752, deviceType: .iPad, displayName: "iPad 13\" Portrait")
    static let iPad_2752x2064 = ExportSize(width: 2752, height: 2064, deviceType: .iPad, displayName: "iPad 13\" Landscape")
    static let iPad_2048x2732 = ExportSize(width: 2048, height: 2732, deviceType: .iPad, displayName: "iPad 12.9\" Portrait")
    static let iPad_2732x2048 = ExportSize(width: 2732, height: 2048, deviceType: .iPad, displayName: "iPad 12.9\" Landscape")

    static let allSizes: [ExportSize] = [
        iPhone_1284x2778,
        iPhone_2778x1284,
        iPhone_1242x2688,
        iPhone_2688x1242,
        iPad_2064x2752,
        iPad_2752x2064,
        iPad_2048x2732,
        iPad_2732x2048
    ]

    static let iPhoneSizes: [ExportSize] = [
        iPhone_1284x2778,
        iPhone_2778x1284,
        iPhone_1242x2688,
        iPhone_2688x1242
    ]

    static let iPadSizes: [ExportSize] = [
        iPad_2064x2752,
        iPad_2752x2064,
        iPad_2048x2732,
        iPad_2732x2048
    ]

    // Portrait-only sizes for export (landscape not currently supported)
    static let iPhonePortraitSizes: [ExportSize] = [
        iPhone_1284x2778,
        iPhone_1242x2688
    ]

    static let iPadPortraitSizes: [ExportSize] = [
        iPad_2064x2752,
        iPad_2048x2732
    ]

    static func portraitSizes(for deviceType: DeviceType) -> [ExportSize] {
        allSizes.filter { $0.deviceType == deviceType && $0.isPortrait }
    }

    static func landscapeSizes(for deviceType: DeviceType) -> [ExportSize] {
        allSizes.filter { $0.deviceType == deviceType && $0.isLandscape }
    }

    /// Returns export sizes for a device type (portrait only, landscape not supported)
    static func sizes(for deviceType: DeviceType) -> [ExportSize] {
        switch deviceType {
        case .iPhone:
            return iPhonePortraitSizes
        case .iPad:
            return iPadPortraitSizes
        }
    }
}
