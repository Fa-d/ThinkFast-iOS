// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Intently",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "Intently",
            targets: ["Intently"]),
    ],
    dependencies: [
        // Firebase
        .package(
            url: "https://github.com/firebase/firebase-ios-sdk.git",
            from: "10.24.0"
        ),
        // Facebook SDK
        .package(
            url: "https://github.com/facebook/facebook-ios-sdk.git",
            from: "17.0.0"
        ),
    ],
    targets: [
        .target(
            name: "Intently",
            dependencies: [
                // Firebase
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk"),
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseCrashlytics", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                // Facebook
                .product(name: "FacebookLogin", package: "facebook-ios-sdk"),
                .product(name: "FacebookCore", package: "facebook-ios-sdk"),
            ],
            path: "Intently"
        ),
        .testTarget(
            name: "IntentlyTests",
            dependencies: ["Intently"],
            path: "IntentlyTests"
        ),
    ]
)
