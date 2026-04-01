import Foundation
import HealthKit
import SwiftUI

class HealthKitManager: ObservableObject {
    let healthStore = HKHealthStore()
    @Published var isAuthorized = false
    @Published var todaySteps: Int = 0
    @Published var todayActiveEnergy: Double = 0
    @Published var todaySleepHours: Double = 0
    @Published var todayStandHours: Int = 0
    @Published var heartRate: Double = 0
    @Published var mindfulnessMinutes: Double = 0

    private let readTypes: Set<HKObjectType> = {
        var types = Set<HKObjectType>()
        if let steps = HKQuantityType.quantityType(forIdentifier: .stepCount) { types.insert(steps) }
        if let energy = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) { types.insert(energy) }
        if let sleep = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) { types.insert(sleep) }
        if let heartRate = HKQuantityType.quantityType(forIdentifier: .heartRate) { types.insert(heartRate) }
        if let mindful = HKCategoryType.categoryType(forIdentifier: .mindfulSession) { types.insert(mindful) }
        if let stand = HKQuantityType.quantityType(forIdentifier: .appleStandTime) { types.insert(stand) }
        return types
    }()

    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else { return }

        healthStore.requestAuthorization(toShare: nil, read: readTypes) { [weak self] success, _ in
            DispatchQueue.main.async {
                self?.isAuthorized = success
                if success {
                    self?.fetchTodayData()
                }
            }
        }
    }

    func fetchTodayData() {
        fetchSteps()
        fetchActiveEnergy()
        fetchSleep()
        fetchHeartRate()
        fetchMindfulness()
    }

    private func fetchSteps() {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }
        let predicate = HKQuery.predicateForSamples(withStart: Calendar.current.startOfDay(for: Date()), end: Date())
        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { [weak self] _, result, _ in
            DispatchQueue.main.async {
                self?.todaySteps = Int(result?.sumQuantity()?.doubleValue(for: .count()) ?? 0)
            }
        }
        healthStore.execute(query)
    }

    private func fetchActiveEnergy() {
        guard let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return }
        let predicate = HKQuery.predicateForSamples(withStart: Calendar.current.startOfDay(for: Date()), end: Date())
        let query = HKStatisticsQuery(quantityType: energyType, quantitySamplePredicate: predicate, options: .cumulativeSum) { [weak self] _, result, _ in
            DispatchQueue.main.async {
                self?.todayActiveEnergy = result?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
            }
        }
        healthStore.execute(query)
    }

    private func fetchSleep() {
        guard let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else { return }
        let yesterday = Calendar.current.date(byAdding: .hour, value: -12, to: Calendar.current.startOfDay(for: Date()))!
        let predicate = HKQuery.predicateForSamples(withStart: yesterday, end: Date())
        let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { [weak self] _, samples, _ in
            guard let sleepSamples = samples as? [HKCategorySample] else { return }
            let inBed = sleepSamples.filter { $0.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue ||
                                              $0.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
                                              $0.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
                                              $0.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue }
            let totalSeconds = inBed.reduce(0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
            DispatchQueue.main.async {
                self?.todaySleepHours = totalSeconds / 3600
            }
        }
        healthStore.execute(query)
    }

    private func fetchHeartRate() {
        guard let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }
        let predicate = HKQuery.predicateForSamples(withStart: Calendar.current.startOfDay(for: Date()), end: Date())
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(sampleType: hrType, predicate: predicate, limit: 1, sortDescriptors: [sort]) { [weak self] _, samples, _ in
            guard let sample = samples?.first as? HKQuantitySample else { return }
            DispatchQueue.main.async {
                self?.heartRate = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
            }
        }
        healthStore.execute(query)
    }

    private func fetchMindfulness() {
        guard let mindfulType = HKCategoryType.categoryType(forIdentifier: .mindfulSession) else { return }
        let predicate = HKQuery.predicateForSamples(withStart: Calendar.current.startOfDay(for: Date()), end: Date())
        let query = HKSampleQuery(sampleType: mindfulType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { [weak self] _, samples, _ in
            let total = samples?.reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) } ?? 0
            DispatchQueue.main.async {
                self?.mindfulnessMinutes = total / 60
            }
        }
        healthStore.execute(query)
    }

    // MARK: - Habit Validation via HealthKit
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
