//
//  GradientHelpers.swift
//  screenshotter
//

import SwiftUI
import CoreGraphics

struct GradientHelpers {
    static func unitPoints(for angle: CGFloat) -> (start: UnitPoint, end: UnitPoint) {
        let radians = angle * .pi / 180
        let dx = cos(radians)
        let dy = sin(radians)
        let start = UnitPoint(x: 0.5 - dx * 0.5, y: 0.5 - dy * 0.5)
        let end = UnitPoint(x: 0.5 + dx * 0.5, y: 0.5 + dy * 0.5)
        return (start, end)
    }

    static func cgPoints(for angle: CGFloat, in rect: CGRect) -> (start: CGPoint, end: CGPoint) {
        let radians = angle * .pi / 180
        let dx = cos(radians)
        let dy = sin(radians)
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let length = 0.5 * sqrt(rect.width * rect.width + rect.height * rect.height)
        let start = CGPoint(x: center.x - dx * length, y: center.y - dy * length)
        let end = CGPoint(x: center.x + dx * length, y: center.y + dy * length)
        return (start, end)
    }
}
