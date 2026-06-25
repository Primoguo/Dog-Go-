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
        XCTAssertEqual(store.state.totalMainCheckIns, 0)
        XCTAssertEqual(store.state.dogCollection.totalCollected, 0)
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

        store.completeMainGoal()

        XCTAssertEqual(store.state.totalMainCheckIns, initialCheckIns + 1)
    }

    func testCompleteMultipleTimes() {
        store.selectDog(.shiba)

        store.completeMainGoal()
        store.completeMainGoal()
        store.completeMainGoal()

        XCTAssertEqual(store.state.totalMainCheckIns, 3)
    }

    // MARK: - 狗狗收集测试

    func testCollectDog() {
        store.selectDog(.shiba)
        let appearance = DogAppearance.generated(for: .shiba)
        store.collectDog(breed: .shiba, appearance: appearance)

        XCTAssertEqual(store.state.dogCollection.totalCollected, 1)
        XCTAssertTrue(store.state.dogCollection.hasCollected(.shiba))
    }

    func testCollectMultipleDogs() {
        let shibaAppearance = DogAppearance.generated(for: .shiba)
        let goldenAppearance = DogAppearance.generated(for: .golden)
        store.collectDog(breed: .shiba, appearance: shibaAppearance)
        store.collectDog(breed: .golden, appearance: goldenAppearance)

        XCTAssertTrue(store.state.dogCollection.collectedBreeds.contains(.shiba))
        XCTAssertTrue(store.state.dogCollection.collectedBreeds.contains(.golden))
        XCTAssertEqual(store.state.dogCollection.totalCollected, 2)
    }

    // MARK: - 陪伴系统测试

    func testSetCompanion() {
        let shibaAppearance = DogAppearance.generated(for: .shiba)
        let goldenAppearance = DogAppearance.generated(for: .golden)
        store.collectDog(breed: .shiba, appearance: shibaAppearance)
        store.collectDog(breed: .golden, appearance: goldenAppearance)

        // 获取金毛的 UUID
        let goldenDog = store.state.dogCollection.dogs.first { $0.breed == .golden }
        XCTAssertNotNil(goldenDog)

        store.setCompanion(id: goldenDog!.id)

        XCTAssertEqual(store.state.activeCompanionId, goldenDog!.id)
    }

    func testSetCompanionNotCollected() {
        let shibaAppearance = DogAppearance.generated(for: .shiba)
        store.collectDog(breed: .shiba, appearance: shibaAppearance)

        // 尝试设置一个不存在的 UUID 为陪伴
        let fakeUUID = UUID()
        store.setCompanion(id: fakeUUID)

        // 应该不匹配任何收集的狗狗
        XCTAssertNotEqual(store.state.activeCompanionId, fakeUUID)
    }

    // MARK: - 领养机制测试

    func testAdoptionTrigger() {
        store.selectDog(.shiba)

        // 完成 10 次应该触发领养机会
        for _ in 0..<10 {
            store.completeMainGoal()
        }

        XCTAssertGreaterThan(store.state.availableAdoptions, 0)
    }

    // MARK: - 专注模式测试

    func testStartFocusMode() {
        store.startFocusMode(plan: .study, durationSeconds: 1500) // 25 分钟

        XCTAssertTrue(store.state.isFocusMode)
        XCTAssertEqual(store.state.actionSession.durationSeconds, 1500)
        XCTAssertNotNil(store.state.focusStartTime)
    }

    func testCompleteFocusSession() {
        store.startFocusMode(plan: .study, durationSeconds: 60) // 1 分钟测试

        // 模拟时间流逝
        store.state.focusStartTime = Date().addingTimeInterval(-60)

        store.completeFocusSession()

        XCTAssertFalse(store.state.isFocusMode)
        XCTAssertEqual(store.state.focusSessionsCount, 1)
        XCTAssertGreaterThan(store.state.totalFocusMinutes, 0)
    }

    func testAbandonFocusSession() {
        store.startFocusMode(plan: .study, durationSeconds: 1500)

        // 模拟 2 分钟后放弃
        store.state.focusStartTime = Date().addingTimeInterval(-120)

        store.abandonFocusSession()

        XCTAssertFalse(store.state.isFocusMode)
        // 超过 1 分钟的专注应该被记录
        XCTAssertEqual(store.state.focusSessionsCount, 1)
    }

    func testAbandonFocusSessionTooShort() {
        store.startFocusMode(plan: .study, durationSeconds: 1500)

        // 模拟 30 秒后放弃（不足 1 分钟）
        store.state.focusStartTime = Date().addingTimeInterval(-30)

        store.abandonFocusSession()

        XCTAssertFalse(store.state.isFocusMode)
        // 不足 1 分钟不应该被记录
        XCTAssertEqual(store.state.focusSessionsCount, 0)
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
