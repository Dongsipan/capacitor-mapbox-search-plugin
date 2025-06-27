// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CapacitorMapboxSearchPlugin",
    platforms: [.iOS(.v14)],
    products: [
        .library(
            name: "CapacitorMapboxSearchPlugin",
            targets: ["CapacitorMapboxSearchPlugin"])
    ],
    dependencies: [
        .package(url: "https://github.com/ionic-team/capacitor-swift-pm.git", from: "7.0.0"),
        .package(url: "https://github.com/mapbox/search-ios.git", from: "2.13.2"),
        .package(url: "https://github.com/mapbox/mapbox-maps-ios.git", from: "11.13.1")
    ],
    targets: [
        .target(
            name: "CapacitorMapboxSearchPlugin",
            dependencies: [
                .product(name: "Capacitor", package: "capacitor-swift-pm"),
                .product(name: "Cordova", package: "capacitor-swift-pm"),
                .product(name: "MapboxSearch", package: "search-ios"),
                .product(name: "MapboxSearchUI", package: "search-ios"),
                .product(name: "MapboxMaps", package: "mapbox-maps-ios")
            ],
            path: "ios/Sources/CapacitorMapboxSearchPlugin"),
        .testTarget(
            name: "CapacitorMapboxSearchPluginTests",
            dependencies: ["CapacitorMapboxSearchPlugin"],
            path: "ios/Tests/CapacitorMapboxSearchPluginTests")
    ]
)
