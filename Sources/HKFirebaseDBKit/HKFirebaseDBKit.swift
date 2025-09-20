import Foundation
import FirebaseCore

/// Main entry point for HKFirebaseDBKit
public struct HKFirebaseDBKit {
    
    /// Shared database service instance
    public static var databaseService: DatabaseServiceProtocol = FirebaseDatabaseService()
    
    /// Configure the database service
    /// - Parameter configuration: Database configuration
    public static func configure(_ configuration: DatabaseConfiguration) {
        databaseService.configure(configuration)
    }
    
    /// Get a query builder for a collection
    /// - Parameter collection: Collection name
    /// - Returns: Query builder instance
    public static func collection<T: DatabaseModel>(_ collection: String) -> QueryBuilder<T> {
        return QueryBuilder<T>(collection: collection)
    }
    
    /// Create a new document
    /// - Parameters:
    ///   - item: The item to create
    ///   - collection: Collection name
    /// - Returns: The created item with generated ID
    public static func create<T: DatabaseModel>(_ item: T, in collection: String) async throws -> T {
        return try await databaseService.create(item, in: collection)
    }
    
    /// Read a document by ID
    /// - Parameters:
    ///   - type: The type to decode to
    ///   - id: Document ID
    ///   - collection: Collection name
    /// - Returns: The decoded document
    public static func read<T: DatabaseModel>(_ type: T.Type, id: String, from collection: String) async throws -> T {
        return try await databaseService.read(type, id: id, from: collection)
    }
    
    /// Update an existing document
    /// - Parameters:
    ///   - item: The item to update
    ///   - collection: Collection name
    /// - Returns: The updated item
    public static func update<T: DatabaseModel>(_ item: T, in collection: String) async throws -> T {
        return try await databaseService.update(item, in: collection)
    }
    
    /// Delete a document by ID
    /// - Parameters:
    ///   - id: Document ID
    ///   - collection: Collection name
    public static func delete(id: String, from collection: String) async throws {
        try await databaseService.delete(id: id, from: collection)
    }
    
    /// List documents with optional filtering and sorting
    /// - Parameters:
    ///   - type: The type to decode to
    ///   - collection: Collection name
    ///   - limit: Maximum number of documents to return
    ///   - offset: Number of documents to skip
    /// - Returns: Array of decoded documents
    public static func list<T: DatabaseModel>(
        _ type: T.Type,
        from collection: String,
        limit: Int? = nil,
        offset: Int? = 0
    ) async throws -> [T] {
        return try await databaseService.list(type, from: collection, limit: limit, offset: offset)
    }
    
    /// Count documents in a collection
    /// - Parameter collection: Collection name
    /// - Returns: Number of documents
    public static func count(in collection: String) async throws -> Int {
        return try await databaseService.count(in: collection)
    }
    
    /// Create multiple documents in a batch
    /// - Parameters:
    ///   - items: Items to create
    ///   - collection: Collection name
    /// - Returns: Array of created items
    public static func createBatch<T: DatabaseModel>(_ items: [T], in collection: String) async throws -> [T] {
        return try await databaseService.createBatch(items, in: collection)
    }
    
    /// Update multiple documents in a batch
    /// - Parameters:
    ///   - items: Items to update
    ///   - collection: Collection name
    /// - Returns: Array of updated items
    public static func updateBatch<T: DatabaseModel>(_ items: [T], in collection: String) async throws -> [T] {
        return try await databaseService.updateBatch(items, in: collection)
    }
    
    /// Delete multiple documents in a batch
    /// - Parameters:
    ///   - ids: Document IDs to delete
    ///   - collection: Collection name
    public static func deleteBatch(ids: [String], from collection: String) async throws {
        try await databaseService.deleteBatch(ids: ids, from: collection)
    }
    
    /// Execute operations in a transaction
    /// - Parameter operations: Transaction operations
    /// - Returns: Transaction result
    public static func transaction<T>(_ operations: @escaping (TransactionContext) async throws -> T) async throws -> T {
        return try await databaseService.transaction(operations)
    }
    
    /// Subscribe to real-time updates for a collection
    /// - Parameters:
    ///   - type: The type to decode to
    ///   - collection: Collection name
    ///   - onUpdate: Callback for updates
    /// - Returns: Subscription token for cancellation
    public static func subscribe<T: DatabaseModel>(
        to type: T.Type,
        in collection: String,
        onUpdate: @escaping ([T]) -> Void
    ) async throws -> SubscriptionToken {
        return try await databaseService.subscribe(to: type, in: collection, onUpdate: onUpdate)
    }
    
    /// Subscribe to real-time updates for a specific document
    /// - Parameters:
    ///   - type: The type to decode to
    ///   - id: Document ID
    ///   - collection: Collection name
    ///   - onUpdate: Callback for updates
    /// - Returns: Subscription token for cancellation
    public static func subscribe<T: DatabaseModel>(
        to type: T.Type,
        id: String,
        in collection: String,
        onUpdate: @escaping (T?) -> Void
    ) async throws -> SubscriptionToken {
        return try await databaseService.subscribe(to: type, id: id, in: collection, onUpdate: onUpdate)
    }
}

