# Test Data Management Guide

Quick reference for managing test data in the city transport ticketing system.

## Prerequisites

- PostgreSQL 18.1+ installed and running
- Database: `city_transport`
- User: `transport_user` (password: `transport_pass`)
- Terminal: PowerShell or cmd

## Clean Test Data

Removes all test data from the database (respects foreign key constraints):

```powershell
psql -U transport_user -d city_transport -f public\cleanup_test_data.sql
```

## Load Test Data

Populates the database with Dhaka city transport scenario:
- 4 routes (Uttara-Gulshan, Dhanmondi-Mirpur, Motijheel-Banani, Farmgate-Mohakhali)
- 3 drivers with Bangladesh license numbers
- 3 vehicles (capacity 25-40 seats)
- 4 passengers
- 4 trips with pricing

```powershell
psql -U transport_user -d city_transport -f public\seed_test_data.sql
```

## Clean + Reseed (Recommended)

```powershell
psql -U transport_user -d city_transport -f public\cleanup_test_data.sql
psql -U transport_user -d city_transport -f public\seed_test_data.sql
```

## Verify Data Loaded

Check routes:
```powershell
psql -U transport_user -d city_transport -c 'SELECT * FROM \"Route\";' 
```

Check trips:
```powershell
psql -U transport_user -d city_transport -c 'SELECT * FROM \"Trip\";' 
```

## Notes

- Both scripts use transactions (`BEGIN`/`COMMIT`) for consistency
- Cleanup order respects foreign key dependencies
- Safe to run multiple times
- Test data includes realistic Dhaka city locations and pricing in BDT
