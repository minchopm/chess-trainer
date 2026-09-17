import Foundation
import Testing

/// The engine framework has to be complete in the repository, not just on the
/// machine that built it.
///
/// `CReckless.xcframework` is a binary target: four static libraries, four
/// module maps, and the header each module map names. It is committed so that
/// nobody needs a Rust toolchain to build the app. But it is written into a
/// vendored directory whose own `.gitignore` carries `reckless*` — a rule meant
/// for the engine binary of that name, which also matches every `reckless.h`
/// the build script copies in.
///
/// The result is a framework that works perfectly on the machine that produced
/// it, because the files are sitting there untracked, and fails on every clone
/// with "header 'reckless.h' not found" — three steps from the cause and on
/// somebody else's afternoon. That has happened twice: once for the header the
/// script reads, once for the four it writes. A rule per file was not the
/// lesson. This is: whatever the framework is made of, the repository has it.
@Suite("The vendored engine framework")
struct VendoredFramework {
    static let framework = URL(filePath: #filePath)
        .deletingLastPathComponent()   // ChessEngineTests
        .deletingLastPathComponent()   // Tests
        .deletingLastPathComponent()   // ios
        .appending(path: "Vendor/Reckless/CReckless.xcframework")

    /// Only where there is a checkout to ask. A package built from a tarball or
    /// a derived copy has no index, and the question means nothing there.
    static var isCheckout: Bool {
        FileManager.default.fileExists(atPath: framework.path())
            && git(["rev-parse", "--is-inside-work-tree"])?.trimmingCharacters(in: .whitespacesAndNewlines) == "true"
    }

    static func git(_ arguments: [String]) -> String? {
        let task = Process()
        task.executableURL = URL(filePath: "/usr/bin/git")
        task.arguments = ["-C", framework.path()] + arguments
        let out = Pipe()
        task.standardOutput = out
        task.standardError = Pipe()
        guard (try? task.run()) != nil else { return nil }
        let data = out.fileHandleForReading.readDataToEndOfFile()
        task.waitUntilExit()
        guard task.terminationStatus == 0 else { return nil }
        return String(decoding: data, as: UTF8.self)
    }

    @Test("every file in it is committed", .enabled(if: isCheckout, "needs a git checkout"))
    func everyFileIsCommitted() throws {
        let tracked = Set(
            (Self.git(["ls-files"]) ?? "")
                .split(separator: "\n")
                .map(String.init)
        )
        #expect(!tracked.isEmpty, "the framework should be in the repository at all")

        let enumerator = try #require(FileManager.default.enumerator(
            at: Self.framework, includingPropertiesForKeys: [.isRegularFileKey]
        ))
        var missing: [String] = []
        for case let url as URL in enumerator {
            guard (try? url.resourceValues(forKeys: [.isRegularFileKey]))?.isRegularFile == true
            else { continue }
            let relative = url.path().replacingOccurrences(of: Self.framework.path() + "/", with: "")
            // The rule that keeps the headers in is allowed to be the one file
            // git does not have to be told about twice.
            guard relative != ".gitignore" else { continue }
            if !tracked.contains(relative) { missing.append(relative) }
        }
        #expect(missing.isEmpty, "a clone would not have: \(missing.sorted().joined(separator: ", "))")
    }
}
