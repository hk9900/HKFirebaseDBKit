import Foundation

/// Configuration for database operations
public struct DatabaseConfiguration {
    /// Collection configurations
    public let collections: [String: CollectionConfiguration]
    
    /// Default security rules
    public let defaultSecurityRules: SecurityRules
    
    /// Enable offline persistence
    public let enableOfflinePersistence: Bool
    
    /// Cache settings
    public let cacheSettings: CacheSettings
    
    /// Retry settings
    public let retrySettings: RetrySettings
    
    /// Analytics settings
    public let analyticsSettings: AnalyticsSettings
    
    /// Migration settings
    public let migrationSettings: MigrationSettings
    
    public init(
        collections: [String: CollectionConfiguration] = [:],
        defaultSecurityRules: SecurityRules = SecurityRules(),
        enableOfflinePersistence: Bool = false,
        cacheSettings: CacheSettings = CacheSettings(),
        retrySettings: RetrySettings = RetrySettings(),
        analyticsSettings: AnalyticsSettings = AnalyticsSettings(),
        migrationSettings: MigrationSettings = MigrationSettings()
    ) {
        self.collections = collections
        self.defaultSecurityRules = defaultSecurityRules
        self.enableOfflinePersistence = enableOfflinePersistence
        self.cacheSettings = cacheSettings
        self.retrySettings = retrySettings
        self.analyticsSettings = analyticsSettings
        self.migrationSettings = migrationSettings
    }
}

/// Configuration for a specific collection
public struct CollectionConfiguration {
    /// Collection name in Firestore
    public let name: String
    
    /// Field used as document ID
    public let idField: String
    
    /// Subcollections
    public let subcollections: [String: CollectionConfiguration]?
    
    /// Security rules for this collection
    public let securityRules: SecurityRules?
    
    /// Indexes for this collection
    public let indexes: [IndexConfiguration]?
    
    /// Validation rules
    public let validationRules: ValidationRules?
    
    /// Auto-create collection on first write
    public let autoCreate: Bool
    
    public init(
        name: String,
        idField: String = "id",
        subcollections: [String: CollectionConfiguration]? = nil,
        securityRules: SecurityRules? = nil,
        indexes: [IndexConfiguration]? = nil,
        validationRules: ValidationRules? = nil,
        autoCreate: Bool = true
    ) {
        self.name = name
        self.idField = idField
        self.subcollections = subcollections
        self.securityRules = securityRules
        self.indexes = indexes
        self.validationRules = validationRules
        self.autoCreate = autoCreate
    }
}

/// Security rules configuration
public struct SecurityRules {
    /// Read rules
    public let read: String
    
    /// Write rules
    public let write: String
    
    /// Delete rules
    public let delete: String
    
    public init(
        read: String = "auth != null",
        write: String = "auth != null",
        delete: String = "auth != null"
    ) {
        self.read = read
        self.write = write
        self.delete = delete
    }
}

/// Cache settings
public struct CacheSettings {
    /// Cache size in bytes
    public let sizeBytes: Int
    
    /// Cache TTL in seconds
    public let ttlSeconds: Int
    
    /// Enable query result caching
    public let enableQueryCaching: Bool
    
    public init(
        sizeBytes: Int = 100 * 1024 * 1024, // 100MB
        ttlSeconds: Int = 300, // 5 minutes
        enableQueryCaching: Bool = true
    ) {
        self.sizeBytes = sizeBytes
        self.ttlSeconds = ttlSeconds
        self.enableQueryCaching = enableQueryCaching
    }
}

/// Retry settings
public struct RetrySettings {
    /// Maximum number of retries
    public let maxRetries: Int
    
    /// Initial retry delay in seconds
    public let initialDelay: Double
    
    /// Maximum retry delay in seconds
    public let maxDelay: Double
    
    /// Backoff multiplier
    public let backoffMultiplier: Double
    
    public init(
        maxRetries: Int = 3,
        initialDelay: Double = 1.0,
        maxDelay: Double = 60.0,
        backoffMultiplier: Double = 2.0
    ) {
        self.maxRetries = maxRetries
        self.initialDelay = initialDelay
        self.maxDelay = maxDelay
        self.backoffMultiplier = backoffMultiplier
    }
}

/// Analytics settings
public struct AnalyticsSettings {
    /// Enable query performance tracking
    public let enableQueryTracking: Bool
    
    /// Enable error tracking
    public let enableErrorTracking: Bool
    
    /// Enable operation tracking
    public let enableOperationTracking: Bool
    
    /// Custom analytics handler
    public let analyticsHandler: ((AnalyticsEvent) -> Void)?
    
    public init(
        enableQueryTracking: Bool = true,
        enableErrorTracking: Bool = true,
        enableOperationTracking: Bool = true,
        analyticsHandler: ((AnalyticsEvent) -> Void)? = nil
    ) {
        self.enableQueryTracking = enableQueryTracking
        self.enableErrorTracking = enableErrorTracking
        self.enableOperationTracking = enableOperationTracking
        self.analyticsHandler = analyticsHandler
    }
}

/// Migration settings
public struct MigrationSettings {
    /// Current schema version
    public let currentVersion: String
    
    /// Enable automatic migration
    public let enableAutoMigration: Bool
    
    /// Migration handlers
    public let migrationHandlers: [String: MigrationHandler]?
    
    public init(
        currentVersion: String = "1.0.0",
        enableAutoMigration: Bool = true,
        migrationHandlers: [String: MigrationHandler]? = nil
    ) {
        self.currentVersion = currentVersion
        self.enableAutoMigration = enableAutoMigration
        self.migrationHandlers = migrationHandlers
    }
}

/// Index configuration
public struct IndexConfiguration {
    /// Fields to index
    public let fields: [String]
    
    /// Index type
    public let type: IndexType
    
    /// Is unique index
    public let isUnique: Bool
    
    public init(fields: [String], type: IndexType = .ascending, isUnique: Bool = false) {
        self.fields = fields
        self.type = type
        self.isUnique = isUnique
    }
}

/// Index type
public enum IndexType {
    case ascending
    case descending
    case array
}

/// Validation rules
public struct ValidationRules {
    /// Required fields
    public let requiredFields: [String]
    
    /// Field validators
    public let fieldValidators: [String: FieldValidator]
    
    /// Custom validators
    public let customValidators: [CustomValidator]
    
    public init(
        requiredFields: [String] = [],
        fieldValidators: [String: FieldValidator] = [:],
        customValidators: [CustomValidator] = []
    ) {
        self.requiredFields = requiredFields
        self.fieldValidators = fieldValidators
        self.customValidators = customValidators
    }
}

/// Field validator
public struct FieldValidator {
    /// Validation type
    public let type: ValidationType
    
    /// Validation parameters
    public let parameters: [String: Any]
    
    public init(type: ValidationType, parameters: [String: Any] = [:]) {
        self.type = type
        self.parameters = parameters
    }
}

/// Validation type
public enum ValidationType {
    case email
    case minLength(Int)
    case maxLength(Int)
    case regex(String)
    case custom((Any) -> Bool)
}

/// Custom validator
public struct CustomValidator {
    /// Validator name
    public let name: String
    
    /// Validation function
    public let validator: (Any) -> Bool
    
    /// Error message
    public let errorMessage: String
    
    public init(name: String, validator: @escaping (Any) -> Bool, errorMessage: String) {
        self.name = name
        self.validator = validator
        self.errorMessage = errorMessage
    }
}

/// Migration handler
public struct MigrationHandler {
    /// From version
    public let fromVersion: String
    
    /// To version
    public let toVersion: String
    
    /// Migration function
    public let migrate: (Any) throws -> Any
    
    public init(fromVersion: String, toVersion: String, migrate: @escaping (Any) throws -> Any) {
        self.fromVersion = fromVersion
        self.toVersion = toVersion
        self.migrate = migrate
    }
}

/// Analytics event
public struct AnalyticsEvent {
    /// Event name
    public let name: String
    
    /// Event parameters
    public let parameters: [String: Any]
    
    /// Timestamp
    public let timestamp: Date
    
    public init(name: String, parameters: [String: Any] = [:], timestamp: Date = Date()) {
        self.name = name
        self.parameters = parameters
        self.timestamp = timestamp
    }
}
