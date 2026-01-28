# Database Implementation Progress

## Instructions

### 1. To generate seeds for DB

npx prisma db seed

## Completed

### Stored Procedures (3)

- **assign_driver_to_trip()** - Assigns driver to trip with availability checking to prevent double assignments
- **generate_daily_trip_summary()** - Aggregates daily revenue, passengers, and operational metrics into DailySummary table
- **record_ticket_purchase()** - Records ticket purchase with seat validation, ticket insertion, and seat status update

### Stored Functions (3)

- **calculate_trip_revenue()** - Computes total revenue for a single trip from all ticket sales
- **get_available_seats()** - Returns list of available seats for a specific trip in real time
- **next_maintenance_due()** - Calculates next maintenance date based on last maintenance record (30-day interval)

### Triggers (5)

- **prevent_duplicate_seats** (BEFORE INSERT on Ticket) - Validates that a seat isn't double-booked
- **update_trip_available_seats** (AFTER INSERT on Ticket) - Updates trip occupancy information
- **log_trip_update** (AFTER UPDATE on Trip) - Logs trip updates with occupancy percentage to AuditLog
- **validate_maintenance_interval** (BEFORE INSERT on MaintenanceRecord) - Ensures maintenance records are at least 7 days apart
- **audit_insert_vehicle/trip/driver** (AFTER INSERT) - Auto-logs all insert operations to AuditLog table

### Complex SQL Queries (8)

1. **Nested Subquery** - Finds most profitable route based on aggregated ticket revenue
2. **Multi-table JOIN** - Displays trips with driver name, route, occupancy percentage
3. **Window Functions** - Ranks vehicles by monthly revenue using RANK() OVER
4. **Analytical Query** - Calculates 7-day rolling average of daily passengers per route
5. **CUBE/GROUPING SETS** - Revenue summary grouped by route, vehicle, and date combinations
6. **Reporting Query** - Comprehensive statistics: total trips, cancellations, revenue, tickets (last 30 days)
7. **JSON Extraction** - Extracts and formats audit log details from JSONB column in AuditLog
8. **Index Optimization** - Efficient trip lookup by departure time (uses idx_trip_departure)

### Application Integration (Next.js & Prisma)

- **Driver Management UI** - React-based interface for assigning/unassigning drivers to vehicles per shift.
- **Ticketing Flow** - Multi-step booking UI (Trip select → Seat select → Passenger info → Confirmation).
- **API Transaction Layer**:
  - `POST /api/assign-driver`: Handles driver-vehicle-shift assignments using Prisma transactions.
  - `POST /api/book`: Manages atomic concurrent seat bookings with ACID compliance via `$transaction`.

## Left to Do

### Frontend/API Integration

- Build **Daily Summary Dashboard** to visualize metrics from `DailySummary` table
- Implement **Trip Management Interface** (Create/Edit/Cancel trips)
- Add **Incident Reporting UI** for drivers/mechanics

### Testing & Validation

- Test all SQL procedures/functions with various edge cases via database client
- Performance test complex queries with larger datasets (e.g., 100k+ tickets)
- Verify transaction isolation for concurrent seat bookings under high load

### Enhancements

- Implement **Pagination** for audit logs and large trip lists
- Create stored procedures for:
  - Trip cancellation with automated refund handling
  - Driver performance analytics (trips completed vs incidents)
  - Revenue forecasting based on historical data
- Implement caching strategies for route and vehicle occupancy data

### Documentation

- Add inline SQL comments explaining complex query logic in `public/database_procedures_triggers.sql`
- Document procedure parameters and return values in a dedicated API guide
- Create ER diagram for schema relationships
- Document transaction isolation levels used for seat booking
