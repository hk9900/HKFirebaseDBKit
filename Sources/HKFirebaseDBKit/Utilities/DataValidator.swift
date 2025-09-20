import Foundation

/// Data validator for database operations
public final class DataValidator {
    
    /// Validate a model before saving
    /// - Parameter model: Model to validate
    /// - Throws: ValidationError if validation fails
    public static func validate<T: DatabaseModel>(_ model: T) throws {
        // Check if model conforms to ValidatableModel
        guard let validatable = model as? any ValidatableModel else {
            return // No validation needed
        }
        
        try validatable.validate()
    }
    
    /// Validate field value
    /// - Parameters:
    ///   - value: Value to validate
    ///   - field: Field name
    ///   - validator: Field validator
    /// - Throws: ValidationError if validation fails
    public static func validateField(_ value: Any, field: String, validator: FieldValidator) throws {
        switch validator.type {
        case .email:
            guard let email = value as? String, isValidEmail(email) else {
                throw ValidationError.invalidEmail("\(field) is not a valid email")
            }
        case .minLength(let minLength):
            guard let string = value as? String, string.count >= minLength else {
                throw ValidationError.tooShort(field, minLength)
            }
        case .maxLength(let maxLength):
            guard let string = value as? String, string.count <= maxLength else {
                throw ValidationError.tooLong(field, maxLength)
            }
        case .regex(let pattern):
            guard let string = value as? String, matchesRegex(string, pattern: pattern) else {
                throw ValidationError.invalidFormat(field)
            }
        case .custom(let validator):
            guard validator(value) else {
                throw ValidationError.custom("\(field) validation failed")
            }
        }
    }
    
    /// Validate required fields
    /// - Parameters:
    ///   - data: Data dictionary
    ///   - requiredFields: Required field names
    /// - Throws: ValidationError if validation fails
    public static func validateRequiredFields(_ data: [String: Any], requiredFields: [String]) throws {
        for field in requiredFields {
            guard data[field] != nil else {
                throw ValidationError.emptyField(field)
            }
        }
    }
    
    /// Validate custom validators
    /// - Parameters:
    ///   - data: Data dictionary
    ///   - validators: Custom validators
    /// - Throws: ValidationError if validation fails
    public static func validateCustomValidators(_ data: [String: Any], validators: [CustomValidator]) throws {
        for validator in validators {
            guard let value = data[validator.name] else {
                throw ValidationError.emptyField(validator.name)
            }
            
            guard validator.validator(value) else {
                throw ValidationError.custom(validator.errorMessage)
            }
        }
    }
    
    // MARK: - Private Helpers
    
    private static func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        return matchesRegex(email, pattern: emailRegex)
    }
    
    private static func matchesRegex(_ string: String, pattern: String) -> Bool {
        do {
            let regex = try NSRegularExpression(pattern: pattern)
            let range = NSRange(location: 0, length: string.utf16.count)
            return regex.firstMatch(in: string, options: [], range: range) != nil
        } catch {
            return false
        }
    }
}

/// Extension to provide convenient validation methods
public extension DatabaseModel {
    /// Validate the model
    /// - Throws: ValidationError if validation fails
    func validate() throws {
        try DataValidator.validate(self)
    }
}
