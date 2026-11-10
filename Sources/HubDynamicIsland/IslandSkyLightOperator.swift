import AppKit
import Darwin

/// Pins the island panel to the system notch overlay space (same approach as DynamicNotch).
@MainActor
final class IslandSkyLightOperator {
    static let shared = IslandSkyLightOperator()

    private enum SpaceLevel: Int32, CaseIterable {
        case notchSurface = 2_147_483_647
    }

    private typealias MainConnectionIDFunction = @convention(c) () -> Int32
    private typealias SpaceCreateFunction = @convention(c) (Int32, Int32, Int32) -> Int32
    private typealias SpaceSetAbsoluteLevelFunction = @convention(c) (Int32, Int32, Int32) -> Int32
    private typealias ShowSpacesFunction = @convention(c) (Int32, CFArray) -> Int32
    private typealias AddWindowsFunction = @convention(c) (Int32, Int32, CFArray, Int32) -> Int32

    private let connection: Int32?
    private let spaces: [SpaceLevel: Int32]
    private let addWindows: AddWindowsFunction?

    var isAvailable: Bool {
        connection != nil && !spaces.isEmpty && addWindows != nil
    }

    private init() {
        let frameworkPath = "/System/Library/PrivateFrameworks/SkyLight.framework/Versions/A/SkyLight"
        guard
            let handle = dlopen(frameworkPath, RTLD_NOW),
            let mainSymbol = dlsym(handle, "SLSMainConnectionID"),
            let createSymbol = dlsym(handle, "SLSSpaceCreate"),
            let levelSymbol = dlsym(handle, "SLSSpaceSetAbsoluteLevel"),
            let showSymbol = dlsym(handle, "SLSShowSpaces"),
            let addSymbol = dlsym(handle, "SLSSpaceAddWindowsAndRemoveFromSpaces")
        else {
            connection = nil
            spaces = [:]
            addWindows = nil
            return
        }

        let mainConnectionID = unsafeBitCast(mainSymbol, to: MainConnectionIDFunction.self)
        let spaceCreate = unsafeBitCast(createSymbol, to: SpaceCreateFunction.self)
        let spaceSetAbsoluteLevel = unsafeBitCast(levelSymbol, to: SpaceSetAbsoluteLevelFunction.self)
        let showSpaces = unsafeBitCast(showSymbol, to: ShowSpacesFunction.self)
        let addWindowsFn = unsafeBitCast(addSymbol, to: AddWindowsFunction.self)

        let connection = mainConnectionID()
        var built: [SpaceLevel: Int32] = [:]
        for level in SpaceLevel.allCases {
            let space = spaceCreate(connection, 1, 0)
            guard space != 0 else { continue }
            _ = spaceSetAbsoluteLevel(connection, space, level.rawValue)
            _ = showSpaces(connection, [space] as CFArray)
            built[level] = space
        }

        self.connection = connection
        self.spaces = built
        self.addWindows = addWindowsFn
    }

    func delegateWindow(_ window: NSWindow) {
        guard let connection,
              let space = spaces[.notchSurface],
              let addWindows else { return }
        _ = addWindows(connection, space, [window.windowNumber] as CFArray, 7)
    }
}
