import Foundation

/// Main protocol for database operations
public protocol DatabaseServiceProtocol {
    /// Configuration for the database service
    var configuration: DatabaseConfiguration { get }
    
    /// Configure the database service
    /// - Parameter configuration: Database configuration
    func configure(_ configuration: DatabaseConfiguration)
    
    // MARK: - CRUD Operations
    
    /// Create a new document
    /// - Parameters:
    ///   - item: The item to create
    ///   - collection: Collection name
    /// - Returns: The created item with generated ID
    func create<T: DatabaseModel>(_ item: T, in collection: String) async throws -> T
    
    /// Read a document by ID
    /// - Parameters:
    ///   - type: The type to decode to
    ///   - id: Document ID
    ///   - collection: Collection name
    /// - Returns: The decoded document
    func read<T: DatabaseModel>(_ type: T.Type, id: String, from collection: String) async throws -> T
    
    /// Update an existing document
    /// - Parameters:
    ///   - item: The item to update
    ///   - collection: Collection name
    /// - Returns: The updated item
    func update<T: DatabaseModel>(_ item: T, in collection: String) async throws -> T
    
    /// Delete a document by ID
    /// - Parameters:
    ///   - id: Document ID
    ///   - collection: Collection name
    func delete(id: String, from collection: String) async throws
    
    /// Check if a document exists
    /// - Parameters:
    ///   - id: Document ID
    ///   - collection: Collection name
    /// - Returns: True if document exists
    func exists(id: String, in collection: String) async throws -> Bool
    
    // MARK: - Query Operations
    
    /// List documents with optional filtering and sorting
    /// - Parameters:
    ///   - type: The type to decode to
    ///   - collection: Collection name
    ///   - limit: Maximum number of documents to return
    ///   - offset: Number of documents to skip
    /// - Returns: Array of decoded documents
    func list<T: DatabaseModel>(
        _ type: T.Type,
        from collection: String,
        limit: Int?,
        offset: Int?
    ) async throws -> [T]
    
    /// Count documents in a collection
    /// - Parameter collection: Collection name
    /// - Returns: Number of documents
    func count(in collection: String) async throws -> Int
    
    // MARK: - Batch Operations
    
    /// Create multiple documents in a batch
    /// - Parameters:
    ///   - items: Items to create
    ///   - collection: Collection name
    /// - Returns: Array of created items
    func createBatch<T: DatabaseModel>(_ items: [T], in collection: String) async throws -> [T]
    
    /// Update multiple documents in a batch
    /// - Parameters:
    ///   - items: Items to update
    ///   - collection: Collection name
    /// - Returns: Array of updated items
    func updateBatch<T: DatabaseModel>(_ items: [T], in collection: String) async throws -> [T]
    
    /// Delete multiple documents in a batch
    /// - Parameters:
    ///   - ids: Document IDs to delete
    ///   - collection: Collection name
    func deleteBatch(ids: [String], from collection: String) async throws
    
    // MARK: - Transaction Operations
    
    /// Execute operations in a transaction
    /// - Parameter operations: Transaction operations
    /// - Returns: Transaction result
    func transaction<T>(_ operations: @escaping (TransactionContext) async throws -> T) async throws -> T
    
    // MARK: - Real-time Operations
    
    /// Subscribe to real-time updates for a collection
    /// - Parameters:
    ///   - type: The type to decode to
    ///   - collection: Collection name
    ///   - onUpdate: Callback for updates
    /// - Returns: Subscription token for cancellation
    func subscribe<T: DatabaseModel>(
        to type: T.Type,
        in collection: String,
        onUpdate: @escaping ([T]) -> Void
    ) async throws -> SubscriptionToken
    
    /// Subscribe to real-time updates for a specific document
    /// - Parameters:
    ///   - type: The type to decode to
    ///   - id: Document ID
    ///   - collection: Collection name
    ///   - onUpdate: Callback for updates
    /// - Returns: Subscription token for cancellation
    func subscribe<T: DatabaseModel>(
        to type: T.Type,
        id: String,
        in collection: String,
        onUpdate: @escaping (T?) -> Void
    ) async throws -> SubscriptionToken
    
    // MARK: - Migration Operations
    
    /// Migrate data to a new schema version
    /// - Parameters:
    ///   - fromVersion: Current version
    ///   - toVersion: Target version
    ///   - collections: Collections to migrate
    func migrate(from fromVersion: String, to toVersion: String, collections: [String]) async throws
    
    /// Get current schema version
    /// - Returns: Current schema version
    func getCurrentSchemaVersion() async throws -> String
    
    // MARK: - Utility Operations
    
    /// Clear all data (use with caution)
    func clearAllData() async throws
    
    /// Export collection data
    /// - Parameters:
    ///   - collection: Collection name
    ///   - format: Export format
    /// - Returns: Exported data
    func export(collection: String, format: ExportFormat) async throws -> Data
    
    /// Import data to collection
    /// - Parameters:
    ///   - data: Data to import
    ///   - collection: Collection name
    ///   - format: Import format
    func `import`(data: Data, to collection: String, format: ImportFormat) async throws
}

/// Transaction context for batch operations
public protocol TransactionContext {
    /// Create a document in transaction
    func create<T: DatabaseModel>(_ item: T, in collection: String) async throws
    
    /// Update a document in transaction
    func update<T: DatabaseModel>(_ item: T, in collection: String) async throws
    
    /// Delete a document in transaction
    func delete(id: String, from collection: String) async throws
    
    /// Read a document in transaction
    func read<T: DatabaseModel>(_ type: T.Type, id: String, from collection: String) async throws -> T?
}

/// Subscription token for real-time updates
public protocol SubscriptionToken {
    /// Cancel the subscription
    func cancel()
}

/// Export format
public enum ExportFormat {
    case json
    case csv
    case xml
}

/// Import format
public enum ImportFormat {
    case json
    case csv
    case xml
}
