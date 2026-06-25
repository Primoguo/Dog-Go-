import XCTest
@testable import CozeDog

final class DataEncodingTests: XCTestCase {

    // MARK: - AppState 编解码测试

    func testAppStateEncoding() {
        var state = AppState.initial
        state.selectedDog = .shiba
        state.dogCollected = true
        state.totalMainCheckIns = 5

        do {
            let data = try JSONEncoder().encode(state)
            XCTAssertGreaterThan(data.count, 0)

            let decoded = try JSONDecoder().decode(AppState.self, from: data)
            XCTAssertEqual(decoded.selectedDog, .shiba)
            XCTAssertEqual(decoded.dogCollected, true)
            XCTAssertEqual(decoded.totalMainCheckIns, 5)
        } catch {
            XCTFail("编解码失败: \(error)")
        }
    }

    func testAppStateWithFocusSessions() {
        var state = AppState.initial
        state.totalFocusSessions = 3
        state.totalFocusTime = 3600

        do {
            let data = try JSONEncoder().encode(state)
            let decoded = try JSONDecoder().decode(AppState.self, from: data)

            XCTAssertEqual(decoded.totalFocusSessions, 3)
            XCTAssertEqual(decoded.totalFocusTime, 3600)
        } catch {
            XCTFail("编解码失败: \(error)")
        }
    }

    func testAppStateWithCollectedDogs() {
        var state = AppState.initial
        state.collectedDogs = [.shiba, .golden, .borderCollie]

        do {
            let data = try JSONEncoder().encode(state)
            let decoded = try JSONDecoder().decode(AppState.self, from: data)

            XCTAssertEqual(decoded.collectedDogs.count, 3)
            XCTAssertTrue(decoded.collectedDogs.contains(.shiba))
            XCTAssertTrue(decoded.collectedDogs.contains(.golden))
            XCTAssertTrue(decoded.collectedDogs.contains(.borderCollie))
        } catch {
            XCTFail("编解码失败: \(error)")
        }
    }

    // MARK: - 向后兼容性测试

    func testDecodeOldAppStateWithoutNewFields() {
        // 模拟旧版本数据（缺少新增字段）
        let oldJson = """
        {
            "screen": "home",
            "selectedDog": "shiba",
            "dogCollected": true,
            "goal": null
        }
        """

        do {
            let data = oldJson.data(using: .utf8)!
            let decoded = try JSONDecoder().decode(AppState.self, from: data)

            // 新增字段应该有默认值
            XCTAssertEqual(decoded.selectedDog, .shiba)
            XCTAssertEqual(decoded.dogCollected, true)
            XCTAssertEqual(decoded.totalMainCheckIns, 0) // 默认值
            XCTAssertEqual(decoded.availableAdoptions, 0) // 默认值
        } catch {
            XCTFail("向后兼容解码失败: \(error)")
        }
    }

    func testDecodeOldAppStateWithoutFocusFields() {
        // 模拟专注模式添加前的数据
        let oldJson = """
        {
            "screen": "home",
            "selectedDog": "golden",
            "dogCollected": true
        }
        """

        do {
            let data = oldJson.data(using: .utf8)!
            let decoded = try JSONDecoder().decode(AppState.self, from: data)

            // 专注模式字段应该有默认值
            XCTAssertEqual(decoded.totalFocusSessions, 0)
            XCTAssertEqual(decoded.totalFocusTime, 0)
            XCTAssertFalse(decoded.isFocusModeActive)
        } catch {
            XCTFail("向后兼容解码失败: \(error)")
        }
    }

    // MARK: - Dog 编解码测试

    func testDogEncoding() {
        let dog = Dog.breed(.shiba).name("小白").build()

        do {
            let data = try JSONEncoder().encode(dog)
            let decoded = try JSONDecoder().decode(Dog.self, from: data)

            XCTAssertEqual(decoded.breed, .shiba)
            XCTAssertEqual(decoded.name, "小白")
        } catch {
            XCTFail("Dog 编解码失败: \(error)")
        }
    }

    // MARK: - DogAppearance 编解码测试

    func testDogAppearanceEncoding() {
        let appearance = DogAppearance(
            bodyColor: .orange,
            earColor: .brown,
            eyeColor: .black,
            noseColor: .black,
            tongueColor: .pink
        )

        do {
            let data = try JSONEncoder().encode(appearance)
            let decoded = try JSONDecoder().decode(DogAppearance.self, from: data)

            XCTAssertEqual(decoded.bodyColor, .orange)
            XCTAssertEqual(decoded.earColor, .brown)
        } catch {
            XCTFail("DogAppearance 编解码失败: \(error)")
        }
    }

    // MARK: - Goal 编解码测试

    func testGoalEncoding() {
        let goal = Goal(
            type: .fitness,
            title: "每天跑步",
            frequency: .daily,
            createdAt: Date()
        )

        do {
            let data = try JSONEncoder().encode(goal)
            let decoded = try JSONDecoder().decode(Goal.self, from: data)

            XCTAssertEqual(decoded.type, .fitness)
            XCTAssertEqual(decoded.title, "每天跑步")
            XCTAssertEqual(decoded.frequency, .daily)
        } catch {
            XCTFail("Goal 编解码失败: \(error)")
        }
    }

    // MARK: - FocusSession 编解码测试

    func testFocusSessionEncoding() {
        let session = FocusSession(
            id: UUID(),
            duration: 1500,
            completedAt: Date(),
            planTitle: "学习 Swift"
        )

        do {
            let data = try JSONEncoder().encode(session)
            let decoded = try JSONDecoder().decode(FocusSession.self, from: data)

            XCTAssertEqual(decoded.duration, 1500)
            XCTAssertEqual(decoded.planTitle, "学习 Swift")
        } catch {
            XCTFail("FocusSession 编解码失败: \(error)")
        }
    }

    // MARK: - 边界情况测试

    func testEmptyStringEncoding() {
        var state = AppState.initial
        state.completedPlanTitle = ""

        do {
            let data = try JSONEncoder().encode(state)
            let decoded = try JSONDecoder().decode(AppState.self, from: data)

            XCTAssertEqual(decoded.completedPlanTitle, "")
        } catch {
            XCTFail("空字符串编解码失败: \(error)")
        }
    }

    func testLargeDataEncoding() {
        var state = AppState.initial
        // 添加大量专注记录
        for i in 0..<100 {
            let session = FocusSession(
                id: UUID(),
                duration: 1500,
                completedAt: Date(),
                planTitle: "测试计划 \(i)"
            )
            state.focusHistory.append(session)
        }

        do {
            let data = try JSONEncoder().encode(state)
            let decoded = try JSONDecoder().decode(AppState.self, from: data)

            XCTAssertEqual(decoded.focusHistory.count, 100)
        } catch {
            XCTFail("大数据编解码失败: \(error)")
        }
    }
}
