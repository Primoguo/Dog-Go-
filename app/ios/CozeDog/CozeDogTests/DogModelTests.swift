import XCTest
@testable import CozeDog

final class DogModelTests: XCTestCase {

    // MARK: - DogState 基础测试

    func testDogStateInitialization() {
        let appearance = DogAppearance.generated(for: .shiba)
        let state = DogState(breed: .shiba, name: "旺财", appearance: appearance)

        XCTAssertEqual(state.breed, .shiba)
        XCTAssertEqual(state.name, "旺财")
        XCTAssertEqual(state.level, 1)
        XCTAssertEqual(state.mood, .neutral)
    }

    func testDogStateAllBreeds() {
        let breeds: [DogBreed] = [.shiba, .golden, .borderCollie, .native, .bulldog, .teddy]

        for breed in breeds {
            let appearance = DogAppearance.generated(for: breed)
            let state = DogState(breed: breed, name: "测试", appearance: appearance)
            XCTAssertEqual(state.breed, breed)
        }
    }

    func testDogStateDefaultValues() {
        let appearance = DogAppearance.generated(for: .golden)
        let state = DogState(breed: .golden, name: "大金", appearance: appearance)

        XCTAssertEqual(state.intimacy, 50)
        XCTAssertEqual(state.fullness, 80)
        XCTAssertEqual(state.cleanliness, 80)
        XCTAssertEqual(state.energy, 80)
        XCTAssertEqual(state.level, 1)
    }

    // MARK: - DogAppearance 生成测试

    func testDogAppearanceGeneration() {
        let appearance = DogAppearance.generated(for: .shiba)

        // 外观属性应该是有效的 UInt 值
        XCTAssertGreaterThan(appearance.primaryFurHex, 0)
        XCTAssertGreaterThan(appearance.bodyColorHex, 0)
        XCTAssertGreaterThan(appearance.earColorHex, 0)
    }

    func testDogAppearanceConsistency() {
        // 同一个 seed 应该生成相同外观
        let appearance1 = DogAppearance.generated(for: .shiba, seed: "test-seed-123")
        let appearance2 = DogAppearance.generated(for: .shiba, seed: "test-seed-123")

        XCTAssertEqual(appearance1.primaryFurHex, appearance2.primaryFurHex)
        XCTAssertEqual(appearance1.bodyColorHex, appearance2.bodyColorHex)
        XCTAssertEqual(appearance1.earColorHex, appearance2.earColorHex)
    }

    func testDogAppearanceDifferentSeeds() {
        // 不同 seed 应该生成不同外观（大概率）
        let appearance1 = DogAppearance.generated(for: .shiba, seed: "seed-aaa")
        let appearance2 = DogAppearance.generated(for: .shiba, seed: "seed-bbb")

        // 至少有一个颜色属性不同
        let different = appearance1.primaryFurHex != appearance2.primaryFurHex ||
                       appearance1.bodyColorHex != appearance2.bodyColorHex ||
                       appearance1.earColorHex != appearance2.earColorHex

        XCTAssertTrue(different, "不同 seed 应该生成不同外观")
    }

    // MARK: - DogPose 测试

    func testDogPoseCases() {
        // 确保所有姿态都存在
        let allPoses: [DogPose] = DogPose.allCases
        XCTAssertGreaterThan(allPoses.count, 0)
        XCTAssertTrue(allPoses.contains(.idle))
        XCTAssertTrue(allPoses.contains(.happy))
        XCTAssertTrue(allPoses.contains(.focused))
    }

    func testDogPoseCelebration() {
        // 庆祝姿态应该有特定标记
        let celebrationPoses = DogPose.allCases.filter { $0.isCelebration }
        XCTAssertGreaterThan(celebrationPoses.count, 0)
    }

    // MARK: - DogMood 测试

    func testDogMoodCases() {
        let allMoods: [DogMood] = DogMood.allCases
        XCTAssertGreaterThan(allMoods.count, 0)
        XCTAssertTrue(allMoods.contains(.neutral))
        XCTAssertTrue(allMoods.contains(.happy))
        XCTAssertTrue(allMoods.contains(.sad))
    }

    // MARK: - DogBreed 测试

    func testDogBreedAllCases() {
        let breeds = DogBreed.allCases
        XCTAssertEqual(breeds.count, 6)
        XCTAssertTrue(breeds.contains(.shiba))
        XCTAssertTrue(breeds.contains(.golden))
        XCTAssertTrue(breeds.contains(.borderCollie))
        XCTAssertTrue(breeds.contains(.native))
        XCTAssertTrue(breeds.contains(.bulldog))
        XCTAssertTrue(breeds.contains(.teddy))
    }

    // MARK: - 鼓励文案测试

    func testEncouragementCopies() {
        let store = AppStore()
        store.selectDog(.shiba)

        // 不同进度应该有不同鼓励语
        let copy25 = store.encouragementCopy(progress: 0.25)
        let copy50 = store.encouragementCopy(progress: 0.50)
        let copy75 = store.encouragementCopy(progress: 0.75)

        XCTAssertFalse(copy25.isEmpty)
        XCTAssertFalse(copy50.isEmpty)
        XCTAssertFalse(copy75.isEmpty)
    }
}
