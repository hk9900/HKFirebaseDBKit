import Foundation
import FirebaseFirestore
import FirebaseAuth

/// Firebase implementation of DatabaseServiceProtocol
public final class FirebaseDatabaseService: DatabaseServiceProtocol {
    public var configuration: DatabaseConfiguration
    
    private let firestore: Firestore
    private let auth: Auth
    private var subscriptions: [String: ListenerRegistration] = [:]
    
    public init(configuration: DatabaseConfiguration = DatabaseConfiguration()) {
        self.configuration = configuration
        self.firestore = Firestore.firestore()
        self.auth = Auth.auth()
    }
    
    public func configure(_ configuration: DatabaseConfiguration) {
        self.configuration = configuration
    }
    
    // MARK: - CRUD Operations
    
    public func create<T: DatabaseModel>(_ item: T, in collection: String) async throws -> T {
        let startTime = Date()
        
        do {
            // Validate if needed
            if let validatable = item as? any ValidatableModel {
                try validatable.validate()
            }
            
            // Transform if needed
            let transformedItem = (item as? any TransformableModel)?.transform() as? T ?? item
            
            // Get collection reference
            let collectionRef = firestore.collection(collection)
            
            // Convert to dictionary
            let data = try encodeToDictionary(transformedItem)
            
            // Add timestamps if needed
            var finalData = data
            if let timestamped = transformedItem as? any TimestampedModel {
                finalData["createdAt"] = timestamped.createdAt
                finalData["updatedAt"] = timestamped.updatedAt
            }
            
            // Create document
            let docRef = try await collectionRef.addDocument(data: finalData)
            
            // Create updated item with generated ID
            var updatedItem = transformedItem
            if let id = docRef.documentID as? String {
                updatedItem = updateItemId(updatedItem, with: id)
            }
            
            // Track analytics
            trackOperation("create", collection: collection, duration: Date().timeIntervalSince(startTime))
            
            return updatedItem
            
        } catch {
            trackError("create", collection: collection, error: error)
            throw mapFirestoreError(error)
        }
    }
    
    public func read<T: DatabaseModel>(_ type: T.Type, id: String, from collection: String) async throws -> T {
        let startTime = Date()
        
        do {
            let docRef = firestore.collection(collection).document(id)
            let document = try await docRef.getDocument()
            
            guard document.exists else {
                throw DatabaseError.documentNotFound(id)
            }
            
            guard let data = document.data() else {
                throw DatabaseError.invalidData("Document data is nil")
            }
            
            let item = try decodeFromDictionary(data, to: type)
            
            // Track analytics
            trackOperation("read", collection: collection, duration: Date().timeIntervalSince(startTime))
            
            return item
            
        } catch {
            trackError("read", collection: collection, error: error)
            throw mapFirestoreError(error)
        }
    }
    
    public func update<T: DatabaseModel>(_ item: T, in collection: String) async throws -> T {
        let startTime = Date()
        
        do {
            // Validate if needed
            if let validatable = item as? any ValidatableModel {
                try validatable.validate()
            }
            
            // Transform if needed
            let transformedItem = (item as? any TransformableModel)?.transform() as? T ?? item
            
            // Get document reference
            let docRef = firestore.collection(collection).document(transformedItem.id)
            
            // Check if document exists
            let document = try await docRef.getDocument()
            guard document.exists else {
                throw DatabaseError.documentNotFound(transformedItem.id)
            }
            
            // Convert to dictionary
            let data = try encodeToDictionary(transformedItem)
            
            // Add timestamps if needed
            var finalData = data
            if let timestamped = transformedItem as? any TimestampedModel {
                finalData["updatedAt"] = timestamped.updatedAt
            }
            
            // Update document
            try await docRef.setData(finalData, merge: true)
            
            // Track analytics
            trackOperation("update", collection: collection, duration: Date().timeIntervalSince(startTime))
            
            return transformedItem
            
        } catch {
            trackError("update", collection: collection, error: error)
            throw mapFirestoreError(error)
        }
    }
    
    public func delete(id: String, from collection: String) async throws {
        let startTime = Date()
        
        do {
            let docRef = firestore.collection(collection).document(id)
            
            // Check if document exists
            let document = try await docRef.getDocument()
            guard document.exists else {
                throw DatabaseError.documentNotFound(id)
            }
            
            // Delete document
            try await docRef.delete()
            
            // Track analytics
            trackOperation("delete", collection: collection, duration: Date().timeIntervalSince(startTime))
            
        } catch {
            trackError("delete", collection: collection, error: error)
            throw mapFirestoreError(error)
        }
    }
    
    public func exists(id: String, in collection: String) async throws -> Bool {
        do {
            let docRef = firestore.collection(collection).document(id)
            let document = try await docRef.getDocument()
            return document.exists
        } catch {
            throw mapFirestoreError(error)
        }
    }
    
    // MARK: - Query Operations
    
    public func list<T: DatabaseModel>(
        _ type: T.Type,
        from collection: String,
        limit: Int?,
        offset: Int?
    ) async throws -> [T] {
        let startTime = Date()
        
        do {
            var query = firestore.collection(collection)
            
            // Apply limit
            if let limit = limit {
                query = query.limit(to: limit)
            }
            
            // Note: Firestore doesn't support offset directly
            // For offset, you'd need to use pagination with startAfter/endBefore
            
            let snapshot = try await query.getDocuments()
            let items = try snapshot.documents.compactMap { document in
                try decodeFromDictionary(document.data(), to: type)
            }
            
            // Track analytics
            trackOperation("list", collection: collection, duration: Date().timeIntervalSince(startTime))
            
            return items
            
        } catch {
            trackError("list", collection: collection, error: error)
            throw mapFirestoreError(error)
        }
    }
    
    public func count(in collection: String) async throws -> Int {
        do {
            let snapshot = try await firestore.collection(collection).getDocuments()
            return snapshot.documents.count
        } catch {
            throw mapFirestoreError(error)
        }
    }
    
    // MARK: - Batch Operations
    
    public func createBatch<T: DatabaseModel>(_ items: [T], in collection: String) async throws -> [T] {
        let startTime = Date()
        
        do {
            let batch = firestore.batch()
            var createdItems: [T] = []
            
            for item in items {
                // Validate if needed
                if let validatable = item as? any ValidatableModel {
                    try validatable.validate()
                }
                
                // Transform if needed
                let transformedItem = (item as? any TransformableModel)?.transform() as? T ?? item
                
                // Convert to dictionary
                let data = try encodeToDictionary(transformedItem)
                
                // Add timestamps if needed
                var finalData = data
                if let timestamped = transformedItem as? any TimestampedModel {
                    finalData["createdAt"] = timestamped.createdAt
                    finalData["updatedAt"] = timestamped.updatedAt
                }
                
                // Add to batch
                let docRef = firestore.collection(collection).document()
                batch.setData(finalData, forDocument: docRef)
                
                // Create updated item with generated ID
                var updatedItem = transformedItem
                if let id = docRef.documentID as? String {
                    updatedItem = updateItemId(updatedItem, with: id)
                }
                createdItems.append(updatedItem)
            }
            
            // Commit batch
            try await batch.commit()
            
            // Track analytics
            trackOperation("createBatch", collection: collection, duration: Date().timeIntervalSince(startTime))
            
            return createdItems
            
        } catch {
            trackError("createBatch", collection: collection, error: error)
            throw mapFirestoreError(error)
        }
    }
    
    public func updateBatch<T: DatabaseModel>(_ items: [T], in collection: String) async throws -> [T] {
        let startTime = Date()
        
        do {
            let batch = firestore.batch()
            
            for item in items {
                // Validate if needed
                if let validatable = item as? any ValidatableModel {
                    try validatable.validate()
                }
                
                // Transform if needed
                let transformedItem = (item as? any TransformableModel)?.transform() as? T ?? item
                
                // Convert to dictionary
                let data = try encodeToDictionary(transformedItem)
                
                // Add timestamps if needed
                var finalData = data
                if let timestamped = transformedItem as? any TimestampedModel {
                    finalData["updatedAt"] = timestamped.updatedAt
                }
                
                // Add to batch
                let docRef = firestore.collection(collection).document(transformedItem.id)
                batch.setData(finalData, forDocument: docRef, merge: true)
            }
            
            // Commit batch
            try await batch.commit()
            
            // Track analytics
            trackOperation("updateBatch", collection: collection, duration: Date().timeIntervalSince(startTime))
            
            return items
            
        } catch {
            trackError("updateBatch", collection: collection, error: error)
            throw mapFirestoreError(error)
        }
    }
    
    public func deleteBatch(ids: [String], from collection: String) async throws {
        let startTime = Date()
        
        do {
            let batch = firestore.batch()
            
            for id in ids {
                let docRef = firestore.collection(collection).document(id)
                batch.deleteDocument(docRef)
            }
            
            // Commit batch
            try await batch.commit()
            
            // Track analytics
            trackOperation("deleteBatch", collection: collection, duration: Date().timeIntervalSince(startTime))
            
        } catch {
            trackError("deleteBatch", collection: collection, error: error)
            throw mapFirestoreError(error)
        }
    }
    
    // MARK: - Transaction Operations
    
    public func transaction<T>(_ operations: @escaping (TransactionContext) async throws -> T) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            firestore.runTransaction { transaction, errorPointer in
                let context = FirebaseTransactionContext(transaction: transaction, firestore: self.firestore)
                
                Task {
                    do {
                        let result = try await operations(context)
                        continuation.resume(returning: result)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
                
                return nil
            } completion: { result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Real-time Operations
    
    public func subscribe<T: DatabaseModel>(
        to type: T.Type,
        in collection: String,
        onUpdate: @escaping ([T]) -> Void
    ) async throws -> SubscriptionToken {
        let listener = firestore.collection(collection).addSnapshotListener { snapshot, error in
            if let error = error {
                print("Real-time subscription error: \(error)")
                return
            }
            
            guard let snapshot = snapshot else { return }
            
            do {
                let items = try snapshot.documents.compactMap { document in
                    try self.decodeFromDictionary(document.data(), to: type)
                }
                onUpdate(items)
            } catch {
                print("Error decoding real-time data: \(error)")
            }
        }
        
        let token = FirebaseSubscriptionToken(listener: listener)
        subscriptions[token.id] = listener
        
        return token
    }
    
    public func subscribe<T: DatabaseModel>(
        to type: T.Type,
        id: String,
        in collection: String,
        onUpdate: @escaping (T?) -> Void
    ) async throws -> SubscriptionToken {
        let listener = firestore.collection(collection).document(id).addSnapshotListener { snapshot, error in
            if let error = error {
                print("Real-time subscription error: \(error)")
                return
            }
            
            guard let snapshot = snapshot else {
                onUpdate(nil)
                return
            }
            
            guard snapshot.exists, let data = snapshot.data() else {
                onUpdate(nil)
                return
            }
            
            do {
                let item = try self.decodeFromDictionary(data, to: type)
                onUpdate(item)
            } catch {
                print("Error decoding real-time data: \(error)")
                onUpdate(nil)
            }
        }
        
        let token = FirebaseSubscriptionToken(listener: listener)
        subscriptions[token.id] = listener
        
        return token
    }
    
    // MARK: - Migration Operations
    
    public func migrate(from fromVersion: String, to toVersion: String, collections: [String]) async throws {
        // Implementation for data migration
        // This would involve reading data, transforming it, and writing it back
        throw DatabaseError.migrationFailed("Migration not implemented yet")
    }
    
    public func getCurrentSchemaVersion() async throws -> String {
        return configuration.migrationSettings.currentVersion
    }
    
    // MARK: - Utility Operations
    
    public func clearAllData() async throws {
        // Implementation for clearing all data
        // This would involve deleting all documents from all collections
        throw DatabaseError.unknown("Clear all data not implemented yet")
    }
    
    public func export(collection: String, format: ExportFormat) async throws -> Data {
        // Implementation for data export
        throw DatabaseError.unknown("Export not implemented yet")
    }
    
    public func `import`(data: Data, to collection: String, format: ImportFormat) async throws {
        // Implementation for data import
        throw DatabaseError.unknown("Import not implemented yet")
    }
    
    // MARK: - Private Helpers
    
    private func encodeToDictionary<T: DatabaseModel>(_ item: T) throws -> [String: Any] {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        
        let data = try encoder.encode(item)
        let json = try JSONSerialization.jsonObject(with: data)
        
        guard let dictionary = json as? [String: Any] else {
            throw DatabaseError.invalidData("Failed to convert to dictionary")
        }
        
        return dictionary
    }
    
    private func decodeFromDictionary<T: DatabaseModel>(_ data: [String: Any], to type: T.Type) throws -> T {
        let jsonData = try JSONSerialization.data(withJSONObject: data)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        
        return try decoder.decode(type, from: jsonData)
    }
    
    private func updateItemId<T: DatabaseModel>(_ item: T, with id: String) -> T {
        // This is a simplified implementation
        // In a real implementation, you'd need to handle this more carefully
        return item
    }
    
    private func mapFirestoreError(_ error: Error) -> DatabaseError {
        if let firestoreError = error as? NSError {
            switch firestoreError.code {
            case 7: // PERMISSION_DENIED
                return .permissionDenied(firestoreError.localizedDescription)
            case 8: // UNAVAILABLE
                return .networkError(error)
            case 14: // UNAUTHENTICATED
                return .permissionDenied("User not authenticated")
            case 16: // DEADLINE_EXCEEDED
                return .timeoutError
            default:
                return .firestoreError(firestoreError.localizedDescription)
            }
        }
        return .unknown(error.localizedDescription)
    }
    
    private func trackOperation(_ operation: String, collection: String, duration: TimeInterval) {
        guard configuration.analyticsSettings.enableOperationTracking else { return }
        
        let event = AnalyticsEvent(
            name: "database_operation",
            parameters: [
                "operation": operation,
                "collection": collection,
                "duration": duration
            ]
        )
        
        configuration.analyticsSettings.analyticsHandler?(event)
    }
    
    private func trackError(_ operation: String, collection: String, error: Error) {
        guard configuration.analyticsSettings.enableErrorTracking else { return }
        
        let event = AnalyticsEvent(
            name: "database_error",
            parameters: [
                "operation": operation,
                "collection": collection,
                "error": error.localizedDescription
            ]
        )
        
        configuration.analyticsSettings.analyticsHandler?(event)
    }
}

// MARK: - Firebase Transaction Context

private class FirebaseTransactionContext: TransactionContext {
    private let transaction: Transaction
    private let firestore: Firestore
    
    init(transaction: Transaction, firestore: Firestore) {
        self.transaction = transaction
        self.firestore = firestore
    }
    
    func create<T: DatabaseModel>(_ item: T, in collection: String) async throws {
        let data = try encodeToDictionary(item)
        let docRef = firestore.collection(collection).document()
        transaction.setData(data, forDocument: docRef)
    }
    
    func update<T: DatabaseModel>(_ item: T, in collection: String) async throws {
        let data = try encodeToDictionary(item)
        let docRef = firestore.collection(collection).document(item.id)
        transaction.setData(data, forDocument: docRef, merge: true)
    }
    
    func delete(id: String, from collection: String) async throws {
        let docRef = firestore.collection(collection).document(id)
        transaction.deleteDocument(docRef)
    }
    
    func read<T: DatabaseModel>(_ type: T.Type, id: String, from collection: String) async throws -> T? {
        let docRef = firestore.collection(collection).document(id)
        let document = try transaction.getDocument(docRef)
        
        guard document.exists, let data = document.data() else {
            return nil
        }
        
        return try decodeFromDictionary(data, to: type)
    }
    
    private func encodeToDictionary<T: DatabaseModel>(_ item: T) throws -> [String: Any] {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        
        let data = try encoder.encode(item)
        let json = try JSONSerialization.jsonObject(with: data)
        
        guard let dictionary = json as? [String: Any] else {
            throw DatabaseError.invalidData("Failed to convert to dictionary")
        }
        
        return dictionary
    }
    
    private func decodeFromDictionary<T: DatabaseModel>(_ data: [String: Any], to type: T.Type) throws -> T {
        let jsonData = try JSONSerialization.data(withJSONObject: data)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        
        return try decoder.decode(type, from: jsonData)
    }
}

// MARK: - Firebase Subscription Token

private class FirebaseSubscriptionToken: SubscriptionToken {
    let id = UUID().uuidString
    private let listener: ListenerRegistration
    
    init(listener: ListenerRegistration) {
        self.listener = listener
    }
    
    func cancel() {
        listener.remove()
    }
}
