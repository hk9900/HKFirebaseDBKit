import Foundation

/// Data transformer for database operations
public final class DataTransformer {
    
    /// Transform a model before saving
    /// - Parameter model: Model to transform
    /// - Returns: Transformed model
    public static func transform<T: DatabaseModel>(_ model: T) -> T {
        // Check if model conforms to TransformableModel
        guard let transformable = model as? any TransformableModel else {
            return model // No transformation needed
        }
        
        return transformable.transform() as! T
    }
    
    /// Transform data dictionary
    /// - Parameters:
    ///   - data: Data to transform
    ///   - transformers: Transform functions
    /// - Returns: Transformed data
    public static func transformData(_ data: [String: Any], transformers: [String: (Any) -> Any]) -> [String: Any] {
        var transformedData = data
        
        for (field, transformer) in transformers {
            if let value = transformedData[field] {
                transformedData[field] = transformer(value)
            }
        }
        
        return transformedData
    }
    
    /// Apply default transformations
    /// - Parameter data: Data to transform
    /// - Returns: Transformed data
    public static func applyDefaultTransformations(_ data: [String: Any]) -> [String: Any] {
        var transformedData = data
        
        // Convert dates to timestamps
        for (key, value) in transformedData {
            if let date = value as? Date {
                transformedData[key] = date.timeIntervalSince1970
            }
        }
        
        // Convert URLs to strings
        for (key, value) in transformedData {
            if let url = value as? URL {
                transformedData[key] = url.absoluteString
            }
        }
        
        // Convert enums to strings
        for (key, value) in transformedData {
            if let enumValue = value as? any CaseIterable {
                transformedData[key] = String(describing: enumValue)
            }
        }
        
        return transformedData
    }
    
    /// Reverse transformations for reading
    /// - Parameters:
    ///   - data: Data to reverse transform
    ///   - type: Target type
    /// - Returns: Reverse transformed data
    public static func reverseTransform<T: DatabaseModel>(_ data: [String: Any], to type: T.Type) -> [String: Any] {
        var reversedData = data
        
        // Convert timestamps back to dates
        for (key, value) in reversedData {
            if let timestamp = value as? TimeInterval {
                reversedData[key] = Date(timeIntervalSince1970: timestamp)
            }
        }
        
        // Convert URL strings back to URLs
        for (key, value) in reversedData {
            if let urlString = value as? String, urlString.hasPrefix("http") {
                reversedData[key] = URL(string: urlString)
            }
        }
        
        return reversedData
    }
}

/// Extension to provide convenient transformation methods
public extension DatabaseModel {
    /// Transform the model
    /// - Returns: Transformed model
    func transform() -> Self {
        return DataTransformer.transform(self)
    }
}
