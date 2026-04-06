import Foundation
import SwiftUI

// Stub HealthKitManager — HealthKit will be added back in v1.1
class HealthKitManager: ObservableObject {
    @Published var isAuthorized = false
    @Published var todaySteps: Int = 0
    @Published var todayActiveEnergy: Double = 0
    @Published var todaySleepHours: Double = 0
    @Published var todayStandHours: Int = 0
    @Published var heartRate: Double = 0
    @Published var mindfulnessMinutes: Double = 0

    func requestAuthorization() {
        // HealthKit disabled for v1.0
    }

    func fetchTodayData() {
        // HealthKit disabled for v1.0
    }

    // MARK: - Habit Validation
    func validateStepsHabit(target: Double) -> Bool {
        return Double(todaySteps) >= target
    }

    func validateSleepHabit(targetHours: Double) -> Bool {
        return todaySleepHours >= targetHours
    }

    func validateMindfulnessHabit(targetMinutes: Double) -> Bool {
        return mindfulnessMinutes >= targetMinutes
    }

    // MARK: - Health Insights
    var sleepQuality: String {
        switch todaySleepHours {
        case 8...: return "Excellent"
        case 7...: return "Good"
        case 6...: return "Fair"
        default: return "Poor"
        }
    }

    var activityLevel: String {
        switch todaySteps {
        case 10000...: return "Very Active"
        case 7500...: return "Active"
        case 5000...: return "Moderate"
        case 2500...: return "Light"
        default: return "Sedentary"
        }
    }
}
