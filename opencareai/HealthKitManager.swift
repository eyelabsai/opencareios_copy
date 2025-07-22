//
//  HealthKitManager.swift
//  opencareai
//
//  Created by Shruthi Sathya on 7/21/25.
//

import Foundation
import HealthKit

class HealthKitManager {
    static let shared = HealthKitManager()
    let healthStore = HKHealthStore()

    // 1. Define the types of data you want to read and write
    private var readTypes: Set<HKObjectType> {
            return [
                HKObjectType.characteristicType(forIdentifier: .dateOfBirth)!,
                HKObjectType.characteristicType(forIdentifier: .biologicalSex)!,
                HKObjectType.quantityType(forIdentifier: .height)!,
                HKObjectType.quantityType(forIdentifier: .bodyMass)!, // Weight
                HKObjectType.clinicalType(forIdentifier: .allergyRecord)!,
                HKObjectType.clinicalType(forIdentifier: .conditionRecord)!
            ]
        }

    private var writeTypes: Set<HKSampleType> {
        // We will add medication writing here later
        return []
    }

    // 2. Request authorization from the user
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        // Check if HealthKit is available on the device
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit is not available on this device.")
            completion(false)
            return
        }

        healthStore.requestAuthorization(toShare: writeTypes, read: readTypes) { success, error in
            if let error = error {
                print("HealthKit Authorization Error: \(error.localizedDescription)")
            }
            completion(success)
        }
    }

    // 3. Fetch the user's most recent height
    func fetchCharacteristics() throws -> (dateOfBirth: Date?, biologicalSex: HKBiologicalSexObject?) {
            let dateOfBirth = try healthStore.dateOfBirthComponents().date
            let biologicalSex = try healthStore.biologicalSex()
            return (dateOfBirth, biologicalSex)
        }

        // 4. Fetch most recent height
        func fetchMostRecentHeight(completion: @escaping (Double?) -> Void) {
            guard let heightType = HKQuantityType.quantityType(forIdentifier: .height) else { completion(nil); return }
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
            let query = HKSampleQuery(sampleType: heightType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, _ in
                guard let sample = samples?.first as? HKQuantitySample else {
                    DispatchQueue.main.async { completion(nil) }
                    return
                }
                let heightInInches = sample.quantity.doubleValue(for: .inch())
                DispatchQueue.main.async { completion(heightInInches) }
            }
            healthStore.execute(query)
        }
        
        // 5. Fetch most recent weight
        func fetchMostRecentWeight(completion: @escaping (Double?) -> Void) {
            guard let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else { completion(nil); return }
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
            let query = HKSampleQuery(sampleType: weightType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, _ in
                guard let sample = samples?.first as? HKQuantitySample else {
                    DispatchQueue.main.async { completion(nil) }
                    return
                }
                let weightInPounds = sample.quantity.doubleValue(for: .pound())
                DispatchQueue.main.async { completion(weightInPounds) }
            }
            healthStore.execute(query)
        }

        
        
}
