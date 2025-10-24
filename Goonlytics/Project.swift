import ProjectDescription

let project = Project(
    name: "Goonlytics",
    settings: .settings(
        base: [
            "SWIFT_VERSION": "6.0"
        ]
    ),
    targets: [
        .target(
            name: "Goonlytics",
            destinations: .iOS,
            product: .app,
            bundleId: "com.thiccc.Thiccc",
            infoPlist: .extendingDefault(
                with: [
                    "CFBundleShortVersionString": "0.1.0",
                    "CFBundleVersion": "1",
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
                .external(name: "SwiftUINavigation"),
                .external(name: "SharingGRDB"),
                .external(name: "CustomDump"),
                .external(name: "IssueReporting")
            ],
//            settings: .settings(base: [
////                "CODE_SIGN_STYLE": "Manual",
//                "CODE_SIGN_IDENTITY": "iPhone Developer",
//                "CODE_SIGNING_REQUIRED": "YES",
////                "PROVISIONING_PROFILE_SPECIFIER": "Anh Hoang"
            ///(WGS9LUKK32)
//            ], )
            settings: .settings(base: [
                "CODE_SIGN_STYLE": "Automatic",
                "DEVELOPMENT_TEAM": "WGS9LUKK32"
            ])
        ),
        .target(
            name: "GoonlyticsTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.thiccc.ThicccTests",
            infoPlist: .default,
            sources: ["Goonlytics/Tests/**"],
            resources: [],
            dependencies: [.target(name: "Goonlytics")]
        ),
    ]
)
