<!-- Things left to do -->

# RDBMS + Next.js Project TODO

## 1) 💰 Financial & Revenue Management

### Dynamic Pricing Engine
- [x] Define pricing rules (e.g., occupancy ≥ 80% → remaining seats +25%)
- [x] Decide pricing scope: per **Trip** / **Route** / **Schedule**
- [x] Add DB fields if needed: `base_fare`, `current_fare`, `last_price_update_at`, `pricing_version`
- [x] Create `PriceChangeLog` table (trip_id, old_price, new_price, reason, changed_at)
- [x] Implement stored procedure/trigger:
  - [x] On booking/seat assignment, calculate occupancy = booked / total
  - [x] Apply rule(s) and update `current_fare`
  - [x] Log price change to `PriceChangeLog`
- [ ] Update Next.js booking API to always use `current_fare`
- [x] Admin UI: view pricing changes per trip/route

### Automated Refund / Cancellation System
- [ ] Create DB procedure `cancel_ticket(ticket_id, cancelled_by, reason)`
- [ ] Implement refund policy:
  - [ ] 100% refund if > 24h before departure
  - [ ] 50% refund if < 12h before departure
  - [ ] (Optional) Define 12–24h bracket to avoid policy gaps
- [ ] Ensure atomic transaction “chain reaction”:
  - [ ] Calculate refund amount
  - [ ] Update ticket status → `CANCELLED`
  - [ ] Release seat / update seat status
  - [ ] Insert into `RefundTransaction` / `PaymentLedger`
  - [ ] Audit log entry
- [ ] Next.js endpoint: `POST /api/tickets/:id/cancel`
- [ ] Passenger UI: show refund amount + policy + cancellation history

<!-- IGNORE -->
### Loyalty & Promo Codes
- [ ] Create `PromoCode` table:
  - [ ] `code` (unique), `discount_type` (PERCENT/FIXED), `discount_value`
  - [ ] `expiry_date`, `usage_limit`, `usage_count`, `min_purchase` (optional), `is_active`
- [ ] Create `PromoRedemption` table (promo_id, user_id, ticket_id, redeemed_at)
- [ ] Update booking API:
  - [ ] Validate promo (active, not expired, usage available)
  - [ ] Apply discount and persist on ticket/payment
  - [ ] Increment usage safely (transaction + lock)
- [ ] UI: promo input at checkout + error states
- [ ] Admin UI: create/disable promos, view usage

---

## 2) 🚛 Operations & Logistics

<!-- IGNORE -->
### Fuel Efficiency Analytics (KM per Liter)
- [ ] Ensure `FuelRecord` has: vehicle_id, liters, date, cost, odometer/km
- [ ] Ensure `Trip` has: vehicle_id, distance (or derive from route)
- [ ] Create view `VehicleFuelEfficiency`:
  - [ ] per vehicle: `SUM(km) / SUM(liters)` (with date window support)
- [ ] Create view `LeastEfficientVehicles`:
  - [ ] order by lowest KM/L, include last maintenance date
- [ ] Dashboard widget: “Least Efficient Vehicles”

### Shift Handover System (ShiftLog)
- [ ] Create `ShiftLog` table:
  - [ ] driver_id, assignment_id/vehicle_id, shift_start, shift_end
  - [ ] start_check JSON (fuel_level, cleanliness, tire_pressure, notes)
  - [ ] end_check JSON (fuel_level, cleanliness, tire_pressure, issues)
- [ ] Add constraints:
  - [ ] start_check required at shift start
  - [ ] end_check required to close shift
- [ ] Driver UI:
  - [ ] Start shift checklist form
  - [ ] End shift checklist form
- [ ] Supervisor UI: open shifts + reported issues

<!-- IGNORE -->
### Resource Optimization (AI-lite Vehicle Suggestion)
- [ ] Define vehicle capacity tiers (Small/Medium/High-capacity)
- [ ] Write SQL query:
  - [ ] Given route_id, compute historical occupancy (avg/median + peak)
  - [ ] Suggest best-fit vehicle capacity
  - [ ] Return top 3 candidate vehicles (available, not under maintenance)
- [ ] API endpoint: `GET /api/recommendations/vehicle?routeId=...`
- [ ] Dispatch UI: show recommendation when scheduling trip

---

## 3) 🧠 Advanced RDBMS Features

### Materialized Views for Reporting
- [ ] Identify dashboard metrics currently computed on-demand
- [ ] Create materialized view `DailySummaryMV` (or similar)
- [ ] Add refresh strategy:
  - [ ] refresh hourly (DB job/cron)
  - [ ] optional concurrent refresh (if supported)
- [ ] Update Next.js dashboards to read from MV
- [ ] Display last refresh timestamp in UI

### Soft Delete & Archiving
- [ ] Choose approach:
  - [ ] `is_active` boolean on core tables OR
  - [ ] central `DeletedRecordAudit` table
- [ ] Implement DB functions:
  - [ ] `soft_delete_trip(id, by, reason)`
  - [ ] `restore_trip(id, by)`
- [ ] Apply to: trips, tickets, routes, vehicles (as needed)
- [ ] Update API queries to filter out inactive by default
- [ ] Admin UI:
  - [ ] “Recently deleted” list
  - [ ] Restore action

### Route Pathfinding (Recursive CTEs for Multi-leg Trips)
- [ ] Add route graph tables:
  - [ ] `Stop` table
  - [ ] `RouteEdge` or `IntermediateStop` table (from_stop, to_stop, time, fare_segment optional)
- [ ] Implement recursive CTE:
  - [ ] find paths A → B with transfer stops
  - [ ] cap max transfers (e.g., 2)
- [ ] Add journey schema:
  - [ ] `Journey` table (start, end, total_fare, total_time)
  - [ ] `JourneyLeg` table (journey_id, trip_id/edge_id, leg_order)
- [ ] Update booking flow:
  - [ ] book multi-leg itinerary as one journey
- [ ] UI: search A→B shows direct + transfer options with totals

---

## 4) 📊 Portals & Dashboards

### Mechanic Console
- [ ] Build “Overdue Maintenance” list using `next_maintenance_due()` (or equivalent)
- [ ] Create `MaintenanceLog` table (vehicle_id, date, mechanic_id, work_done, notes)
- [ ] Create `SparePartsUsed` table (maintenance_log_id, part_id, qty, cost)
- [ ] Mechanic UI:
  - [ ] log maintenance + parts used
  - [ ] mark vehicle serviced / update next due date

### Passenger History & Digital Receipts
- [ ] Booking history API (pagination + filters)
- [ ] Add `receipt_snapshot` JSONB on Ticket/Payment:
  - [ ] immutable snapshot (fare, discounts, taxes, trip info, seat, timestamps)
- [ ] Passenger dashboard:
  - [ ] booking history list
  - [ ] spending summary
  - [ ] receipt view + download (PDF/print view)

---

## Project Plumbing (Suggested)
- [ ] Add migrations folder + naming convention
- [ ] Add DB transaction helpers in API layer
- [ ] Add audit logging standard (who/when/what + entity id)
- [ ] Add role-based access control (Admin/Driver/Mechanic/Passenger)
- [ ] Add test plan for procedures/triggers (edge cases + concurrency)