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
                .external(name: "SwiftUINavigation"),
                .external(name: "SharingGRDB"),
                .external(name: "CustomDump")
            ],
//            settings: .settings(base: [
////                "CODE_SIGN_STYLE": "Manual",
//                "CODE_SIGN_IDENTITY": "iPhone Developer",
//                "CODE_SIGNING_REQUIRED": "YES",
////                "PROVISIONING_PROFILE_SPECIFIER": "Anh Hoang"
            ///(WGS9LUKK32)
//            ], )
            settings: .settings(base: [
                "CODE_SIGN_IDENTITY": "Apple Development",
                "CODE_SIGNING_REQUIRED": "YES",
                "DEVELOPMENT_TEAM": "WGS9LUKK32"
            ])
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
