import SwiftUI

// MARK: - 首次启动引导视图
struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @EnvironmentObject var store: AppStore
    @State private var currentPage = 0

    var body: some View {
        VStack(spacing: 0) {
            // 页面指示器（像素方块）
            HStack(spacing: 8) {
                ForEach(0..<4) { index in
                    Rectangle()
                        .fill(index == currentPage ? Color.dogBrand : Color.dogTextPlaceholder.opacity(0.3))
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
                    .foregroundColor(Color.dogBrand)
                    .padding(.horizontal, 20)
                }

                Spacer()

                if currentPage < 3 {
                    Button("下一步") {
                        withAnimation {
                            currentPage += 1
                        }
                    }
                    .foregroundColor(Color.dogBrand)
                    .padding(.horizontal, 20)
                } else {
                    Button("Dog Go！") {
                        hasSeenOnboarding = true
                    }
                    .font(.headline)
                    .foregroundColor(Color.dogBgPanel)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(Color.dogBrand)
                    .overlay(Rectangle().stroke(Color.dogBrandDark, lineWidth: 2))
                    .shadow(color: Color.dogPixelShadow.opacity(0.16), radius: 0, x: 4, y: 4)
                    .padding(.horizontal, 20)
                }
            }
            .padding(.bottom, 40)
            .padding(.horizontal, 20)
        }
        .background(
            ZStack {
                Color.dogBgPage
                PixelTinyGrid(colorA: Color.dogAccentBright.opacity(0.15), colorB: .clear, tile: 14)
            }
        )
    }

    // MARK: - 第 1 页：欢迎
    private var onboardingPage1: some View {
        VStack(spacing: 30) {
            Spacer()

            // 像素狗头像（像素风方块背景）
            ZStack {
                Rectangle()
                    .fill(Color.dogBgTexture)
                    .frame(width: 200, height: 200)
                    .overlay(Rectangle().stroke(Color.dogBorder, lineWidth: 2))
                    .shadow(color: Color.dogPixelShadow.opacity(0.16), radius: 0, x: 4, y: 4)

                PixelDogSprite(
                    breed: .shiba,
                    appearance: DogAppearance.generated(for: .shiba, seed: "preview"),
                    size: 150,
                    pose: .idle
                )
            }

            Text("欢迎来到自律狗")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(Color.dogTextPrimary)

            Text("让你的像素柴犬\n陪你一起养成好习惯")
                .font(.system(size: 18))
                .foregroundColor(Color.dogTextSecondary)
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
                .foregroundColor(Color.dogTextSecondary)
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
                    breed: .shiba,
                    appearance: DogAppearance.generated(for: .shiba, seed: "preview"),
                    size: 80,
                    pose: .happy
                )
                PixelDogSprite(
                    breed: .golden,
                    appearance: DogAppearance.generated(for: .golden, seed: "preview"),
                    size: 80,
                    pose: .happy
                )
                PixelDogSprite(
                    breed: .borderCollie,
                    appearance: DogAppearance.generated(for: .borderCollie, seed: "preview"),
                    size: 80,
                    pose: .happy
                )
            }

            Text("领养你的专属狗狗")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Color.dogTextPrimary)

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
                breed: .shiba,
                appearance: DogAppearance.generated(for: .shiba, seed: "preview"),
                size: 180,
                pose: .happy
            )

            Text("准备好了吗？")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(Color.dogTextPrimary)

            Text("你的第一只柴犬\n正在等待你领养")
                .font(.system(size: 18))
                .foregroundColor(Color.dogTextSecondary)
                .multilineTextAlignment(.center)

            // 小星星装饰（像素风配色）
            HStack(spacing: 40) {
                Image(systemName: "star.fill")
                    .foregroundColor(Color.dogAccent)
                    .font(.title2)
                Image(systemName: "star.fill")
                    .foregroundColor(Color.dogBrand)
                    .font(.title)
                Image(systemName: "star.fill")
                    .foregroundColor(Color.dogAccent)
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
                    .foregroundColor(Color.dogTextPrimary)

                Text(description)
                    .font(.system(size: 15))
                    .foregroundColor(Color.dogTextSecondary)
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
                .foregroundColor(Color.dogTextPrimary)

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
