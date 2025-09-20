import Foundation

/// Protocol that all database models must conform to
public protocol DatabaseModel: Codable, Identifiable {
    /// Unique identifier for the model
    var id: String { get }
}

/// Protocol for models that support automatic timestamp management
public protocol TimestampedModel: DatabaseModel {
    /// Creation timestamp
    var createdAt: Date { get set }
    /// Last update timestamp
    var updatedAt: Date { get set }
}

/// Protocol for models that can be validated before saving
public protocol ValidatableModel: DatabaseModel {
    /// Validates the model before saving to database
    /// - Throws: ValidationError if validation fails
    func validate() throws
}

/// Protocol for models that support data transformation
public protocol TransformableModel: DatabaseModel {
    /// Transforms the model before saving to database
    /// - Returns: Transformed version of the model
    func transform() -> Self
}

/// Base implementation of TimestampedModel
public struct BaseTimestampedModel: TimestampedModel {
    public let id: String
    public var createdAt: Date
    public var updatedAt: Date
    
    public init(id: String = UUID().uuidString, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

/// Extension to provide default timestamp behavior
public extension TimestampedModel {
    /// Updates the updatedAt timestamp to current time
    mutating func touch() {
        updatedAt = Date()
    }
    
    /// Creates a copy with updated timestamps
    func withUpdatedTimestamps() -> Self {
        var copy = self
        copy.touch()
        return copy
    }
}
