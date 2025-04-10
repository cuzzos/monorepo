import ProjectDescription

let project = Project(
    name: "Goonlytics",
    targets: [
        .target(
            name: "Goonlytics",
            destinations: .iOS,
            product: .app,
            bundleId: "io.tuist.Goonlytics",
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ],
                ]
            ),
            sources: ["Goonlytics/Sources/**"],
            resources: ["Goonlytics/Resources/**"],
            dependencies: [
                .external(name: "Dependencies"),
                .external(name: "DependenciesMacros"),
                .external(name: "SwiftNavigation"),
                .external(name: "SharingGRDB"),
            ]
        ),
        .target(
            name: "GoonlyticsTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "io.tuist.GoonlyticsTests",
            infoPlist: .default,
            sources: ["Goonlytics/Tests/**"],
            resources: [],
            dependencies: [.target(name: "Goonlytics")]
        ),
    ]
)
