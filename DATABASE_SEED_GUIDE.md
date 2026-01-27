# Database Seed & Test Data Management Guide (Prisma)

Quick reference for managing **test data** in the **City Transportation Ticketing System** using **Prisma ORM**.

---

## Prerequisites

- **PostgreSQL 18.1+** installed and running
- Database: `city_transport`
- User: `transport_user`
- Node.js & npm installed
- Prisma CLI available (`npx prisma -v`)
- `.env` file configured

### `.env` example
```env
DATABASE_URL="postgresql://transport_user:transport_pass@localhost:5432/city_transport"


## Reset Test Data

Removes all test data from the database (respects foreign key constraints):

```powershell
npx prisma migrate reset
```

## Migrate Test Data

Populates the database with Dhaka city transport scenario.

```powershell
npx prisma migrate dev
```

## Reseed (Recommended)

```powershell
npx prisma db seed
```

## Verify Data Loaded

```powershell
npx prisma studio
```

## Notes & Best Practices

- All schema changes must be made in `schema.prisma`
- Database structure is managed via Prisma migrations
- Test data is managed exclusively via `seed.ts`
- Safe to run reset and seed commands multiple times during development

### Commit the following files:
- `schema.prisma`
- `prisma/migrations/`
- `seed.ts`

### Do not commit:
- `.env`
- `.env.local`


## Recommended Development Workflow (TL;DR)

```powershell
npx prisma migrate reset
npx prisma db seed
npx prisma studio
```