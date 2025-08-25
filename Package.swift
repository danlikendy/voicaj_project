// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "VoiceActionJournal",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "VoiceActionJournal",
            targets: ["VoiceActionJournal"]),
    ],
    dependencies: [
        // Dependencies will be added here as needed
    ],
    targets: [
        .target(
            name: "VoiceActionJournal",
            dependencies: []),
        .testTarget(
            name: "VoiceActionJournalTests",
            dependencies: ["VoiceActionJournal"]),
    ]
)
