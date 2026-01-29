//
//  screenshotterApp.swift
//  screenshotter
//

import SwiftUI

@main
struct screenshotterApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.automatic)
        .defaultSize(width: 1200, height: 800)
        .commands {
            CommandGroup(replacing: .newItem) { }

            CommandGroup(after: .newItem) {
                Button("Export All Sizes") {
                    NotificationCenter.default.post(name: .exportAllSizes, object: nil)
                }
                .keyboardShortcut("e", modifiers: .command)

                Divider()

                Button("Export Configuration...") {
                    NotificationCenter.default.post(name: .exportConfiguration, object: nil)
                }
                .keyboardShortcut("e", modifiers: [.command, .shift])

                Button("Import Configuration...") {
                    NotificationCenter.default.post(name: .importConfiguration, object: nil)
                }
                .keyboardShortcut("i", modifiers: [.command, .shift])
            }
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let exportAllSizes = Notification.Name("exportAllSizes")
    static let exportConfiguration = Notification.Name("exportConfiguration")
    static let importConfiguration = Notification.Name("importConfiguration")
}
