//
//  ControlPanelView.swift
//  screenshotter
//

import SwiftUI

struct ControlPanelView: View {
    @ObservedObject var project: ScreenshotProject
    var onExport: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Screenshot Section
                sectionView(title: "Screenshot", icon: "photo") {
                    DropZoneView(project: project)
                }

                Divider()

                // Text Section
                sectionView(title: "Text", icon: "textformat") {
                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Title")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("Enter title", text: $project.titleText)
                                .textFieldStyle(.roundedBorder)
                                .disabled(!project.hasImage)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Subtitle")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("Enter subtitle", text: $project.subtitleText)
                                .textFieldStyle(.roundedBorder)
                                .disabled(!project.hasImage)
                        }

                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Title Size: \(Int(project.titleFontSize))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Slider(value: $project.titleFontSize, in: 24...200, step: 2)
                                    .tint(.tealPrimary)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Subtitle Size: \(Int(project.subtitleFontSize))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Slider(value: $project.subtitleFontSize, in: 16...150, step: 2)
                                    .tint(.tealPrimary)
                            }
                        }

                        HStack {
                            Text("Text Color")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            ColorPicker("", selection: $project.textColor)
                                .labelsHidden()
                        }
                    }
                }

                Divider()

                // Position Section
                sectionView(title: "Position", icon: "arrow.up.arrow.down") {
                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Text Position")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Picker("", selection: $project.textPosition) {
                                ForEach(TextPosition.allCases, id: \.self) { position in
                                    Text(position.rawValue).tag(position)
                                }
                            }
                            .pickerStyle(.segmented)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Device Y Offset: \(Int(project.screenshotYOffset))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Slider(value: $project.screenshotYOffset, in: -200...200, step: 5)
                                .tint(.tealPrimary)

                            HStack {
                                Text("-200")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("0")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("+200")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                Divider()

                // Background Section
                sectionView(title: "Background", icon: "paintpalette") {
                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Style")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Picker("", selection: $project.backgroundStyle) {
                                ForEach(BackgroundStyle.allCases, id: \.self) { style in
                                    Text(style.rawValue).tag(style)
                                }
                            }
                            .pickerStyle(.segmented)
                        }

                        HStack {
                            Text(project.backgroundStyle == .gradient ? "Gradient" : "Background Color")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        if project.backgroundStyle == .gradient {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("Start")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    ColorPicker("", selection: $project.backgroundGradientStart)
                                        .labelsHidden()
                                }

                                HStack {
                                    Text("End")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    ColorPicker("", selection: $project.backgroundGradientEnd)
                                        .labelsHidden()
                                }

                                HStack {
                                    Text("Angle: \(Int(project.backgroundGradientAngle))°")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Button("Swap") {
                                        swapGradientColors()
                                    }
                                    .buttonStyle(.plain)
                                    .font(.caption2)
                                    .foregroundColor(.tealPrimary)
                                }

                                Slider(value: $project.backgroundGradientAngle, in: 0...360, step: 5)
                                    .tint(.tealPrimary)
                            }
                        } else {
                            HStack {
                                Spacer()
                                ColorPicker("", selection: $project.backgroundColor)
                                    .labelsHidden()
                            }

                            // Color presets
                            HStack(spacing: 8) {
                                colorPreset(.white, label: "White")
                                colorPreset(.black, label: "Black")
                                colorPreset(Color(red: 0.95, green: 0.95, blue: 0.97), label: "Light Gray")
                                colorPreset(.tealPrimary, label: "Teal")
                                colorPreset(Color(red: 0.2, green: 0.2, blue: 0.3), label: "Dark")
                            }
                        }
                    }
                }

                Divider()

                // Device Section
                sectionView(title: "Device", icon: "iphone") {
                    Picker("", selection: $project.deviceType) {
                        ForEach(DeviceType.allCases, id: \.self) { device in
                            Text(device.displayName).tag(device)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Spacer(minLength: 20)

                // Export Button
                ExportButton(action: onExport, isEnabled: project.hasImage)
            }
            .padding(20)
        }
        .frame(width: 300)
        .background(Color(NSColor.controlBackgroundColor))
    }

    private func swapGradientColors() {
        let start = project.backgroundGradientStart
        project.backgroundGradientStart = project.backgroundGradientEnd
        project.backgroundGradientEnd = start
    }

    @ViewBuilder
    private func sectionView<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(title)
            }
            .sectionHeader()

            content()
        }
    }

    @ViewBuilder
    private func colorPreset(_ color: Color, label: String) -> some View {
        Button {
            project.backgroundColor = color
        } label: {
            RoundedRectangle(cornerRadius: 6)
                .fill(color)
                .frame(width: 32, height: 32)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .overlay(
                    project.backgroundColor == color ?
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(color == .white || color == Color(red: 0.95, green: 0.95, blue: 0.97) ? .black : .white)
                    : nil
                )
        }
        .buttonStyle(.plain)
        .help(label)
    }
}
