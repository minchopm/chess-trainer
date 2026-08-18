// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ChessTrainer",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "ChessCore", targets: ["ChessCore"]),
        .library(name: "ChessEngine", targets: ["ChessEngine"]),
        .library(name: "ChessTraining", targets: ["ChessTraining"]),
        .library(name: "ChessTrainerApp", targets: ["ChessTrainerApp"]),
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

        .target(name: "ChessEngine", dependencies: ["CStockfish", "ChessCore"]),
        .testTarget(name: "ChessEngineTests", dependencies: ["ChessEngine"]),

        // Everything the trainer knows that is not a rule of chess: what a
        // position's features are, how good a move was, what to show next.
        // Deliberately free of the engine so it can be tested without one.
        .target(name: "ChessTraining", dependencies: ["ChessCore"]),
        .testTarget(name: "ChessTrainingTests", dependencies: ["ChessTraining"]),

        // Command-line driver for diagnosing engine problems.
        .executableTarget(name: "sfprobe", dependencies: ["ChessEngine"]),

        // The SwiftUI layer. Kept as a library rather than an app target so the
        // views can be compiled and previewed without the Xcode project.
        .target(
            name: "ChessTrainerApp",
            dependencies: ["ChessCore", "ChessEngine", "ChessTraining"]
        ),
    ],
    cxxLanguageStandard: .cxx17
)
