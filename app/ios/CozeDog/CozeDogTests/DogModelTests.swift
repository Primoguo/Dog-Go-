import XCTest
@testable import CozeDog

final class DogModelTests: XCTestCase {

    // MARK: - Dog 构建测试

    func testBuildShiba() {
        let dog = Dog.breed(.shiba).build()

        XCTAssertEqual(dog.breed, .shiba)
        XCTAssertFalse(dog.name.isEmpty)
    }

    func testBuildAllBreeds() {
        let breeds: [DogBreed] = [.shiba, .golden, .borderCollie, .native, .bulldog, .teddy]

        for breed in breeds {
            let dog = Dog.breed(breed).build()
            XCTAssertEqual(dog.breed, breed)
        }
    }

    func testDogWithCustomName() {
        let dog = Dog.breed(.shiba).name("旺财").build()

        XCTAssertEqual(dog.name, "旺财")
        XCTAssertEqual(dog.breed, .shiba)
    }

    // MARK: - 狗狗外观测试

    func testDogAppearanceGeneration() {
        let appearance = DogAppearance.generated(for: .shiba)

        // 外观应该有所有必要的颜色
        XCTAssertNotNil(appearance.bodyColor)
        XCTAssertNotNil(appearance.earColor)
        XCTAssertNotNil(appearance.eyeColor)
    }

    func testDogAppearanceConsistency() {
        // 同一种狗狗、同一个 seed 应该生成相同外观
        let appearance1 = DogAppearance.generated(for: .shiba, seed: 12345)
        let appearance2 = DogAppearance.generated(for: .shiba, seed: 12345)

        XCTAssertEqual(appearance1.bodyColor, appearance2.bodyColor)
        XCTAssertEqual(appearance1.earColor, appearance2.earColor)
        XCTAssertEqual(appearance1.eyeColor, appearance2.eyeColor)
    }

    func testDogAppearanceDifferentSeeds() {
        // 不同 seed 应该生成不同外观（大概率）
        let appearance1 = DogAppearance.generated(for: .shiba, seed: 111)
        let appearance2 = DogAppearance.generated(for: .shiba, seed: 222)

        // 至少有一个颜色不同
        let different = appearance1.bodyColor != appearance2.bodyColor ||
                       appearance1.earColor != appearance2.earColor ||
                       appearance1.eyeColor != appearance2.eyeColor

        XCTAssertTrue(different, "不同 seed 应该生成不同外观")
    }

    // MARK: - 狗狗状态测试

    func testDogStatusInitialization() {
        let status = DogStatus()

        XCTAssertEqual(status.affection, 50)
        XCTAssertEqual(status.hunger, 50)
        XCTAssertEqual(status.cleanliness, 50)
        XCTAssertEqual(status.energy, 50)
        XCTAssertEqual(status.mood, 50)
    }

    func testDogStatusLevelUp() {
        var status = DogStatus()
        status.level = 1
        status.experience = 90

        // 升级应该重置经验值
        status.experience += 20
        if status.experience >= 100 {
            status.level += 1
            status.experience -= 100
        }

        XCTAssertEqual(status.level, 2)
        XCTAssertEqual(status.experience, 10)
    }

    // MARK: - 品种特性测试

    func testBreedProperties() {
        let shiba = Dog.breed(.shiba).build()

        // 柴犬应该有特定的性格描述
        XCTAssertFalse(shiba.personality.isEmpty)
    }

    func testCelebrationPoses() {
        let dog = Dog.breed(.shiba).build()

        // 每个品种都应该有庆祝姿势
        let pose = dog.celebrationPose()
        XCTAssertNotNil(pose)
    }

    func testEncouragementCopies() {
        let dog = Dog.breed(.shiba).build()

        // 不同进度应该有不同鼓励语
        let copy25 = dog.encouragementCopy(progress: 0.25)
        let copy50 = dog.encouragementCopy(progress: 0.50)
        let copy75 = dog.encouragementCopy(progress: 0.75)

        XCTAssertFalse(copy25.isEmpty)
        XCTAssertFalse(copy50.isEmpty)
        XCTAssertFalse(copy75.isEmpty)
    }
}
