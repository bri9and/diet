# Diet App Backend

Node.js/Express backend API for the diet tracking application.

## Stack

- Node.js 20+
- Express 4.x
- MongoDB with Mongoose
- Clerk for authentication
- TypeScript

## Prerequisites

- Node.js 20 or later
- MongoDB 7.0 or later (local or Atlas)
- Clerk account with API keys

## Setup

1. Install dependencies:

```bash
npm install
```

2. Copy environment variables:

```bash
cp .env.example .env
```

3. Configure environment variables in `.env`:

- `MONGODB_URI`: Your MongoDB connection string
- `CLERK_SECRET_KEY`: Your Clerk secret key
- `CLERK_PUBLISHABLE_KEY`: Your Clerk publishable key
- `PORT`: Server port (default: 3001)
- `CORS_ORIGIN`: Frontend URL for CORS (default: http://localhost:3000)

4. Start MongoDB (if running locally):

```bash
mongod
```

5. Run the development server:

```bash
npm run dev
```

## Scripts

- `npm run dev` - Start development server with hot reload
- `npm run build` - Build TypeScript to JavaScript
- `npm start` - Run production server
- `npm run lint` - Run ESLint
- `npm run typecheck` - Run TypeScript type checking

## API Endpoints

### Health

- `GET /health` - Health check
- `GET /health/ready` - Readiness check (includes MongoDB status)
- `GET /health/live` - Liveness check

### Users (requires authentication)

- `GET /api/users/me` - Get current user profile
- `PUT /api/users/me` - Update current user profile
- `DELETE /api/users/me` - Soft delete user account

### Food Logs (requires authentication)

- `GET /api/food-logs` - Get food logs (supports query params: startDate, endDate, mealType)
- `GET /api/food-logs/:id` - Get specific food log
- `POST /api/food-logs` - Create food log
- `PUT /api/food-logs/:id` - Update food log
- `DELETE /api/food-logs/:id` - Soft delete food log

### Foods (requires authentication)

- `GET /api/foods/search?q=query` - Search foods by name/brand
- `GET /api/foods/barcode/:barcode` - Get food by barcode
- `GET /api/foods/:id` - Get specific food
- `POST /api/foods` - Create custom food
- `PUT /api/foods/:id` - Update custom food (owner only)
- `DELETE /api/foods/:id` - Soft delete custom food (owner only)

## Project Structure

```
backend/
├── src/
│   ├── config/
│   │   └── database.ts      # MongoDB connection
│   ├── middleware/
│   │   └── auth.ts          # Clerk authentication
│   ├── models/
│   │   ├── User.ts          # User model
│   │   ├── Food.ts          # Food model
│   │   ├── FoodLog.ts       # Food log model
│   │   ├── WeightLog.ts     # Weight log model
│   │   └── index.ts         # Model exports
│   ├── routes/
│   │   ├── health.ts        # Health check routes
│   │   ├── users.ts         # User routes
│   │   ├── foodLogs.ts      # Food log routes
│   │   ├── foods.ts         # Food routes
│   │   └── index.ts         # Route exports
│   └── index.ts             # Express app entry point
├── .env.example             # Environment variables template
├── .gitignore               # Git ignore rules
├── package.json             # Dependencies and scripts
├── tsconfig.json            # TypeScript configuration
└── README.md                # This file
```

## Authentication

All `/api/*` routes require authentication via Clerk. Include the Clerk session token in the `Authorization` header:

```
Authorization: Bearer <clerk_session_token>
```

The frontend Clerk SDK handles this automatically when configured correctly.
