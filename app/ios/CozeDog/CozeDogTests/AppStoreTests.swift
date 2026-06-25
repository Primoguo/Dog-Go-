import XCTest
@testable import CozeDog

final class AppStoreTests: XCTestCase {

    var store: AppStore!

    override func setUp() {
        super.setUp()
        store = AppStore()
    }

    override func tearDown() {
        store = nil
        super.tearDown()
    }

    // MARK: - 初始化测试

    func testInitialState() {
        // 初始状态应该是领养界面
        XCTAssertEqual(store.state.screen, .adopt)
        XCTAssertFalse(store.state.dogCollected)
        XCTAssertEqual(store.state.totalMainCheckIns, 0)
    }

    // MARK: - 选择狗狗测试

    func testSelectDog() {
        store.selectDog(.shiba)

        XCTAssertEqual(store.state.selectedDog, .shiba)
        XCTAssertNotNil(store.state.dogAppearance)
    }

    func testSelectDifferentDogs() {
        let breeds: [DogBreed] = [.shiba, .golden, .borderCollie, .native, .bulldog, .teddy]

        for breed in breeds {
            store.selectDog(breed)
            XCTAssertEqual(store.state.selectedDog, breed)
        }
    }

    // MARK: - 完成计划测试

    func testCompleteMainCheckIn() {
        store.selectDog(.shiba)
        let initialCheckIns = store.state.totalMainCheckIns

        store.complete()

        XCTAssertEqual(store.state.totalMainCheckIns, initialCheckIns + 1)
        XCTAssertNotNil(store.state.completedPlanTitle)
    }

    func testCompleteMultipleTimes() {
        store.selectDog(.shiba)

        store.complete()
        store.complete()
        store.complete()

        XCTAssertEqual(store.state.totalMainCheckIns, 3)
    }

    // MARK: - 狗狗收集测试

    func testCollectDog() {
        store.selectDog(.shiba)
        store.collectDog()

        XCTAssertTrue(store.state.dogCollected)
        XCTAssertEqual(store.state.collectedDogs.count, 1)
    }

    func testCollectMultipleDogs() {
        store.collectDog(.shiba)
        store.collectDog(.golden)

        XCTAssertTrue(store.state.collectedDogs.contains(.shiba))
        XCTAssertTrue(store.state.collectedDogs.contains(.golden))
        XCTAssertEqual(store.state.collectedDogs.count, 2)
    }

    // MARK: - 陪伴系统测试

    func testSetCompanion() {
        store.collectDog(.shiba)
        store.collectDog(.golden)

        store.setCompanion(.golden)

        XCTAssertEqual(store.state.activeCompanionId, .golden)
    }

    func testSetCompanionNotCollected() {
        store.collectDog(.shiba)

        // 尝试设置未收集的狗狗为陪伴
        store.setCompanion(.golden)

        // 应该保持原样或清空
        XCTAssertNotEqual(store.state.activeCompanionId, .golden)
    }

    // MARK: - 领养机制测试

    func testAdoptionTrigger() {
        store.selectDog(.shiba)

        // 完成 10 次应该触发领养机会
        for _ in 0..<10 {
            store.complete()
        }

        XCTAssertGreaterThan(store.state.availableAdoptions, 0)
    }

    // MARK: - 专注模式测试

    func testStartFocusMode() {
        store.startFocusMode(duration: 1500) // 25 分钟

        XCTAssertTrue(store.state.isFocusModeActive)
        XCTAssertEqual(store.state.focusDuration, 1500)
        XCTAssertNotNil(store.state.focusStartTime)
    }

    func testCompleteFocusSession() {
        store.startFocusMode(duration: 60) // 1 分钟测试

        // 模拟时间流逝
        store.state.focusStartTime = Date().addingTimeInterval(-60)

        store.completeFocusSession()

        XCTAssertFalse(store.state.isFocusModeActive)
        XCTAssertEqual(store.state.totalFocusSessions, 1)
        XCTAssertGreaterThan(store.state.totalFocusTime, 0)
    }

    func testAbandonFocusSession() {
        store.startFocusMode(duration: 1500)

        // 模拟 2 分钟后放弃
        store.state.focusStartTime = Date().addingTimeInterval(-120)

        store.abandonFocusSession()

        XCTAssertFalse(store.state.isFocusModeActive)
        // 超过 1 分钟的专注应该被记录
        XCTAssertEqual(store.state.totalFocusSessions, 1)
    }

    func testAbandonFocusSessionTooShort() {
        store.startFocusMode(duration: 1500)

        // 模拟 30 秒后放弃（不足 1 分钟）
        store.state.focusStartTime = Date().addingTimeInterval(-30)

        store.abandonFocusSession()

        XCTAssertFalse(store.state.isFocusModeActive)
        // 不足 1 分钟不应该被记录
        XCTAssertEqual(store.state.totalFocusSessions, 0)
    }

    // MARK: - 休息模式测试

    func testStartRest() {
        store.startRest()

        XCTAssertTrue(store.state.isResting)
        XCTAssertNotNil(store.state.restStartTime)
    }

    func testEndRest() {
        store.startRest()
        store.endRest()

        XCTAssertFalse(store.state.isResting)
        XCTAssertNil(store.state.restStartTime)
    }
}
