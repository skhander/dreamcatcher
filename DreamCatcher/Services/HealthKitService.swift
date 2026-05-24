import Foundation
import HealthKit

@MainActor
final class HealthKitService: ObservableObject {
    static let shared = HealthKitService()

    @Published var isAuthorized = false
    @Published var lastSleepHours: Double?
    @Published var averageSleepHours: Double?
    @Published var sleepCorrelationNote: String?

    private let healthStore = HKHealthStore()

    private init() {}

    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func requestAuthorization() async {
        guard isAvailable else { return }

        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        let typesToRead: Set<HKObjectType> = [sleepType]

        do {
            try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
            isAuthorized = true
            await fetchRecentSleep()
        } catch {
            isAuthorized = false
        }
    }

    func fetchRecentSleep() async {
        guard isAvailable, isAuthorized else { return }

        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return }

        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -14, to: endDate) else { return }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        let samples: [HKCategorySample] = await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, results, _ in
                continuation.resume(returning: results as? [HKCategorySample] ?? [])
            }
            healthStore.execute(query)
        }

        let asleepValues: Set<Int> = [
            HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
            HKCategoryValueSleepAnalysis.asleepCore.rawValue,
            HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
            HKCategoryValueSleepAnalysis.asleepREM.rawValue
        ]

        let asleepSamples = samples.filter { asleepValues.contains($0.value) }

        var sleepByNight: [Date: TimeInterval] = [:]
        for sample in asleepSamples {
            let night = calendar.startOfDay(for: sample.endDate)
            let duration = sample.endDate.timeIntervalSince(sample.startDate)
            sleepByNight[night, default: 0] += duration
        }

        let hours = sleepByNight.map { $0.value / 3600 }
        if let last = hours.first {
            lastSleepHours = last
        }
        if !hours.isEmpty {
            averageSleepHours = hours.reduce(0, +) / Double(hours.count)
        }
    }

    func correlateSleepWithDreams(_ dreams: [Dream]) -> String? {
        guard let avgSleep = averageSleepHours else { return nil }

        let vividEmotions: Set<String> = [DreamEmotion.wonder.rawValue, DreamEmotion.fear.rawValue, DreamEmotion.desire.rawValue]
        let vividDreams = dreams.filter { dream in
            vividEmotions.contains(dream.dominantEmotion ?? "") ||
            dream.symbols.count >= 3
        }

        if avgSleep < 6 && vividDreams.count >= 2 {
            sleepCorrelationNote = "Your dreams have been especially vivid during a period of shorter sleep. Sleep deprivation often intensifies dream recall and emotional tone."
            return sleepCorrelationNote
        }

        if avgSleep >= 7.5 {
            sleepCorrelationNote = "You're sleeping well lately. Restful sleep often supports clearer dream recall and more coherent narratives."
            return sleepCorrelationNote
        }

        return nil
    }
}
