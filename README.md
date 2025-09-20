# HKFirebaseDBKit

A powerful, generic Swift package for Firebase Firestore database operations with a fluent API, built for iOS and macOS applications.

## Features

- 🚀 **Generic CRUD Operations** - Create, Read, Update, Delete with type safety
- 🔍 **Fluent Query Builder** - Intuitive query building with filtering and sorting
- 📊 **Real-time Subscriptions** - Live data updates with automatic synchronization
- 🔄 **Batch Operations** - Efficient bulk operations and transactions
- ✅ **Data Validation** - Built-in validation with custom rules
- 🔧 **Data Transformation** - Automatic data transformation and migration
- 🛡️ **Security & Access Control** - Configurable security rules and permissions
- 📈 **Analytics Integration** - Built-in hooks for performance monitoring
- 🔄 **Migration Support** - Schema versioning and data migration
- ⚡ **Error Recovery** - Automatic retry mechanisms and error handling

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/HKFirebaseDBKit", from: "1.0.0")
]
```

Or add it through Xcode:
1. File → Add Package Dependencies
2. Enter the repository URL
3. Select the version and add to your target

## Quick Start

### 1. Configure Firebase

```swift
import FirebaseCore
import HKFirebaseDBKit

// Configure Firebase
FirebaseApp.configure()

// Configure HKFirebaseDBKit
let config = DatabaseConfiguration(
    collections: [
        "users": CollectionConfiguration(
            name: "users",
            validationRules: ValidationRules(
                requiredFields: ["email", "name"],
                fieldValidators: [
                    "email": FieldValidator(type: .email),
                    "name": FieldValidator(type: .minLength(2))
                ]
            )
        )
    ]
)

HKFirebaseDBKit.configure(config)
```

### 2. Define Your Models

```swift
import HKFirebaseDBKit

struct User: DatabaseModel, TimestampedModel, ValidatableModel {
    let id: String
    var email: String
    var name: String
    var createdAt: Date
    var updatedAt: Date
    
    func validate() throws {
        guard !email.isEmpty else {
            throw ValidationError.emptyField("email")
        }
        guard !name.isEmpty else {
            throw ValidationError.emptyField("name")
        }
    }
}
```

### 3. Basic CRUD Operations

```swift
// Create
let user = User(id: UUID().uuidString, email: "john@example.com", name: "John Doe")
let createdUser = try await HKFirebaseDBKit.create(user, in: "users")

// Read
let fetchedUser = try await HKFirebaseDBKit.read(User.self, id: "user-id", from: "users")

// Update
var updatedUser = fetchedUser
updatedUser.name = "John Smith"
let savedUser = try await HKFirebaseDBKit.update(updatedUser, in: "users")

// Delete
try await HKFirebaseDBKit.delete(id: "user-id", from: "users")
```

### 4. Query Operations

```swift
// List all users
let users = try await HKFirebaseDBKit.list(User.self, from: "users")

// List with limit and offset
let limitedUsers = try await HKFirebaseDBKit.list(
    User.self, 
    from: "users", 
    limit: 10, 
    offset: 0
)

// Count documents
let userCount = try await HKFirebaseDBKit.count(in: "users")
```

### 5. Fluent Query Builder

```swift
// Simple queries
let activeUsers = try await HKFirebaseDBKit
    .collection(User.self, "users")
    .where("isActive", isEqualTo: true)
    .where("createdAt", isGreaterThan: Date().addingTimeInterval(-86400))
    .orderBy("name", direction: .ascending)
    .limit(20)
    .get()

// Complex queries
let recentUsers = try await HKFirebaseDBKit
    .collection(User.self, "users")
    .where("email", in: ["admin@example.com", "user@example.com"])
    .where("createdAt", isGreaterThan: Date().addingTimeInterval(-604800))
    .orderBy("createdAt", direction: .descending)
    .get()
```

### 6. Real-time Subscriptions

```swift
// Subscribe to collection updates
let subscription = try await HKFirebaseDBKit.subscribe(
    to: User.self,
    in: "users"
) { users in
    print("Users updated: \(users.count)")
}

// Subscribe to document updates
let documentSubscription = try await HKFirebaseDBKit.subscribe(
    to: User.self,
    id: "user-id",
    in: "users"
) { user in
    if let user = user {
        print("User updated: \(user.name)")
    } else {
        print("User deleted")
    }
}

// Cancel subscription
subscription.cancel()
```

### 7. Batch Operations

```swift
// Create multiple users
let users = [
    User(id: UUID().uuidString, email: "user1@example.com", name: "User 1"),
    User(id: UUID().uuidString, email: "user2@example.com", name: "User 2")
]
let createdUsers = try await HKFirebaseDBKit.createBatch(users, in: "users")

// Update multiple users
let updatedUsers = try await HKFirebaseDBKit.updateBatch(users, in: "users")

// Delete multiple users
try await HKFirebaseDBKit.deleteBatch(ids: ["user1", "user2"], from: "users")
```

### 8. Transactions

```swift
// Execute operations in a transaction
let result = try await HKFirebaseDBKit.transaction { context in
    // Create user
    let user = User(id: UUID().uuidString, email: "new@example.com", name: "New User")
    try await context.create(user, in: "users")
    
    // Update counter
    let counter = try await context.read(Counter.self, id: "user-count", from: "counters") ?? Counter(id: "user-count", count: 0)
    var updatedCounter = counter
    updatedCounter.count += 1
    try await context.update(updatedCounter, in: "counters")
    
    return user
}
```

## Advanced Features

### Data Validation

```swift
struct User: DatabaseModel, ValidatableModel {
    let id: String
    var email: String
    var name: String
    var age: Int
    
    func validate() throws {
        guard !email.isEmpty else {
            throw ValidationError.emptyField("email")
        }
        guard email.contains("@") else {
            throw ValidationError.invalidEmail(email)
        }
        guard !name.isEmpty else {
            throw ValidationError.emptyField("name")
        }
        guard age >= 0 else {
            throw ValidationError.custom("Age must be non-negative")
        }
    }
}
```

### Data Transformation

```swift
struct User: DatabaseModel, TransformableModel {
    let id: String
    var email: String
    var name: String
    var profileImage: URL?
    
    func transform() -> Self {
        var transformed = self
        // Transform email to lowercase
        transformed.email = email.lowercased()
        // Transform name to title case
        transformed.name = name.capitalized
        return transformed
    }
}
```

### Analytics Integration

```swift
let config = DatabaseConfiguration(
    analyticsSettings: AnalyticsSettings(
        enableQueryTracking: true,
        enableErrorTracking: true,
        enableOperationTracking: true,
        analyticsHandler: { event in
            // Send to your analytics service
            Analytics.track(event.name, parameters: event.parameters)
        }
    )
)
```

## Error Handling

```swift
do {
    let user = try await HKFirebaseDBKit.read(User.self, id: "user-id", from: "users")
    print("User: \(user.name)")
} catch DatabaseError.documentNotFound(let id) {
    print("User with ID \(id) not found")
} catch DatabaseError.permissionDenied(let reason) {
    print("Permission denied: \(reason)")
} catch DatabaseError.networkError(let error) {
    print("Network error: \(error.localizedDescription)")
} catch {
    print("Unknown error: \(error.localizedDescription)")
}
```

## Requirements

- iOS 16.0+ / macOS 13.0+
- Swift 5.9+
- Firebase iOS SDK 12.0+

## Dependencies

- FirebaseFirestore
- FirebaseAuth

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Support

If you encounter any issues or have questions, please open an issue on GitHub.

## Changelog

### Version 1.0.0
- Initial release
- Generic CRUD operations
- Fluent query builder
- Real-time subscriptions
- Batch operations and transactions
- Data validation and transformation
- Analytics integration
- Error recovery and retry mechanisms
