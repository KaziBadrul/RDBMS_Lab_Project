# Transport Management System (TMS)

A robust, full-stack Transport Management System built with **Next.js 15**, **Prisma**, and **PostgreSQL**. This project focuses on efficient fleet logistics, driver management, and passenger ticketing through advanced RDBMS capabilities.

## 🚀 Key Features

- **Ticketing & Booking**: Multi-step flow for trip selection, real-time seat availability, and atomic booking transactions.
- **Fleet Logistics**: Comprehensive management of vehicles, routes, and automated scheduling.
- **Driver Management**: Assignment of drivers to vehicles and shifts with availability validation.
- **Maintenance & Fuel**: Tracking periodic maintenance intervals, fuel consumption, and operational costs.
- **Incident Reporting**: Real-time logging of incidents with severity tracking for both trips and vehicles.
- **Operational Intelligence**: Automated daily summaries of revenue, passenger counts, and trip analytics.

## 🛠 Tech Stack

- **Frontend**: [Next.js 15](https://nextjs.org/) (App Router), React 19, Tailwind CSS.
- **Backend/Database**: [PostgreSQL](https://www.postgresql.org/) managed via [Prisma ORM](https://www.prisma.io/).
- **Advanced RDBMS**: Extensive use of Stored Procedures, Triggers, and Analytical SQL for data integrity and performance.

## 📖 Documentation

For deeper technical insights, please refer to:
- [DATABASE_IMPLEMENTATION.md](./DATABASE_IMPLEMENTATION.md): Overview of stored procedures, triggers, and complex SQL queries.
- [DATABASE_SEED_GUIDE.md](./DATABASE_SEED_GUIDE.md): Instructions on populating the database with realistic data.
- [SETUP.md](./SETUP.md): Detailed environment configuration and local development setup.

## ⚙️ Getting Started

### 1. Prerequisites
- Node.js (v18+)
- PostgreSQL instance

### 2. Setup
```bash
# Install dependencies
npm install

# Configure environment
cp .env.example .env # Update DATABASE_URL in .env

# Initialize database
npx prisma db push
npx prisma db seed
```

### 3. Run Development Server
```bash
npm run dev
```
Open [http://localhost:3000](http://localhost:3000) to see the application in action.
