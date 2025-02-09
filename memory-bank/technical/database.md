# Database Documentation

## Schema Design

### Tables

#### 1. herds
```sql
create table herds (
  uid uuid default uuid_generate_v4() primary key,
  name text not null,
  numberOfAnimals integer not null,
  active boolean default true not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- RLS Policies
alter table herds enable row level security;
```

#### 2. silage_fed
```sql
create table silage_fed (
  uid uuid default uuid_generate_v4() primary key,
  herd_id uuid references herds(uid) not null,
  amount_fed decimal(10,2) not null,
  grain_percentage decimal(5,2) not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- RLS Policies
alter table silage_fed enable row level security;
```

### Indexes

#### herds
```sql
create index idx_herds_active on herds(active);
```

#### silage_fed
```sql
create index idx_silage_fed_herd_id on silage_fed(herd_id);
create index idx_silage_fed_created_at on silage_fed(created_at);
```

## Data Models

### Herd Model
```dart
class Herd {
  final String uid;
  final String name;
  final int numberOfAnimals;
  final bool active;
  final DateTime createdAt;

  // Constructor and JSON serialization methods
}
```

### SilageFed Model
```dart
class SilageFed {
  final String uid;
  final String herdId;
  final double amountFed;
  final double grainPercentage;
  final DateTime createdAt;

  // Constructor and JSON serialization methods
}
```

## Security Considerations

### Row Level Security (RLS)
- Policies based on user authentication
- Separate policies for read/write operations

### Data Validation
- Server-side constraints
- Client-side validation
- Type checking and sanitization