import Foundation
import Testing
import MLXLMCommon

@Suite("Pico tokenizer shim lifetime")
struct PicoTokenizerLifetimeTests {
    @Test("The caller can find a chained shim without the library deleting its tokenizer")
    func chainedShimsRemainAvailableUntilTheCallerReleasesThem() throws {
        let files = FileManager.default
        let base = files.temporaryDirectory
        let first = base.appendingPathComponent("vmlx-tokenizer-shim-\(UUID())", isDirectory: true)
        let backing = base.appendingPathComponent("vmlx-chat-template-shim-\(UUID())", isDirectory: true)
        try files.createDirectory(at: first, withIntermediateDirectories: true)
        try files.createDirectory(at: backing, withIntermediateDirectories: true)
        defer {
            try? files.removeItem(at: first)
            try? files.removeItem(at: backing)
        }
        let tokenizer = backing.appendingPathComponent("tokenizer.json")
        try Data("tokenizer data".utf8).write(to: tokenizer)
        let linked = first.appendingPathComponent("tokenizer.json")
        try files.createSymbolicLink(atPath: linked.path,
                                     withDestinationPath: "../\(backing.lastPathComponent)/tokenizer.json")
        let returned = JangLoader.temporaryShimDirectories(behind: first)
        #expect(Set(returned.map { $0.standardizedFileURL.path }) == Set([first.path, backing.path]))
        #expect(try Data(contentsOf: linked) == Data("tokenizer data".utf8))
        #expect(JangLoader.temporaryShimDirectories(behind: first).count == 2)
    }

    @Test("A similarly named directory inside a model is never returned for cleanup")
    func modelDirectoriesAreNotTemporaryShims() throws {
        let files = FileManager.default
        let model = files.temporaryDirectory.appendingPathComponent("pico-model-\(UUID())", isDirectory: true)
        let nested = model.appendingPathComponent("vmlx-tokenizer-shim-source", isDirectory: true)
        try files.createDirectory(at: nested, withIntermediateDirectories: true)
        defer { try? files.removeItem(at: model) }
        #expect(JangLoader.temporaryShimDirectories(behind: nested).isEmpty)
        #expect(files.fileExists(atPath: nested.path))
    }
}
