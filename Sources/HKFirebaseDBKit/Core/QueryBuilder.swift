import Foundation

/// Fluent query builder for database operations
public class QueryBuilder<T: DatabaseModel> {
    private var collection: String
    private var limit: Int?
    private var offset: Int = 0
    private var orderBy: [(String, OrderDirection)] = []
    private var whereClauses: [WhereClause] = []
    private var startAfter: Any?
    private var endBefore: Any?
    
    internal init(collection: String) {
        self.collection = collection
    }
    
    // MARK: - Filtering
    
    /// Add a where clause for equality
    /// - Parameters:
    ///   - field: Field name
    ///   - value: Value to match
    /// - Returns: Query builder instance
    @discardableResult
    public func `where`(_ field: String, isEqualTo value: Any) -> QueryBuilder<T> {
        whereClauses.append(WhereClause(field: field, operator: .equal, value: value))
        return self
    }
    
    /// Add a where clause for inequality
    /// - Parameters:
    ///   - field: Field name
    ///   - value: Value to not match
    /// - Returns: Query builder instance
    @discardableResult
    public func `where`(_ field: String, isNotEqualTo value: Any) -> QueryBuilder<T> {
        whereClauses.append(WhereClause(field: field, operator: .notEqual, value: value))
        return self
    }
    
    /// Add a where clause for greater than
    /// - Parameters:
    ///   - field: Field name
    ///   - value: Value to compare against
    /// - Returns: Query builder instance
    @discardableResult
    public func `where`(_ field: String, isGreaterThan value: Any) -> QueryBuilder<T> {
        whereClauses.append(WhereClause(field: field, operator: .greaterThan, value: value))
        return self
    }
    
    /// Add a where clause for greater than or equal
    /// - Parameters:
    ///   - field: Field name
    ///   - value: Value to compare against
    /// - Returns: Query builder instance
    @discardableResult
    public func `where`(_ field: String, isGreaterThanOrEqualTo value: Any) -> QueryBuilder<T> {
        whereClauses.append(WhereClause(field: field, operator: .greaterThanOrEqual, value: value))
        return self
    }
    
    /// Add a where clause for less than
    /// - Parameters:
    ///   - field: Field name
    ///   - value: Value to compare against
    /// - Returns: Query builder instance
    @discardableResult
    public func `where`(_ field: String, isLessThan value: Any) -> QueryBuilder<T> {
        whereClauses.append(WhereClause(field: field, operator: .lessThan, value: value))
        return self
    }
    
    /// Add a where clause for less than or equal
    /// - Parameters:
    ///   - field: Field name
    ///   - value: Value to compare against
    /// - Returns: Query builder instance
    @discardableResult
    public func `where`(_ field: String, isLessThanOrEqualTo value: Any) -> QueryBuilder<T> {
        whereClauses.append(WhereClause(field: field, operator: .lessThanOrEqual, value: value))
        return self
    }
    
    /// Add a where clause for array contains
    /// - Parameters:
    ///   - field: Field name
    ///   - value: Value to check for
    /// - Returns: Query builder instance
    @discardableResult
    public func `where`(_ field: String, arrayContains value: Any) -> QueryBuilder<T> {
        whereClauses.append(WhereClause(field: field, operator: .arrayContains, value: value))
        return self
    }
    
    /// Add a where clause for array contains any
    /// - Parameters:
    ///   - field: Field name
    ///   - values: Values to check for
    /// - Returns: Query builder instance
    @discardableResult
    public func `where`(_ field: String, arrayContainsAny values: [Any]) -> QueryBuilder<T> {
        whereClauses.append(WhereClause(field: field, operator: .arrayContainsAny, value: values))
        return self
    }
    
    /// Add a where clause for in
    /// - Parameters:
    ///   - field: Field name
    ///   - values: Values to check for
    /// - Returns: Query builder instance
    @discardableResult
    public func `where`(_ field: String, in values: [Any]) -> QueryBuilder<T> {
        whereClauses.append(WhereClause(field: field, operator: .in, value: values))
        return self
    }
    
    /// Add a where clause for not in
    /// - Parameters:
    ///   - field: Field name
    ///   - values: Values to exclude
    /// - Returns: Query builder instance
    @discardableResult
    public func `where`(_ field: String, notIn values: [Any]) -> QueryBuilder<T> {
        whereClauses.append(WhereClause(field: field, operator: .notIn, value: values))
        return self
    }
    
    // MARK: - Ordering
    
    /// Add ordering by field
    /// - Parameters:
    ///   - field: Field name
    ///   - direction: Order direction
    /// - Returns: Query builder instance
    @discardableResult
    public func orderBy(_ field: String, direction: OrderDirection = .ascending) -> QueryBuilder<T> {
        orderBy.append((field, direction))
        return self
    }
    
    // MARK: - Pagination
    
    /// Set limit for results
    /// - Parameter limit: Maximum number of results
    /// - Returns: Query builder instance
    @discardableResult
    public func limit(_ limit: Int) -> QueryBuilder<T> {
        self.limit = limit
        return self
    }
    
    /// Set offset for results
    /// - Parameter offset: Number of results to skip
    /// - Returns: Query builder instance
    @discardableResult
    public func offset(_ offset: Int) -> QueryBuilder<T> {
        self.offset = offset
        return self
    }
    
    /// Set cursor for pagination
    /// - Parameter cursor: Cursor value
    /// - Returns: Query builder instance
    @discardableResult
    public func startAfter(_ cursor: Any) -> QueryBuilder<T> {
        self.startAfter = cursor
        return self
    }
    
    /// Set end cursor for pagination
    /// - Parameter cursor: Cursor value
    /// - Returns: Query builder instance
    @discardableResult
    public func endBefore(_ cursor: Any) -> QueryBuilder<T> {
        self.endBefore = cursor
        return self
    }
    
    // MARK: - Execution
    
    /// Execute the query and return results
    /// - Returns: Array of results
    public func get() async throws -> [T] {
        // This will be implemented by the concrete database service
        throw DatabaseError.unsupportedQueryOperation("Query execution not implemented")
    }
    
    /// Execute the query and return the first result
    /// - Returns: First result or nil
    public func first() async throws -> T? {
        let results = try await limit(1).get()
        return results.first
    }
    
    /// Execute the query and return count
    /// - Returns: Number of results
    public func count() async throws -> Int {
        // This will be implemented by the concrete database service
        throw DatabaseError.unsupportedQueryOperation("Count execution not implemented")
    }
    
    // MARK: - Internal Properties
    
    internal var query: Query {
        return Query(
            collection: collection,
            whereClauses: whereClauses,
            orderBy: orderBy,
            limit: limit,
            offset: offset,
            startAfter: startAfter,
            endBefore: endBefore
        )
    }
}

/// Order direction
public enum OrderDirection {
    case ascending
    case descending
}

/// Where clause
public struct WhereClause {
    let field: String
    let `operator`: WhereOperator
    let value: Any
}

/// Where operators
public enum WhereOperator {
    case equal
    case notEqual
    case greaterThan
    case greaterThanOrEqual
    case lessThan
    case lessThanOrEqual
    case arrayContains
    case arrayContainsAny
    case `in`
    case notIn
}

/// Query representation
public struct Query {
    let collection: String
    let whereClauses: [WhereClause]
    let orderBy: [(String, OrderDirection)]
    let limit: Int?
    let offset: Int
    let startAfter: Any?
    let endBefore: Any?
}

/// Extension to provide convenient query methods
public extension DatabaseServiceProtocol {
    /// Create a query builder for a collection
    /// - Parameter collection: Collection name
    /// - Returns: Query builder instance
    func collection<T: DatabaseModel>(_ collection: String) -> QueryBuilder<T> {
        return QueryBuilder<T>(collection: collection)
    }
}
