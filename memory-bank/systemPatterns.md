# System Patterns

## State Management Patterns

### Local State Management
- **Pattern**: Provider + ChangeNotifier
- **Usage**: For UI-level state and simple data management
- **Benefits**: 
  - Lightweight and built into Flutter
  - Easy to understand and implement
  - Good for local component state

### Data Access Patterns
- **Pattern**: Repository Pattern
- **Usage**: Abstracting data operations with Supabase
- **Implementation**:
  ```dart
  abstract class Repository<T> {
    Future<T> get(String id);
    Future<List<T>> getAll();
    Future<void> save(T item);
    Future<void> delete(String id);
  }
  ```

## Data Integration Patterns

### Supabase Integration
- **Real-time Updates**: Using Supabase's real-time subscriptions
- **Error Handling**: Basic retry mechanism
- **Data Validation**: Server-side constraints

## UI/UX Patterns

### Mobile-Optimized Interface
- Bottom navigation for primary sections
- FAB for primary actions
- Pull-to-refresh for data updates
- Loading state indicators

### Form Patterns
- Progressive disclosure in complex forms
- Inline validation
- Context-preserving navigation
- Success/failure feedback

### List View Patterns
- Efficient filtering
- Cached rendering for performance
- Pull-to-refresh for updates
- Optimistic updates for better UX

## Error Handling Patterns

### Network Errors
- Basic error detection
- User feedback
- Error recovery options
- Standard error messages

### Data Validation
- Client-side validation
- Server-side validation
- Error message standardization

### Exception Management
```dart
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  AppException(this.message, {this.code, this.originalError});
}
```

## Testing Patterns

### Unit Testing
- Repository mocking
- Service isolation
- State management testing

### Widget Testing
- Golden tests for UI consistency
- Integration testing for critical flows
- Mocked services for predictable tests

## Security Patterns

### Authentication (Planned)
- Supabase authentication integration
- Token management
- Session handling

### Data Access
- Row-level security in Supabase
- Role-based access control (planned)
- Data validation and sanitization

## Performance Patterns

### Data Loading
- Efficient querying
- Basic caching
- Image optimization

### State Management
- Granular rebuilds
- Computed properties
- Efficient list rendering
- Memory management best practices