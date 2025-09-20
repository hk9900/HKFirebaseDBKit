// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "HKFirebaseDBKit",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "HKFirebaseDBKit",
            targets: ["HKFirebaseDBKit"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "12.0.0")
    ],
    targets: [
        .target(
            name: "HKFirebaseDBKit",
            dependencies: [
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk")
            ]
        ),
        .testTarget(
            name: "HKFirebaseDBKitTests",
            dependencies: ["HKFirebaseDBKit"]
        ),
    ]
)
