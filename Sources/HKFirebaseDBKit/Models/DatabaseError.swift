import Foundation

/// Comprehensive error types for database operations
public enum DatabaseError: LocalizedError {
    // Document errors
    case documentNotFound(String)
    case documentAlreadyExists(String)
    case invalidDocumentId(String)
    
    // Collection errors
    case collectionNotFound(String)
    case invalidCollectionName(String)
    
    // Permission errors
    case permissionDenied(String)
    case insufficientPermissions(String)
    
    // Network errors
    case networkError(Error)
    case timeoutError
    case connectionError
    
    // Validation errors
    case validationError(String)
    case invalidData(String)
    case missingRequiredField(String)
    
    // Query errors
    case invalidQuery(String)
    case queryLimitExceeded(Int)
    case unsupportedQueryOperation(String)
    
    // Batch operation errors
    case batchOperationFailed([String])
    case transactionFailed(String)
    
    // Migration errors
    case migrationFailed(String)
    case schemaVersionMismatch(String, String)
    
    // Security errors
    case securityRuleViolation(String)
    case accessDenied(String)
    
    // Retry errors
    case maxRetriesExceeded(Int)
    case retryTimeout
    
    // Unknown errors
    case unknown(String)
    case firestoreError(String)
    
    public var errorDescription: String? {
        switch self {
        case .documentNotFound(let id):
            return "Document with ID '\(id)' not found"
        case .documentAlreadyExists(let id):
            return "Document with ID '\(id)' already exists"
        case .invalidDocumentId(let id):
            return "Invalid document ID: '\(id)'"
        case .collectionNotFound(let name):
            return "Collection '\(name)' not found"
        case .invalidCollectionName(let name):
            return "Invalid collection name: '\(name)'"
        case .permissionDenied(let reason):
            return "Permission denied: \(reason)"
        case .insufficientPermissions(let operation):
            return "Insufficient permissions for operation: \(operation)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .timeoutError:
            return "Request timed out"
        case .connectionError:
            return "Connection error"
        case .validationError(let message):
            return "Validation error: \(message)"
        case .invalidData(let message):
            return "Invalid data: \(message)"
        case .missingRequiredField(let field):
            return "Missing required field: \(field)"
        case .invalidQuery(let query):
            return "Invalid query: \(query)"
        case .queryLimitExceeded(let limit):
            return "Query limit exceeded: \(limit)"
        case .unsupportedQueryOperation(let operation):
            return "Unsupported query operation: \(operation)"
        case .batchOperationFailed(let errors):
            return "Batch operation failed with errors: \(errors.joined(separator: ", "))"
        case .transactionFailed(let reason):
            return "Transaction failed: \(reason)"
        case .migrationFailed(let reason):
            return "Migration failed: \(reason)"
        case .schemaVersionMismatch(let current, let expected):
            return "Schema version mismatch. Current: \(current), Expected: \(expected)"
        case .securityRuleViolation(let rule):
            return "Security rule violation: \(rule)"
        case .accessDenied(let resource):
            return "Access denied to resource: \(resource)"
        case .maxRetriesExceeded(let count):
            return "Maximum retries exceeded: \(count)"
        case .retryTimeout:
            return "Retry timeout"
        case .unknown(let message):
            return "Unknown error: \(message)"
        case .firestoreError(let message):
            return "Firestore error: \(message)"
        }
    }
    
    public var failureReason: String? {
        switch self {
        case .documentNotFound:
            return "The requested document does not exist in the database"
        case .permissionDenied:
            return "The current user does not have permission to perform this operation"
        case .networkError:
            return "A network error occurred while communicating with the database"
        case .validationError:
            return "The data provided does not meet the validation requirements"
        case .queryLimitExceeded:
            return "The query exceeds the maximum allowed limit"
        default:
            return nil
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .documentNotFound:
            return "Check if the document ID is correct and the document exists"
        case .permissionDenied:
            return "Ensure the user is authenticated and has the required permissions"
        case .networkError:
            return "Check your internet connection and try again"
        case .validationError:
            return "Review the data and ensure it meets all validation requirements"
        case .queryLimitExceeded:
            return "Reduce the query scope or use pagination"
        default:
            return "Please try again or contact support if the problem persists"
        }
    }
}

/// Validation error for model validation
public enum ValidationError: LocalizedError {
    case invalidEmail(String)
    case invalidPassword(String)
    case invalidName(String)
    case emptyField(String)
    case tooShort(String, Int)
    case tooLong(String, Int)
    case invalidFormat(String)
    case custom(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidEmail(let email):
            return "Invalid email format: \(email)"
        case .invalidPassword(let reason):
            return "Invalid password: \(reason)"
        case .invalidName(let name):
            return "Invalid name: \(name)"
        case .emptyField(let field):
            return "Field '\(field)' cannot be empty"
        case .tooShort(let field, let min):
            return "Field '\(field)' is too short. Minimum length: \(min)"
        case .tooLong(let field, let max):
            return "Field '\(field)' is too long. Maximum length: \(max)"
        case .invalidFormat(let field):
            return "Field '\(field)' has invalid format"
        case .custom(let message):
            return message
        }
    }
}
