# Setup Guide

## Prerequisites
- PostgreSQL 18.1
- Node.js & npm

## Installation

1. **Install dependencies**
   ```bash
   npm install
   ```

2. **Create PostgreSQL database**
   ```bash
   psql -U postgres
   CREATE DATABASE city_transport;
   CREATE USER transport_user WITH PASSWORD 'transport_pass';
   GRANT ALL PRIVILEGES ON DATABASE city_transport TO transport_user;
   ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO transport_user;
   ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO transport_user;
   \q
   ```

3. **Set environment variables**
   - Create `.env.local`:
   ```
   DATABASE_URL="postgresql://transport_user:transport_pass@localhost:5432/city_transport"
   ```

4. **Push Prisma schema**
   ```bash
   $env:DATABASE_URL="postgresql://transport_user:transport_pass@localhost:5432/city_transport"
   npm exec prisma db push
   ```

5. **Run database procedures & triggers**
   ```bash
   $env:PGPASSWORD="transport_pass"
   psql -U transport_user -d city_transport -f "public/database_procedures_triggers.sql"
   ```

6. **Start development server**
   ```bash
   npm run dev
   ```

Open [http://localhost:3000](http://localhost:3000)

## Database

- **Schema**: `prisma/schema.prisma`
- **Procedures/Triggers/Queries**: `public/database_procedures_triggers.sql`
- **Documentation**: `public/DBImplementationDocumentation.txt`
