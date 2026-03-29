import XCTest
@testable import PlexusOneDesktop

final class WindowStateManagerTests: XCTestCase {

    var mockFileSystem: MockFileSystem!
    var tempStateDirectory: URL!

    override func setUp() {
        super.setUp()
        mockFileSystem = MockFileSystem()
        tempStateDirectory = URL(fileURLWithPath: "/tmp/test-plexusone")
    }

    override func tearDown() {
        mockFileSystem = nil
        tempStateDirectory = nil
        super.tearDown()
    }

    // MARK: - Helper

    private func makeManager(withState data: Data? = nil) -> WindowStateManager {
        if let data = data {
            let stateFilePath = tempStateDirectory.appendingPathComponent("state.json").path
            mockFileSystem.setFile(at: stateFilePath, content: data)
        }
        return WindowStateManager(
            fileSystem: mockFileSystem,
            stateDirectory: tempStateDirectory
        )
    }

    // MARK: - Registration Tests

    func testRegisterWindowReturnsConfig() {
        let manager = makeManager()

        let config = manager.registerWindow()

        XCTAssertNotNil(config.id)
        XCTAssertEqual(config.gridColumns, 2)
        XCTAssertEqual(config.gridRows, 1)
    }

    func testRegisterWindowWithCustomConfig() {
        let manager = makeManager()
        let customConfig = WindowConfig(gridConfig: GridConfig(columns: 3, rows: 2))

        let config = manager.registerWindow(config: customConfig)

        XCTAssertEqual(config.id, customConfig.id)
        XCTAssertEqual(config.gridColumns, 3)
        XCTAssertEqual(config.gridRows, 2)
    }

    func testRegisterMultipleWindows() {
        let manager = makeManager()

        let config1 = manager.registerWindow()
        let config2 = manager.registerWindow()

        XCTAssertNotEqual(config1.id, config2.id)
        XCTAssertEqual(manager.windowConfigs.count, 2)
    }

    func testUnregisterWindow() {
        let manager = makeManager()
        let config = manager.registerWindow()

        XCTAssertEqual(manager.windowConfigs.count, 1)

        manager.unregisterWindow(id: config.id)

        XCTAssertEqual(manager.windowConfigs.count, 0)
    }

    func testUnregisterNonexistentWindow() {
        let manager = makeManager()
        let config = manager.registerWindow()

        manager.unregisterWindow(id: UUID()) // Different UUID

        XCTAssertEqual(manager.windowConfigs.count, 1)
        XCTAssertNotNil(manager.config(for: config.id))
    }

    // MARK: - Config Retrieval Tests

    func testConfigForId() {
        let manager = makeManager()
        let registered = manager.registerWindow(
            config: WindowConfig(gridConfig: GridConfig(columns: 4, rows: 2))
        )

        let retrieved = manager.config(for: registered.id)

        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.gridColumns, 4)
        XCTAssertEqual(retrieved?.gridRows, 2)
    }

    func testConfigForNonexistentId() {
        let manager = makeManager()
        _ = manager.registerWindow()

        let config = manager.config(for: UUID())

        XCTAssertNil(config)
    }

    // MARK: - State Loading Tests (v2 Format)

    func testLoadStateV2() {
        let testConfig = WindowConfig(
            gridConfig: GridConfig(columns: 3, rows: 2),
            paneAttachments: ["1": "test-session"]
        )
        let stateData = MockFileSystem.makeV2StateJSON(configs: [testConfig])
        let manager = makeManager(withState: stateData)

        XCTAssertTrue(manager.hasRestoredState)
        XCTAssertEqual(manager.pendingRestoreConfigs.count, 1)
        XCTAssertEqual(manager.pendingRestoreConfigs[0].gridColumns, 3)
        XCTAssertEqual(manager.pendingRestoreConfigs[0].gridRows, 2)
        XCTAssertEqual(manager.pendingRestoreConfigs[0].paneAttachments["1"], "test-session")
    }

    func testLoadStateV2MultipleWindows() {
        let config1 = WindowConfig(gridConfig: GridConfig(columns: 2, rows: 1))
        let config2 = WindowConfig(gridConfig: GridConfig(columns: 3, rows: 3))
        let stateData = MockFileSystem.makeV2StateJSON(configs: [config1, config2])
        let manager = makeManager(withState: stateData)

        XCTAssertTrue(manager.hasRestoredState)
        XCTAssertEqual(manager.pendingRestoreConfigs.count, 2)
    }

    func testLoadStateV2Empty() {
        let stateData = MockFileSystem.makeV2StateJSON(configs: [])
        let manager = makeManager(withState: stateData)

        XCTAssertFalse(manager.hasRestoredState)
        XCTAssertTrue(manager.pendingRestoreConfigs.isEmpty)
    }

    // MARK: - State Loading Tests (v1 Migration)

    func testLoadStateV1Migration() {
        let stateData = MockFileSystem.makeV1StateJSON(
            gridColumns: 4,
            gridRows: 2,
            paneAttachments: ["1": "old-session"]
        )
        let manager = makeManager(withState: stateData)

        XCTAssertTrue(manager.hasRestoredState)
        XCTAssertEqual(manager.pendingRestoreConfigs.count, 1)
        XCTAssertEqual(manager.pendingRestoreConfigs[0].gridColumns, 4)
        XCTAssertEqual(manager.pendingRestoreConfigs[0].gridRows, 2)
        XCTAssertEqual(manager.pendingRestoreConfigs[0].paneAttachments["1"], "old-session")
    }

    // MARK: - State Loading Tests (Error Cases)

    func testLoadStateNoFile() {
        let manager = makeManager() // No state file set

        XCTAssertFalse(manager.hasRestoredState)
        XCTAssertTrue(manager.pendingRestoreConfigs.isEmpty)
    }

    func testLoadStateCorruptedJSON() {
        let corruptedData = "this is not valid json".data(using: .utf8)!
        let manager = makeManager(withState: corruptedData)

        XCTAssertFalse(manager.hasRestoredState)
        XCTAssertTrue(manager.pendingRestoreConfigs.isEmpty)
    }

    func testLoadStateWrongStructure() {
        let wrongData = "{\"foo\": \"bar\"}".data(using: .utf8)!
        let manager = makeManager(withState: wrongData)

        XCTAssertFalse(manager.hasRestoredState)
        XCTAssertTrue(manager.pendingRestoreConfigs.isEmpty)
    }

    // MARK: - State Saving Tests

    func testSaveStateCreatesDirectory() {
        let manager = makeManager()

        _ = manager.registerWindow()

        XCTAssertTrue(mockFileSystem.wasDirectoryCreated(at: tempStateDirectory))
    }

    func testSaveStateWritesFile() {
        let manager = makeManager()

        _ = manager.registerWindow(
            config: WindowConfig(gridConfig: GridConfig(columns: 3, rows: 2))
        )

        let stateFileURL = tempStateDirectory.appendingPathComponent("state.json")
        let savedData = mockFileSystem.getFile(at: stateFileURL)
        XCTAssertNotNil(savedData)

        // Verify saved data is valid JSON
        if let data = savedData {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let state = try? decoder.decode(MultiWindowState.self, from: data)
            XCTAssertNotNil(state)
            XCTAssertEqual(state?.windows.count, 1)
            XCTAssertEqual(state?.windows[0].gridColumns, 3)
            XCTAssertEqual(state?.windows[0].gridRows, 2)
        }
    }

    func testSaveStateUpdatesOnWindowChange() {
        let manager = makeManager()
        let config1 = manager.registerWindow()
        _ = manager.registerWindow()

        manager.unregisterWindow(id: config1.id)

        let stateFileURL = tempStateDirectory.appendingPathComponent("state.json")
        let savedData = mockFileSystem.getFile(at: stateFileURL)
        if let data = savedData {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let state = try? decoder.decode(MultiWindowState.self, from: data)
            XCTAssertEqual(state?.windows.count, 1) // Only one window remains
        }
    }

    // MARK: - Clear State Tests

    func testClearState() {
        let stateData = MockFileSystem.makeV2StateJSON(configs: [WindowConfig()])
        let manager = makeManager(withState: stateData)

        _ = manager.registerWindow()
        _ = manager.registerWindow()
        XCTAssertEqual(manager.windowConfigs.count, 2)

        manager.clearState()

        XCTAssertEqual(manager.windowConfigs.count, 0)
        XCTAssertFalse(manager.hasRestoredState)
        XCTAssertTrue(manager.pendingRestoreConfigs.isEmpty)

        let stateFileURL = tempStateDirectory.appendingPathComponent("state.json")
        XCTAssertTrue(mockFileSystem.wasRemoved(at: stateFileURL))
    }

    func testClearStateNoFile() {
        let manager = makeManager() // No state file

        // Should not throw
        manager.clearState()

        XCTAssertEqual(manager.windowConfigs.count, 0)
        XCTAssertFalse(manager.hasRestoredState)
    }

    // MARK: - Pending Configs Tests

    func testPopNextPendingConfigReturnsNilWhenEmpty() {
        let manager = makeManager()

        let config = manager.popNextPendingConfig()

        XCTAssertNil(config)
    }

    func testPopNextPendingConfigReturnsFIFO() {
        let config1 = WindowConfig(gridConfig: GridConfig(columns: 1, rows: 1))
        let config2 = WindowConfig(gridConfig: GridConfig(columns: 2, rows: 2))
        let stateData = MockFileSystem.makeV2StateJSON(configs: [config1, config2])
        let manager = makeManager(withState: stateData)

        XCTAssertEqual(manager.pendingRestoreConfigs.count, 2)

        let popped1 = manager.popNextPendingConfig()
        XCTAssertEqual(popped1?.gridColumns, 1)
        XCTAssertEqual(manager.pendingRestoreConfigs.count, 1)

        let popped2 = manager.popNextPendingConfig()
        XCTAssertEqual(popped2?.gridColumns, 2)
        XCTAssertEqual(manager.pendingRestoreConfigs.count, 0)

        let popped3 = manager.popNextPendingConfig()
        XCTAssertNil(popped3)
    }

    func testHasPendingConfigs() {
        let stateData = MockFileSystem.makeV2StateJSON(configs: [WindowConfig()])
        let manager = makeManager(withState: stateData)

        XCTAssertTrue(manager.hasPendingConfigs)

        manager.clearPendingRestore()

        XCTAssertFalse(manager.hasPendingConfigs)
    }

    func testConfigsToRestore() {
        let config = WindowConfig(gridConfig: GridConfig(columns: 5, rows: 5))
        let stateData = MockFileSystem.makeV2StateJSON(configs: [config])
        let manager = makeManager(withState: stateData)

        let configs = manager.configsToRestore()

        XCTAssertEqual(configs.count, 1)
        XCTAssertEqual(configs[0].gridColumns, 5)
    }

    func testClearPendingRestore() {
        let stateData = MockFileSystem.makeV2StateJSON(configs: [WindowConfig(), WindowConfig()])
        let manager = makeManager(withState: stateData)

        XCTAssertEqual(manager.pendingRestoreConfigs.count, 2)

        manager.clearPendingRestore()

        XCTAssertTrue(manager.pendingRestoreConfigs.isEmpty)
        XCTAssertFalse(manager.hasPendingConfigs)
    }

    // MARK: - Window Update Tests

    func testUpdateWindowFrame() {
        let manager = makeManager()
        let config = manager.registerWindow()
        let frame = WindowFrame(x: 100, y: 200, width: 800, height: 600)

        manager.updateWindowFrame(id: config.id, frame: frame)

        let updated = manager.config(for: config.id)
        XCTAssertEqual(updated?.frame, frame)
    }

    func testUpdateWindowFrameNonexistent() {
        let manager = makeManager()
        _ = manager.registerWindow()
        let frame = WindowFrame(x: 100, y: 200, width: 800, height: 600)

        // Should not throw
        manager.updateWindowFrame(id: UUID(), frame: frame)
    }
}
