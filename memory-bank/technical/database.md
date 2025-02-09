# Database Documentation

## Supabase Schema Design

### Tables

#### 1. herds
```sql
create table herds (
  id uuid default uuid_generate_v4() primary key,
  name text not null,
  description text,
  head_count integer not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
  deleted_at timestamp with time zone,
  version integer default 1 not null
);

-- RLS Policies
alter table herds enable row level security;
```

#### 2. silage_entries
```sql
create table silage_entries (
  id uuid default uuid_generate_v4() primary key,
  herd_id uuid references herds(id) not null,
  feed_date date not null,
  silage_amount decimal(10,2) not null,
  grain_percentage decimal(5,2) not null,
  notes text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
  deleted_at timestamp with time zone,
  version integer default 1 not null,
  sync_status text default 'pending' not null
);

-- RLS Policies
alter table silage_entries enable row level security;
```

#### 3. sync_queue
```sql
create table sync_queue (
  id uuid default uuid_generate_v4() primary key,
  table_name text not null,
  record_id uuid not null,
  operation text not null,
  payload jsonb not null,
  status text default 'pending' not null,
  retry_count integer default 0 not null,
  last_attempt timestamp with time zone,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- RLS Policies
alter table sync_queue enable row level security;
```

### Indexes

#### herds
```sql
create index idx_herds_deleted_at on herds(deleted_at);
create index idx_herds_updated_at on herds(updated_at);
```

#### silage_entries
```sql
create index idx_silage_entries_herd_id on silage_entries(herd_id);
create index idx_silage_entries_feed_date on silage_entries(feed_date);
create index idx_silage_entries_sync_status on silage_entries(sync_status);
create index idx_silage_entries_deleted_at on silage_entries(deleted_at);
```

#### sync_queue
```sql
create index idx_sync_queue_status on sync_queue(status);
create index idx_sync_queue_table_record on sync_queue(table_name, record_id);
```

## Data Models

### Herd Model
```dart
class Herd {
  final String id;
  final String name;
  final String? description;
  final int headCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final int version;

  // Constructor and JSON serialization methods
}
```

### SilageEntry Model
```dart
class SilageEntry {
  final String id;
  final String herdId;
  final DateTime feedDate;
  final double silageAmount;
  final double grainPercentage;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final int version;
  final String syncStatus;

  // Constructor and JSON serialization methods
}
```

### SyncQueueEntry Model
```dart
class SyncQueueEntry {
  final String id;
  final String tableName;
  final String recordId;
  final String operation;
  final Map<String, dynamic> payload;
  final String status;
  final int retryCount;
  final DateTime? lastAttempt;
  final DateTime createdAt;

  // Constructor and JSON serialization methods
}
```

## Offline Data Handling

### Local SQLite Schema
- Mirrors Supabase schema structure
- Additional sync-related columns
- Indexes for efficient querying

### Sync Strategy
1. **Queue-Based Sync**
   - Track changes in sync_queue table
   - Batch processing of changes
   - Retry mechanism for failed operations

2. **Conflict Resolution**
   - Version-based conflict detection
   - Last-write-wins strategy
   - Merge strategy for non-conflicting changes

3. **Status Tracking**
   - Pending: Initial state
   - Syncing: Currently processing
   - Completed: Successfully synced
   - Failed: Sync failed, needs retry

## Data Access Patterns

### Repository Layer
```dart
abstract class Repository<T> {
  Future<T?> get(String id);
  Future<List<T>> getAll();
  Future<void> save(T item);
  Future<void> delete(String id);
  Future<void> sync();
}
```

### Implementation Example
```dart
class HerdRepository implements Repository<Herd> {
  final Database localDb;
  final SupabaseClient supabaseClient;
  
  // CRUD operations
  // Sync mechanisms
  // Conflict resolution
}
```

## Security Considerations

### Row Level Security (RLS)
- Policies based on user authentication
- Separate policies for read/write operations
- Soft delete implementation

### Data Validation
- Server-side constraints
- Client-side validation
- Type checking and sanitization

### Audit Trail
- Created/Updated timestamps
- Version tracking
- Soft deletes
- Sync status tracking