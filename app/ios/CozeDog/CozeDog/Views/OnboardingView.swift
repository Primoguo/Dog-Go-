import SwiftUI

// MARK: - 首次启动引导视图
struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @EnvironmentObject var store: AppStore
    @State private var currentPage = 0

    var body: some View {
        VStack(spacing: 0) {
            // 页面指示器
            HStack(spacing: 8) {
                ForEach(0..<4) { index in
                    Circle()
                        .fill(index == currentPage ? Color.orange : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .animation(.easeInOut(duration: 0.3), value: currentPage)
                }
            }
            .padding(.top, 60)
            .padding(.bottom, 20)

            // 内容区域
            TabView(selection: $currentPage) {
                onboardingPage1
                    .tag(0)

                onboardingPage2
                    .tag(1)

                onboardingPage3
                    .tag(2)

                onboardingPage4
                    .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.3), value: currentPage)

            // 底部按钮
            HStack {
                if currentPage > 0 {
                    Button("上一步") {
                        withAnimation {
                            currentPage -= 1
                        }
                    }
                    .foregroundColor(.orange)
                    .padding(.horizontal, 20)
                }

                Spacer()

                if currentPage < 3 {
                    Button("下一步") {
                        withAnimation {
                            currentPage += 1
                        }
                    }
                    .foregroundColor(.orange)
                    .padding(.horizontal, 20)
                } else {
                    Button("Dog Go！") {
                        hasSeenOnboarding = true
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(Color.orange)
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                }
            }
            .padding(.bottom, 40)
            .padding(.horizontal, 20)
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.orange.opacity(0.1), Color.yellow.opacity(0.05)]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    // MARK: - 第 1 页：欢迎
    private var onboardingPage1: some View {
        VStack(spacing: 30) {
            Spacer()

            // 像素狗头像
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.2))
                    .frame(width: 200, height: 200)

                PixelDogSprite(
                    dog: Dog.breed(.shiba).build(),
                    pose: .idle,
                    size: 150
                )
            }

            Text("欢迎来到自律狗")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.primary)

            Text("让你的像素柴犬\n陪你一起养成好习惯")
                .font(.system(size: 18))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 40)
    }

    // MARK: - 第 2 页：核心功能
    private var onboardingPage2: some View {
        VStack(spacing: 40) {
            Spacer()

            // 三个步骤
            VStack(spacing: 25) {
                stepRow(icon: "🎯", title: "设定目标", description: "选择你想完成的事情")
                stepRow(icon: "⏱️", title: "专注完成", description: "计时专注，狗狗陪你")
                stepRow(icon: "🎉", title: "获得奖励", description: "升级狗狗，收集道具")
            }

            Spacer()

            Text("简单三步，开始你的自律之旅")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding(.horizontal, 40)
    }

    // MARK: - 第 3 页：狗狗系统
    private var onboardingPage3: some View {
        VStack(spacing: 30) {
            Spacer()

            // 展示多只狗狗
            HStack(spacing: 20) {
                PixelDogSprite(
                    dog: Dog.breed(.shiba).build(),
                    pose: .happy,
                    size: 80
                )
                PixelDogSprite(
                    dog: Dog.breed(.golden).build(),
                    pose: .happy,
                    size: 80
                )
                PixelDogSprite(
                    dog: Dog.breed(.borderCollie).build(),
                    pose: .happy,
                    size: 80
                )
            }

            Text("领养你的专属狗狗")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.primary)

            VStack(spacing: 15) {
                featureRow(icon: "🐕", text: "6 种品种可选")
                featureRow(icon: "🎨", text: "独特外观和性格")
                featureRow(icon: "💝", text: "陪你一起成长")
                featureRow(icon: "🏆", text: "完成目标解锁新伙伴")
            }
            .padding(.top, 10)

            Spacer()
        }
        .padding(.horizontal, 40)
    }

    // MARK: - 第 4 页：开始
    private var onboardingPage4: some View {
        VStack(spacing: 30) {
            Spacer()

            // 开心的狗狗
            PixelDogSprite(
                dog: Dog.breed(.shiba).build(),
                pose: .happy,
                size: 180
            )

            Text("准备好了吗？")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.primary)

            Text("你的第一只柴犬\n正在等待你领养")
                .font(.system(size: 18))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            // 小星星装饰
            HStack(spacing: 40) {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                    .font(.title2)
                Image(systemName: "star.fill")
                    .foregroundColor(.orange)
                    .font(.title)
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                    .font(.title2)
            }
            .padding(.top, 20)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 40)
    }

    // MARK: - 辅助视图
    private func stepRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 20) {
            Text(icon)
                .font(.system(size: 40))
                .frame(width: 60)

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)

                Text(description)
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 15) {
            Text(icon)
                .font(.system(size: 28))

            Text(text)
                .font(.system(size: 17))
                .foregroundColor(.primary)

            Spacer()
        }
    }
}

// MARK: - 预览
struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
            .environmentObject(AppStore())
    }
}
