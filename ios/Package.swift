// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "BrassPawn",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "ChessCore", targets: ["ChessCore"]),
        .library(name: "ChessEngine", targets: ["ChessEngine"]),
        .library(name: "ChessTraining", targets: ["ChessTraining"]),
        .library(name: "BoardScene", targets: ["BoardScene"]),
        .library(name: "BoardUI", targets: ["BoardUI"]),
        .library(name: "BrassPawnApp", targets: ["BrassPawnApp"]),
    ],
    targets: [
        // Rules of chess. No dependencies, no I/O — so it can be exercised from
        // the command line, which is what makes the perft suite practical.
        .target(name: "ChessCore"),
        .testTarget(name: "ChessCoreTests", dependencies: ["ChessCore"]),

        // Stockfish itself, plus a flat C surface over its Engine class.
        // GPLv3 — see Vendor/Stockfish/Copying.txt.
        .target(
            name: "CStockfish",
            path: "Vendor/Stockfish",
            exclude: [
                "Copying.txt",
                "AUTHORS",
                "VERSION.txt",
                "src/Makefile",
                "src/main.cpp",          // the standalone binary's entry point
                "src/incbin/UNLICENCE",
            ],
            sources: ["src", "bridge"],
            publicHeadersPath: "bridge/include",
            cxxSettings: [
                .headerSearchPath("src"),
                .define("NDEBUG"),
                // Load networks from files at runtime instead of embedding them
                // in the binary: on iOS they ship as bundle resources, and the
                // app should choose the path rather than the build.
                .define("NNUE_EMBEDDING_OFF"),
            ]
        ),

        // Reckless, a second engine, as a prebuilt static library.
        //
        // Binary rather than source because it is Rust: cargo builds it, and
        // SwiftPM cannot. `ios/scripts/build-reckless.sh` produces the
        // xcframework — device, simulator and macOS, the last so that
        // `swift test` can exercise the engine on the host. That script has to
        // have been run before this package will build. AGPLv3; see NOTICE.md.
        .binaryTarget(name: "CReckless", path: "Vendor/Reckless/CReckless.xcframework"),

        .target(name: "ChessEngine", dependencies: ["CStockfish", "CReckless", "ChessCore"]),
        .testTarget(name: "ChessEngineTests", dependencies: ["ChessEngine"]),

        // Everything the trainer knows that is not a rule of chess: what a
        // position's features are, how good a move was, what to show next.
        // Deliberately free of the engine so it can be tested without one.
        .target(name: "ChessTraining", dependencies: ["ChessCore"]),
        .testTarget(name: "ChessTrainingTests", dependencies: ["ChessTraining"]),

        // Command-line driver for diagnosing engine problems.
        .executableTarget(name: "sfprobe", dependencies: ["ChessEngine"]),

        // The board in three dimensions: SceneKit, and the turned pieces
        // the site draws, ported profile for profile. Depends on the rules and
        // on nothing else, so a game can be played out on it without the app.
        .target(name: "BoardScene", dependencies: ["ChessCore"]),
        .testTarget(name: "BoardSceneTests", dependencies: ["BoardScene"]),

        // The board in two dimensions, and the palette it is drawn in. Split
        // out of the app so the App Clip can show a position: the clip has no
        // room for an engine, and before this the board could not be compiled
        // without linking one.
        .target(name: "BoardUI", dependencies: ["ChessCore", "ChessTraining"]),
        .testTarget(name: "BoardUITests", dependencies: ["BoardUI"]),

        // The SwiftUI layer. Kept as a library rather than an app target so the
        // views can be compiled and previewed without the Xcode project.
        .target(
            name: "BrassPawnApp",
            dependencies: ["ChessCore", "ChessEngine", "ChessTraining", "BoardScene", "BoardUI"]
        ),
        .testTarget(name: "BrassPawnAppTests", dependencies: ["BrassPawnApp"]),
    ],
    cxxLanguageStandard: .cxx17
)
