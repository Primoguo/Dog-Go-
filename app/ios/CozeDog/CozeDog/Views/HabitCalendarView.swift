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
                    .fill(Color.white.opacity(0.9))
                    .frame(width: 44, height: 44)
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)

                Image(systemName: "calendar")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.green)
            }
        }
    }
}

// MARK: - Habit Calendar View

struct HabitCalendarView: View {
    @EnvironmentObject var store: AppStore
    @Binding var isPresented: Bool
    @State private var selectedMonth: Date = Date()
    @State private var showsMonthlyReport = false

    var body: some View {
        ZStack {
            // 背景遮罩
            Color.black.opacity(0.4)
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
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(red: 1.0, green: 0.98, blue: 0.95))
            )
            .frame(width: 340, height: 580)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(red: 0.6, green: 0.5, blue: 0.4), lineWidth: 3)
            )
            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .sheet(isPresented: $showsMonthlyReport) {
            MonthlyReportView(month: selectedMonth)
                .environmentObject(store)
        }
    }

    // MARK: - Header

    private var calendarHeader: some View {
        HStack {
            Text("📅 习惯追踪")
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundColor(.black)

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
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.blue.opacity(0.8))
                )
            }

            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    isPresented = false
                }
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.gray)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.orange.opacity(0.3))
        )
    }

    // MARK: - Stats Panel

    private var statsPanel: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                StatItem(
                    icon: "flame.fill",
                    iconColor: .orange,
                    value: "\(store.calculateCurrentStreak())",
                    label: "连续打卡"
                )

                StatItem(
                    icon: "checkmark.circle.fill",
                    iconColor: .green,
                    value: "\(Int(store.calculateMonthlyCompletionRate() * 100))%",
                    label: "本月完成率"
                )
            }

            HStack(spacing: 16) {
                StatItem(
                    icon: "trophy.fill",
                    iconColor: .purple,
                    value: "\(store.calculateLongestStreak())",
                    label: "最长连续"
                )

                StatItem(
                    icon: "calendar.badge.checkmark",
                    iconColor: .blue,
                    value: "\(store.getMonthlyCheckInCount())",
                    label: "本月打卡"
                )
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.yellow.opacity(0.1))
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
                        .foregroundColor(.blue)
                }

                Text(monthYearString(from: selectedMonth))
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(.black)

                Spacer()

                if !Calendar.current.isDate(selectedMonth, equalTo: Date(), toGranularity: .month) {
                    Button(action: {
                        selectedMonth = Date()
                    }) {
                        Text("今天")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.blue)
                    }
                }

                Button(action: {
                    if let newDate = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth) {
                        selectedMonth = newDate
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.blue)
                }
            }

            // 星期标题
            HStack(spacing: 0) {
                ForEach(["日", "一", "二", "三", "四", "五", "六"], id: \.self) { day in
                    Text(day)
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                }
            }

            // 日历网格
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                ForEach(generateCalendarDays(), id: \.self) { date in
                    if let date = date {
                        CalendarDayCell(
                            date: date,
                            hasCheckIn: store.hasCheckIn(on: date),
                            isToday: Calendar.current.isDateInToday(date),
                            isCurrentMonth: Calendar.current.isDate(date, equalTo: selectedMonth, toGranularity: .month)
                        )
                    } else {
                        Color.clear
                            .frame(height: 40)
                    }
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.6))
        )
    }

    // MARK: - Achievement Section

    private var achievementSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("🏆 成就徽章")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(.black)

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
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.purple.opacity(0.1))
        )
    }

    // MARK: - Recovery Section

    private var recoverySection: some View {
        VStack(spacing: 8) {
            Text("📊 断签恢复激励")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(.black)

            Text(store.getStreakRecoveryMessage())
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.green.opacity(0.1))
        )
    }

    // MARK: - Helpers

    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }

    private func generateCalendarDays() -> [Date?] {
        let calendar = Calendar.current
        guard let monthInterval = calendar.dateInterval(of: .month, for: selectedMonth),
              let daysRange = calendar.range(of: .day, in: .month, for: selectedMonth) else {
            return []
        }

        let firstDayOfMonth = monthInterval.start
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)

        var days: [Date?] = Array(repeating: nil, count: firstWeekday - 1)

        for day in daysRange {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth) {
                days.append(date)
            }
        }

        return days
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
                .foregroundColor(isCurrentMonth ? .black : .gray.opacity(0.5))

            if hasCheckIn {
                Circle()
                    .fill(Color.green)
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
            RoundedRectangle(cornerRadius: 4)
                .fill(isToday ? Color.orange.opacity(0.3) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(isToday ? Color.orange : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Stat Item

struct HabitStatItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundColor(.black)

            Text(label)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(color.opacity(0.1))
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
                    .fill(isUnlocked ? Color.yellow : Color.gray.opacity(0.3))
                    .frame(width: 36, height: 36)

                Image(systemName: type.icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(isUnlocked ? .white : .gray)
            }

            Text(type.title)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(isUnlocked ? .black : .gray)
                .lineLimit(1)
        }
    }
}

// MARK: - Monthly Report View

struct MonthlyReportView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss
    let month: Date

    var body: some View {
        VStack(spacing: 20) {
            // 标题
            HStack {
                Text("📊 月度报告")
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(.black)

                Spacer()

                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)

            // 报告内容
            let report = store.generateMonthlyReport(for: month)

            VStack(spacing: 16) {
                // 月份标题
                Text(monthString(from: month))
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(.blue)

                // 统计数据
                VStack(spacing: 12) {
                    reportStatRow(icon: "calendar", label: "打卡天数", value: "\(report.totalCheckIns) 天")
                    reportStatRow(icon: "percent", label: "完成率", value: "\(Int(report.completionRate * 100))%")
                    reportStatRow(icon: "flame.fill", label: "最长连续", value: "\(report.longestStreak) 天")
                    reportStatRow(icon: "timer", label: "专注时长", value: "\(report.totalFocusMinutes) 分钟")

                    if let goalType = report.topGoalType {
                        reportStatRow(icon: "star.fill", label: "最多目标", value: goalType.displayName)
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.yellow.opacity(0.1))
                )

                // 鼓励文案
                Text(encouragementMessage(for: report))
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
            .padding(16)

            Spacer()
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 1.0, green: 0.98, blue: 0.95))
        )
        .frame(width: 320, height: 480)
    }

    private func reportStatRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.blue)
                .frame(width: 24)

            Text(label)
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundColor(.black)

            Spacer()

            Text(value)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(.blue)
        }
    }

    private func monthString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
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
