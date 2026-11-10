// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MacOSHub",
    defaultLocalization: "ru",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "MacOSHub", targets: ["MacOSHub"]),
    ],
    targets: [
        .target(name: "HubDiagnostics"),
        .target(
            name: "HubSettings",
            dependencies: ["HubDiagnostics"]
        ),
        .target(
            name: "HubPermissions",
            dependencies: ["HubDiagnostics", "HubSettings"]
        ),
        .target(
            name: "HubCore",
            dependencies: ["HubDiagnostics", "HubSettings", "HubPermissions"],
            resources: [.process("Resources")]
        ),
        .target(
            name: "HubSystemMonitor",
            dependencies: ["HubCore", "HubDiagnostics"]
        ),
        .target(
            name: "HubCleaner",
            dependencies: ["HubCore", "HubDiagnostics"]
        ),
        .target(
            name: "HubDeviceControl",
            dependencies: ["HubCore", "HubDiagnostics", "HubPermissions", "HubSettings"]
        ),
        .target(
            name: "HubDynamicIsland",
            dependencies: ["HubCore", "HubDiagnostics", "HubSettings", "HubSystemMonitor"]
        ),
        .target(
            name: "HubShortcuts",
            dependencies: ["HubCore", "HubSettings", "HubDiagnostics"],
            linkerSettings: [.linkedFramework("Carbon")]
        ),
        .executableTarget(
            name: "MacOSHub",
            dependencies: [
                "HubCore",
                "HubCleaner",
                "HubSystemMonitor",
                "HubDeviceControl",
                "HubDynamicIsland",
                "HubShortcuts",
                "HubSettings",
                "HubPermissions",
                "HubDiagnostics",
            ],
            swiftSettings: [.unsafeFlags(["-parse-as-library"], .when(configuration: .debug))]
        ),
        .testTarget(
            name: "HubCleanerTests",
            dependencies: ["HubCleaner"]
        ),
        .testTarget(
            name: "HubSystemMonitorTests",
            dependencies: ["HubSystemMonitor"]
        ),
        .testTarget(
            name: "HubCoreTests",
            dependencies: ["HubCore", "HubSettings"]
        ),
        .testTarget(
            name: "MacOSHubLocalizationTests",
            dependencies: ["HubCore", "HubCleaner", "HubShortcuts"]
        ),
    ]
)
