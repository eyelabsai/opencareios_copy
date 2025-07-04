// Services/FirebaseService.swift
import Foundation
import Firebase
import FirebaseFirestore
import FirebaseAuth

class FirebaseService {
    static let shared = FirebaseService()
    private let db = Firestore.firestore()

    private var userId: String? {
        Auth.auth().currentUser?.uid
    }

    // MARK: - User Profile
    func fetchUserProfile(completion: @escaping (Result<User, Error>) -> Void) {
        guard let userId = userId else { return }
        db.collection("users").document(userId).getDocument(as: User.self, completion: completion)
    }
    
    func updateUserProfile(userProfile: User, completion: @escaping (Error?) -> Void) {
        guard let userId = userProfile.id else { return }
        do {
            try db.collection("users").document(userId).setData(from: userProfile, merge: true, completion: completion)
        } catch {
            completion(error)
        }
    }

    // MARK: - Visits
    func saveVisit(_ visit: Visit, completion: @escaping (Error?) -> Void) {
        guard let userId = userId else { return }
        do {
            // Add a new document with an auto-generated ID
            _ = try db.collection("users").document(userId).collection("visits").addDocument(from: visit, completion: completion)
        } catch {
            completion(error)
        }
    }
    
    func fetchVisits(completion: @escaping (Result<[Visit], Error>) -> Void) {
        guard let userId = userId else { return }
        db.collection("users").document(userId).collection("visits").order(by: "date", descending: true).getDocuments { snapshot, error in
            if let snapshot = snapshot {
                let visits = snapshot.documents.compactMap { try? $0.data(as: Visit.self) }
                completion(.success(visits))
            } else if let error = error {
                completion(.failure(error))
            }
        }
    }

    // MARK: - Medications
    func saveMedications(_ medications: [Medication], completion: @escaping (Error?) -> Void) {
        guard let userId = userId, !medications.isEmpty else {
            completion(nil)
            return
        }
        let batch = db.batch()
        let collectionRef = db.collection("users").document(userId).collection("medications")
        medications.forEach { med in
            let docRef = collectionRef.document() // Create a new document for each new medication
            do {
                try batch.setData(from: med, forDocument: docRef)
            } catch {
                completion(error)
                return
            }
        }
        batch.commit(completion: completion)
    }
    
    func fetchMedications(completion: @escaping (Result<[Medication], Error>) -> Void) {
        guard let userId = userId else { return }
        db.collection("users").document(userId).collection("medications").getDocuments { snapshot, error in
            if let snapshot = snapshot {
                let medications = snapshot.documents.compactMap { try? $0.data(as: Medication.self) }
                completion(.success(medications))
            } else if let error = error {
                completion(.failure(error))
            }
        }
    }
}
