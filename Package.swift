// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MacOSHub",
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
            dependencies: ["HubDiagnostics", "HubSettings", "HubPermissions"]
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
        .executableTarget(
            name: "MacOSHub",
            dependencies: [
                "HubCore",
                "HubCleaner",
                "HubSystemMonitor",
                "HubDeviceControl",
                "HubDynamicIsland",
                "HubSettings",
                "HubPermissions",
                "HubDiagnostics",
            ],
            resources: [.process("Resources")],
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
    ]
)
