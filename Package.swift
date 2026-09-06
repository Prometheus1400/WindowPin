// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "WindowPin",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "WindowPin", targets: ["WindowPin"]),
        .executable(name: "windowpinctl", targets: ["WindowPinCLI"]),
    ],
    targets: [
        .target(
            name: "WindowPinIPC",
            path: "Shared"
        ),
        .executableTarget(
            name: "WindowPin",
            dependencies: ["WindowPinIPC"],
            path: "Sources",
            linkerSettings: [
                .unsafeFlags(["-framework", "AppKit"]),
                .unsafeFlags(["-framework", "ApplicationServices"]),
                .unsafeFlags(["-framework", "ScreenCaptureKit"]),
                .unsafeFlags(["-framework", "ServiceManagement"]),
            ]
        ),
        .executableTarget(
            name: "WindowPinCLI",
            dependencies: ["WindowPinIPC"],
            path: "CLI",
            linkerSettings: [
                .unsafeFlags(["-framework", "AppKit"]),
            ]
        ),
        .testTarget(
            name: "WindowPinIPCTests",
            dependencies: ["WindowPinIPC"]
        ),
    ]
)
