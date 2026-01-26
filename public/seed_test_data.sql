-- =========================================
-- SEED TEST DATA (Dhaka City Scenario)
-- =========================================

BEGIN;

-- 1. Routes (Dhaka)
INSERT INTO "Route" ("StartLocation", "EndLocation", "Distance")
VALUES
('Uttara', 'Gulshan', 14.50),
('Dhanmondi', 'Mirpur', 8.20),
('Motijheel', 'Banani', 9.75),
('Farmgate', 'Mohakhali', 6.30);

-- 2. Drivers (Bangladeshi names)
INSERT INTO "Driver" ("Name", "LicenseNumber", "ContactInfo")
VALUES
('Md. Rahim Uddin', 'DHK-DL-1001', 'rahim@gmail.com'),
('Abdul Karim', 'DHK-DL-1002', 'karim@gmail.com'),
('Shafiq Ahmed', 'DHK-DL-1003', 'shafiq@gmail.com');

-- 3. Vehicles
INSERT INTO "Vehicle" ("LicensePlate", "Capacity", "Status")
VALUES
('DHAKA-METRO-11-1234', 40, 'active'),
('DHAKA-METRO-12-5678', 30, 'active'),
('DHAKA-METRO-13-9012', 25, 'active');

-- 4. Passengers
INSERT INTO "Passenger" ("Name", "ContactInfo")
VALUES
('Ayesha Rahman', 'ayesha@gmail.com'),
('Tanvir Hasan', 'tanvir@gmail.com'),
('Nusrat Jahan', 'nusrat@gmail.com'),
('Sabbir Hossain', 'sabbir@gmail.com');

-- 5. Trips
INSERT INTO "Trip" (
  "RouteID",
  "VehicleID",
  "DriverID",
  "DepartureTime",
  "ArrivalTime",
  "Price"
)
VALUES
(1, 1, 1, CURRENT_DATE + INTERVAL '08:00', CURRENT_DATE + INTERVAL '09:00', 120.00),
(2, 2, 2, CURRENT_DATE + INTERVAL '10:00', CURRENT_DATE + INTERVAL '11:00', 80.00),
(3, 3, 3, CURRENT_DATE + INTERVAL '12:00', CURRENT_DATE + INTERVAL '13:00', 100.00),
(4, 1, 1, CURRENT_DATE + INTERVAL '15:00', CURRENT_DATE + INTERVAL '16:00', 70.00);

-- 6. Seats (auto-generate based on vehicle capacity)
INSERT INTO "Seat" ("TripID", "SeatNumber", "Status")
SELECT
  t."TripID",
  gs,
  'available'
FROM "Trip" t
JOIN "Vehicle" v ON v."VehicleID" = t."VehicleID",
generate_series(1, v."Capacity") gs;

-- 7. Tickets (tests seat locking + triggers)
INSERT INTO "Ticket" ("TripID", "PassengerID", "SeatNumber", "Price")
VALUES
(1, 1, 1, 120.00),
(1, 2, 2, 120.00),
(2, 3, 1, 80.00),
(3, 4, 1, 100.00);

-- 8. Payments
INSERT INTO "Payment" ("TicketID", "Amount", "PaymentMethod")
VALUES
(1, 120.00, 'card'),
(2, 120.00, 'cash'),
(3, 80.00, 'mobile'),
(4, 100.00, 'card');

-- 9. Maintenance records
INSERT INTO "MaintenanceRecord" ("VehicleID", "Date", "Description", "Cost")
VALUES
(1, CURRENT_DATE - INTERVAL '15 days', 'Engine oil change', 3000.00),
(2, CURRENT_DATE - INTERVAL '20 days', 'Brake service', 4500.00);

-- 10. Fuel records
INSERT INTO "FuelRecord" ("VehicleID", "Date", "FuelAmount", "Cost")
VALUES
(1, CURRENT_DATE - INTERVAL '2 days', 35.5, 4200.00),
(2, CURRENT_DATE - INTERVAL '1 day', 28.0, 3400.00);

-- 11. Incident report
INSERT INTO "IncidentReport" ("TripID", "VehicleID", "IncidentDate", "Description", "Severity")
VALUES
(1, 1, CURRENT_DATE, 'Traffic jam near Airport Road', 'low');

COMMIT;
