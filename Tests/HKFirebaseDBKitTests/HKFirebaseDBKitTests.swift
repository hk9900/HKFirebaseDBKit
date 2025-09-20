import XCTest
@testable import HKFirebaseDBKit

final class HKFirebaseDBKitTests: XCTestCase {
    
    func testDatabaseModelProtocol() throws {
        // Test that DatabaseModel protocol works
        let user = TestUser(id: "test-id", name: "Test User", email: "test@example.com")
        XCTAssertEqual(user.id, "test-id")
        XCTAssertEqual(user.name, "Test User")
        XCTAssertEqual(user.email, "test@example.com")
    }
    
    func testTimestampedModel() throws {
        let user = TestTimestampedUser(id: "test-id", name: "Test User")
        let originalCreatedAt = user.createdAt
        let originalUpdatedAt = user.updatedAt
        
        // Test touch method
        var mutableUser = user
        mutableUser.touch()
        
        XCTAssertEqual(mutableUser.createdAt, originalCreatedAt)
        XCTAssertGreaterThan(mutableUser.updatedAt, originalUpdatedAt)
    }
    
    func testValidatableModel() throws {
        let validUser = TestValidatableUser(id: "test-id", name: "Test User", email: "test@example.com")
        XCTAssertNoThrow(try validUser.validate())
        
        let invalidUser = TestValidatableUser(id: "test-id", name: "", email: "invalid-email")
        XCTAssertThrowsError(try invalidUser.validate())
    }
    
    func testTransformableModel() throws {
        let user = TestTransformableUser(id: "test-id", name: "test user", email: "TEST@EXAMPLE.COM")
        let transformed = user.transform()
        
        XCTAssertEqual(transformed.name, "Test User") // Should be capitalized
        XCTAssertEqual(transformed.email, "test@example.com") // Should be lowercase
    }
    
    func testDatabaseError() throws {
        let error = DatabaseError.documentNotFound("test-id")
        XCTAssertEqual(error.localizedDescription, "Document with ID 'test-id' not found")
        XCTAssertEqual(error.failureReason, "The requested document does not exist in the database")
        XCTAssertEqual(error.recoverySuggestion, "Check if the document ID is correct and the document exists")
    }
    
    func testValidationError() throws {
        let error = ValidationError.invalidEmail("invalid-email")
        XCTAssertEqual(error.localizedDescription, "Invalid email format: invalid-email")
        
        let emptyFieldError = ValidationError.emptyField("name")
        XCTAssertEqual(emptyFieldError.localizedDescription, "Field 'name' cannot be empty")
    }
    
    func testQueryBuilder() throws {
        let queryBuilder = QueryBuilder<TestUser>(collection: "users")
        
        // Test chaining
        let query = queryBuilder
            .where("name", isEqualTo: "Test User")
            .where("email", isEqualTo: "test@example.com")
            .orderBy("name", direction: .ascending)
            .limit(10)
            .offset(5)
            .query
        
        XCTAssertEqual(query.collection, "users")
        XCTAssertEqual(query.whereClauses.count, 2)
        XCTAssertEqual(query.orderBy.count, 1)
        XCTAssertEqual(query.limit, 10)
        XCTAssertEqual(query.offset, 5)
    }
    
    func testDatabaseConfiguration() throws {
        let config = DatabaseConfiguration(
            collections: [
                "users": CollectionConfiguration(
                    name: "users",
                    validationRules: ValidationRules(
                        requiredFields: ["name", "email"],
                        fieldValidators: [
                            "email": FieldValidator(type: .email)
                        ]
                    )
                )
            ],
            enableOfflinePersistence: true,
            cacheSettings: CacheSettings(sizeBytes: 50 * 1024 * 1024),
            retrySettings: RetrySettings(maxRetries: 5)
        )
        
        XCTAssertEqual(config.collections.count, 1)
        XCTAssertTrue(config.enableOfflinePersistence)
        XCTAssertEqual(config.cacheSettings.sizeBytes, 50 * 1024 * 1024)
        XCTAssertEqual(config.retrySettings.maxRetries, 5)
    }
}

// MARK: - Test Models

struct TestUser: DatabaseModel {
    let id: String
    let name: String
    let email: String
}

struct TestTimestampedUser: TimestampedModel {
    let id: String
    let name: String
    var createdAt: Date
    var updatedAt: Date
    
    init(id: String, name: String) {
        self.id = id
        self.name = name
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

struct TestValidatableUser: DatabaseModel, ValidatableModel {
    let id: String
    let name: String
    let email: String
    
    func validate() throws {
        guard !name.isEmpty else {
            throw ValidationError.emptyField("name")
        }
        guard email.contains("@") else {
            throw ValidationError.invalidEmail(email)
        }
    }
}

struct TestTransformableUser: DatabaseModel, TransformableModel {
    let id: String
    let name: String
    let email: String
    
    func transform() -> TestTransformableUser {
        return TestTransformableUser(
            id: id,
            name: name.capitalized,
            email: email.lowercased()
        )
    }
}
