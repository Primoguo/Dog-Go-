import SwiftUI

// MARK: - Habit Calendar Button

struct HabitCalendarButton: View {
    @EnvironmentObject var store: AppStore
    @Binding var isPresented: Bool

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3)) {
                isPresented = true
            }
        }) {
            ZStack {
                Circle()
                    .fill(Color.dogBgCard)
                    .frame(width: 44, height: 44)
                    .shadow(color: Color.dogPixelShadow.opacity(0.16), radius: 0, x: 3, y: 3)

                Image(systemName: "calendar")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color.dogSuccess)
            }
        }
        .accessibilityLabel("习惯日历")
    }
}

// MARK: - Habit Calendar View

struct HabitCalendarView: View {
    @EnvironmentObject var store: AppStore
    @Binding var isPresented: Bool
    @State private var selectedMonth: Date = Date()
    @State private var showsMonthlyReport = false
    @State private var cachedCalendarDays: [Date?] = []

    var body: some View {
        ZStack {
            // 背景遮罩
            Color.dogScrim.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.3)) {
                        isPresented = false
                    }
                }

            // 主面板
            VStack(spacing: 0) {
                // 标题栏
                calendarHeader

                ScrollView {
                    VStack(spacing: 16) {
                        // 统计面板
                        statsPanel

                        // 日历
                        monthCalendarView

                        // 成就徽章
                        achievementSection

                        // 断签激励
                        recoverySection
                    }
                    .padding(16)
                }
            }
            .background {
                ZStack {
                    Color.dogBgPanel
                    PixelTinyGrid(colorA: Color(hex: 0xF4E6C6, alpha: 0.34), colorB: .clear, tile: 14)
                }
            }
            .frame(width: 340, height: 580)
            .overlay { Rectangle().stroke(Color.dogBorder, lineWidth: 3) }
            .shadow(color: Color.dogPixelShadow.opacity(0.16), radius: 0, x: 4, y: 4)
        }
        .sheet(isPresented: $showsMonthlyReport) {
            MonthlyReportView(month: selectedMonth)
                .environmentObject(store)
        }
        .onAppear {
            updateCalendarDaysCache()
        }
        .onChange(of: selectedMonth) { _, _ in
            updateCalendarDaysCache()
        }
    }

    // MARK: - Header

    private var calendarHeader: some View {
        HStack {
            Text("📅 习惯追踪")
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.dogTextPrimary)

            Spacer()

            Button(action: {
                showsMonthlyReport = true
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 14, weight: .bold))
                    Text("月度报告")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                }
                .foregroundStyle(Color.dogBgPanel)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Rectangle()
                        .fill(Color.dogBrand)
                )
            }

            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    isPresented = false
                }
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.dogTextTertiary)
            }
        }
        .padding(16)
        .background(
            Rectangle()
                .fill(Color.dogAccentLight.opacity(0.3))
        )
    }

    // MARK: - Stats Panel

    private var statsPanel: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                StatItem(
                    icon: "flame.fill",
                    iconColor: Color.dogAccent,
                    value: "\(store.calculateCurrentStreak())",
                    label: "连续打卡"
                )

                StatItem(
                    icon: "checkmark.circle.fill",
                    iconColor: Color.dogSuccess,
                    value: "\(Int(store.calculateMonthlyCompletionRate() * 100))%",
                    label: "本月完成率"
                )
            }

            HStack(spacing: 16) {
                StatItem(
                    icon: "trophy.fill",
                    iconColor: Color.dogAccent,
                    value: "\(store.calculateLongestStreak())",
                    label: "最长连续"
                )

                StatItem(
                    icon: "calendar.badge.checkmark",
                    iconColor: Color.dogBrand,
                    value: "\(store.getMonthlyCheckInCount())",
                    label: "本月打卡"
                )
            }
        }
        .padding(12)
        .background(
            Rectangle()
                .fill(Color.dogAccentBright.opacity(0.1))
        )
    }

    // MARK: - Month Calendar

    private var monthCalendarView: some View {
        VStack(spacing: 12) {
            // 月份切换
            HStack {
                Button(action: {
                    if let newDate = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth) {
                        selectedMonth = newDate
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.dogBrand)
                }

                Text(monthYearString(from: selectedMonth))
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.dogTextPrimary)

                Spacer()

                if !Calendar.current.isDate(selectedMonth, equalTo: Date(), toGranularity: .month) {
                    Button(action: {
                        selectedMonth = Date()
                    }) {
                        Text("今天")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.dogBrand)
                    }
                }

                Button(action: {
                    if let newDate = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth) {
                        selectedMonth = newDate
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.dogBrand)
                }
            }

            // 星期标题
            HStack(spacing: 0) {
                ForEach(["日", "一", "二", "三", "四", "五", "六"], id: \.self) { day in
                    Text(day)
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.dogTextTertiary)
                        .frame(maxWidth: .infinity)
                }
            }

            // 日历网格
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                ForEach(Array(cachedCalendarDays.enumerated()), id: \.offset) { index, date in
                    if let date = date {
                        CalendarDayCell(
                            date: date,
                            hasCheckIn: store.hasCheckIn(on: date),
                            isToday: Calendar.current.isDateInToday(date),
                            isCurrentMonth: Calendar.current.isDate(date, equalTo: selectedMonth, toGranularity: .month)
                        )
                        .id(date)
                    } else {
                        Color.clear
                            .frame(height: 40)
                            .id("blank-\(index)")
                    }
                }
            }
        }
        .padding(12)
        .background {
            ZStack {
                Color.dogBgPanel
                PixelTinyGrid(colorA: Color(hex: 0xF4E6C6, alpha: 0.34), colorB: .clear, tile: 14)
            }
        }
        .overlay { Rectangle().stroke(Color.dogBorder, lineWidth: 2) }
    }

    // MARK: - Achievement Section

    private var achievementSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("🏆 成就徽章")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.dogTextPrimary)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                ForEach(AchievementType.allCases, id: \.self) { type in
                    AchievementBadgeView(
                        type: type,
                        isUnlocked: store.hasAchievement(type)
                    )
                }
            }
        }
        .padding(12)
        .background(
            Rectangle()
                .fill(Color.dogAccentBright.opacity(0.1))
        )
    }

    // MARK: - Recovery Section

    private var recoverySection: some View {
        VStack(spacing: 8) {
            Text("📊 断签恢复激励")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.dogTextPrimary)

            Text(store.getStreakRecoveryMessage())
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundStyle(Color.dogTextTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
        }
        .padding(12)
        .background(
            Rectangle()
                .fill(Color.dogSuccess.opacity(0.1))
        )
    }

    // MARK: - Helpers

    private static let monthYearFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy年M月"
        f.locale = Locale(identifier: "zh_CN")
        return f
    }()

    private func monthYearString(from date: Date) -> String {
        Self.monthYearFormatter.string(from: date)
    }

    private func updateCalendarDaysCache() {
        let calendar = Calendar.current
        guard let monthInterval = calendar.dateInterval(of: .month, for: selectedMonth),
              let daysRange = calendar.range(of: .day, in: .month, for: selectedMonth) else {
            cachedCalendarDays = []
            return
        }

        let firstDayOfMonth = monthInterval.start
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)

        var days: [Date?] = Array(repeating: nil, count: firstWeekday - 1)

        for day in daysRange {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth) {
                days.append(date)
            }
        }

        cachedCalendarDays = days
    }
}

// MARK: - Calendar Day Cell

struct CalendarDayCell: View {
    let date: Date
    let hasCheckIn: Bool
    let isToday: Bool
    let isCurrentMonth: Bool

    var body: some View {
        VStack(spacing: 2) {
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.system(size: 12, weight: isToday ? .bold : .regular, design: .monospaced))
                .foregroundStyle(isCurrentMonth ? Color.dogTextPrimary : Color.dogTextPlaceholder.opacity(0.5))

            if hasCheckIn {
                Circle()
                    .fill(Color.dogSuccess)
                    .frame(width: 6, height: 6)
            } else {
                Circle()
                    .fill(Color.clear)
                    .frame(width: 6, height: 6)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 40)
        .background(
            Rectangle()
                .fill(isToday ? Color.dogAccentLight.opacity(0.3) : Color.clear)
        )
        .overlay(
            Rectangle()
                .stroke(isToday ? Color.dogAccent : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Achievement Badge View

struct AchievementBadgeView: View {
    let type: AchievementType
    let isUnlocked: Bool

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(isUnlocked ? Color.dogAccent : Color.dogTextPlaceholder.opacity(0.3))
                    .frame(width: 36, height: 36)

                Image(systemName: type.icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(isUnlocked ? Color.dogBgPanel : Color.dogTextTertiary)
            }

            Text(type.title)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(isUnlocked ? Color.dogTextPrimary : Color.dogTextTertiary)
                .lineLimit(1)
        }
    }
}

// MARK: - Monthly Report View

struct MonthlyReportView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss
    let month: Date
    @State private var report: MonthlyReport?

    private static let monthYearFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy年M月"
        f.locale = Locale(identifier: "zh_CN")
        return f
    }()

    var body: some View {
        VStack(spacing: 20) {
            // 标题
            HStack {
                Text("📊 月度报告")
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.dogTextPrimary)

                Spacer()

                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.dogTextTertiary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)

            // 报告内容
            if let report {

            VStack(spacing: 16) {
                // 月份标题
                Text(monthString(from: month))
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.dogBrand)

                // 统计数据
                VStack(spacing: 12) {
                    reportStatRow(icon: "calendar", label: "打卡天数", value: "\(report.totalCheckIns) 天")
                    reportStatRow(icon: "percent", label: "完成率", value: "\(Int(report.completionRate * 100))%")
                    reportStatRow(icon: "flame.fill", label: "最长连续", value: "\(report.longestStreak) 天")
                    reportStatRow(icon: "timer", label: "专注时长", value: "\(report.totalFocusMinutes) 分钟")

                    if let goalType = report.topGoalType {
                        reportStatRow(icon: "star.fill", label: "最多目标", value: goalType.label)
                    }
                }
                .padding(16)
                .background(
                    Rectangle()
                        .fill(Color.dogAccentBright.opacity(0.1))
                )

                // 鼓励文案
                Text(encouragementMessage(for: report))
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.dogTextTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
            .padding(16)
            } else {
                Spacer()
                ProgressView()
                Spacer()
            }

            Spacer()
        }
        .background {
            ZStack {
                Color.dogBgPanel
                PixelTinyGrid(colorA: Color(hex: 0xF4E6C6, alpha: 0.34), colorB: .clear, tile: 14)
            }
        }
        .overlay { Rectangle().stroke(Color.dogBorder, lineWidth: 2) }
        .shadow(color: Color.dogPixelShadow.opacity(0.16), radius: 0, x: 4, y: 4)
        .frame(width: 320, height: 480)
        .task {
            let r = store.generateMonthlyReport(for: month)
            store.persistMonthlyReport(r)
            report = r
        }
    }

    private func reportStatRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color.dogBrand)
                .frame(width: 24)

            Text(label)
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundStyle(Color.dogTextPrimary)

            Spacer()

            Text(value)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.dogBrand)
        }
    }

    private func monthString(from date: Date) -> String {
        Self.monthYearFormatter.string(from: date)
    }

    private func encouragementMessage(for report: MonthlyReport) -> String {
        if report.completionRate >= 0.9 {
            return "太棒了！这个月表现非常出色！🎉"
        } else if report.completionRate >= 0.7 {
            return "做得很好！继续保持这个节奏！💪"
        } else if report.completionRate >= 0.5 {
            return "不错的开始，下个月可以做得更好！✨"
        } else {
            return "每一步都算数，继续前进！🌟"
        }
    }
}
