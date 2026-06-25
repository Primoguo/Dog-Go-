import XCTest
@testable import CozeDog

final class DataEncodingTests: XCTestCase {

    // MARK: - AppState 编解码测试

    func testAppStateEncoding() {
        var state = AppState.initial
        state.selectedDog = .shiba
        state.totalMainCheckIns = 5

        do {
            let data = try JSONEncoder().encode(state)
            XCTAssertGreaterThan(data.count, 0)

            let decoded = try JSONDecoder().decode(AppState.self, from: data)
            XCTAssertEqual(decoded.selectedDog, .shiba)
            XCTAssertEqual(decoded.totalMainCheckIns, 5)
        } catch {
            XCTFail("编解码失败: \(error)")
        }
    }

    func testAppStateWithFocusSessions() {
        var state = AppState.initial
        state.focusSessionsCount = 3
        state.totalFocusMinutes = 60

        do {
            let data = try JSONEncoder().encode(state)
            let decoded = try JSONDecoder().decode(AppState.self, from: data)

            XCTAssertEqual(decoded.focusSessionsCount, 3)
            XCTAssertEqual(decoded.totalFocusMinutes, 60)
        } catch {
            XCTFail("编解码失败: \(error)")
        }
    }

    func testAppStateWithCollectedDogs() {
        var state = AppState.initial
        let shibaDog = CollectedDog(
            breed: .shiba,
            appearance: DogAppearance.generated(for: .shiba),
            nickname: "小白",
            collectedAt: Date()
        )
        let goldenDog = CollectedDog(
            breed: .golden,
            appearance: DogAppearance.generated(for: .golden),
            nickname: "大金",
            collectedAt: Date()
        )
        let borderDog = CollectedDog(
            breed: .borderCollie,
            appearance: DogAppearance.generated(for: .borderCollie),
            nickname: "边边",
            collectedAt: Date()
        )
        state.dogCollection = DogCollection(dogs: [shibaDog, goldenDog, borderDog])

        do {
            let data = try JSONEncoder().encode(state)
            let decoded = try JSONDecoder().decode(AppState.self, from: data)

            XCTAssertEqual(decoded.dogCollection.totalCollected, 3)
            XCTAssertTrue(decoded.dogCollection.collectedBreeds.contains(.shiba))
            XCTAssertTrue(decoded.dogCollection.collectedBreeds.contains(.golden))
            XCTAssertTrue(decoded.dogCollection.collectedBreeds.contains(.borderCollie))
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
            "totalMainCheckIns": 0,
            "availableAdoptions": 0
        }
        """

        do {
            let data = oldJson.data(using: .utf8)!
            let decoded = try JSONDecoder().decode(AppState.self, from: data)

            XCTAssertEqual(decoded.selectedDog, .shiba)
            XCTAssertEqual(decoded.totalMainCheckIns, 0)
            XCTAssertEqual(decoded.availableAdoptions, 0)
        } catch {
            XCTFail("向后兼容解码失败: \(error)")
        }
    }

    func testDecodeOldAppStateWithoutFocusFields() {
        // 模拟专注模式添加前的数据
        let oldJson = """
        {
            "screen": "home",
            "selectedDog": "golden"
        }
        """

        do {
            let data = oldJson.data(using: .utf8)!
            let decoded = try JSONDecoder().decode(AppState.self, from: data)

            // 专注模式字段应该有默认值
            XCTAssertEqual(decoded.focusSessionsCount, 0)
            XCTAssertEqual(decoded.totalFocusMinutes, 0)
            XCTAssertFalse(decoded.isFocusMode)
        } catch {
            XCTFail("向后兼容解码失败: \(error)")
        }
    }

    // MARK: - CollectedDog 编解码测试

    func testCollectedDogEncoding() {
        let appearance = DogAppearance.generated(for: .shiba, seed: "test-seed")
        let dog = CollectedDog(
            breed: .shiba,
            appearance: appearance,
            nickname: "小白",
            collectedAt: Date()
        )

        do {
            let data = try JSONEncoder().encode(dog)
            let decoded = try JSONDecoder().decode(CollectedDog.self, from: data)

            XCTAssertEqual(decoded.breed, .shiba)
            XCTAssertEqual(decoded.nickname, "小白")
            XCTAssertEqual(decoded.appearance.seed, appearance.seed)
        } catch {
            XCTFail("CollectedDog 编解码失败: \(error)")
        }
    }

    // MARK: - DogAppearance 编解码测试

    func testDogAppearanceEncoding() {
        let appearance = DogAppearance.generated(for: .shiba, seed: "test-seed")

        do {
            let data = try JSONEncoder().encode(appearance)
            let decoded = try JSONDecoder().decode(DogAppearance.self, from: data)

            XCTAssertEqual(decoded.seed, appearance.seed)
            XCTAssertEqual(decoded.primaryFurHex, appearance.primaryFurHex)
            XCTAssertEqual(decoded.bodyColorHex, appearance.bodyColorHex)
        } catch {
            XCTFail("DogAppearance 编解码失败: \(error)")
        }
    }

    // MARK: - Goal 编解码测试

    func testGoalEncoding() {
        let goal = Goal(
            id: UUID(),
            type: .fitness,
            title: "每天跑步",
            createdAt: Date(),
            updatedAt: Date()
        )

        do {
            let data = try JSONEncoder().encode(goal)
            let decoded = try JSONDecoder().decode(Goal.self, from: data)

            XCTAssertEqual(decoded.type, .fitness)
            XCTAssertEqual(decoded.title, "每天跑步")
        } catch {
            XCTFail("Goal 编解码失败: \(error)")
        }
    }

    // MARK: - FocusSession 编解码测试

    func testFocusSessionEncoding() {
        let session = FocusSession(
            id: UUID(),
            plan: .study,
            durationSeconds: 1500,
            startedAt: Date(),
            completedAt: Date(),
            completed: true
        )

        do {
            let data = try JSONEncoder().encode(session)
            let decoded = try JSONDecoder().decode(FocusSession.self, from: data)

            XCTAssertEqual(decoded.durationSeconds, 1500)
            XCTAssertEqual(decoded.plan, .study)
            XCTAssertTrue(decoded.completed)
        } catch {
            XCTFail("FocusSession 编解码失败: \(error)")
        }
    }

    // MARK: - 边界情况测试

    func testLargeDataEncoding() {
        var state = AppState.initial
        // 添加大量专注记录
        for i in 0..<100 {
            let session = FocusSession(
                id: UUID(),
                plan: .study,
                durationSeconds: 1500,
                startedAt: Date(),
                completedAt: Date(),
                completed: true
            )
            state.focusSessions.append(session)
        }

        do {
            let data = try JSONEncoder().encode(state)
            let decoded = try JSONDecoder().decode(AppState.self, from: data)

            XCTAssertEqual(decoded.focusSessions.count, 100)
        } catch {
            XCTFail("大数据编解码失败: \(error)")
        }
    }
}
