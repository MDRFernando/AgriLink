# AgriLink Backend API

NestJS REST API for the AgriLink agricultural marketplace. Connects farmers, businesses, and government authorities with role-based access control.

## Stack

- **NestJS** — API framework
- **Prisma** — ORM
- **SQLite** — local dev database (swap to PostgreSQL for production)
- **JWT** — authentication
- **bcrypt** — password hashing

## Quick start

```bash
cd backend
npm install
npm run db:setup    # migrate + seed
npm run start:dev   # http://localhost:3000/api/v1
```

## Demo accounts

All seeded users use password: `password123`

| Role       | Email                 |
|------------|-----------------------|
| Farmer     | farmer@agrilink.lk    |
| Business   | business@agrilink.lk  |
| Government | gov@agrilink.lk       |

## API endpoints

Base URL: `http://localhost:3000/api/v1`

### Auth
| Method | Path            | Auth | Description        |
|--------|-----------------|------|--------------------|
| POST   | /auth/register  | No   | Register user      |
| POST   | /auth/login     | No   | Login, get JWT     |
| GET    | /auth/me        | Yes  | Current profile    |
| PATCH  | /auth/profile   | Yes  | Complete profile   |

### Productions
| Method | Path                   | Auth   | Role    |
|--------|------------------------|--------|---------|
| GET    | /productions           | No     | —       |
| GET    | /productions/mine      | Yes    | farmer  |
| GET    | /productions/:id       | No     | —       |
| POST   | /productions           | Yes    | farmer  |
| PATCH  | /productions/:id       | Yes    | farmer  |
| PATCH  | /productions/:id/status| Yes    | farmer  |

### Demands
| Method | Path              | Auth | Role              |
|--------|-------------------|------|-------------------|
| GET    | /demands          | No   | —                 |
| GET    | /demands/mine     | Yes  | business/gov      |
| POST   | /demands          | Yes  | business/gov      |
| PATCH  | /demands/:id/status | Yes | business/gov    |

### Interests
| Method | Path                  | Auth | Role     |
|--------|-----------------------|------|----------|
| GET    | /interests/mine       | Yes  | business |
| GET    | /interests/received   | Yes  | farmer   |
| POST   | /interests            | Yes  | business |
| PATCH  | /interests/:id/status | Yes  | farmer   |

### Analytics (Government only)
| Method | Path                      | Description              |
|--------|---------------------------|--------------------------|
| GET    | /analytics/dashboard      | Summary counts           |
| GET    | /analytics/regional       | Regional capacity        |
| GET    | /analytics/trends/:crop   | Crop production trends   |
| GET    | /analytics/alerts         | Shortage/surplus alerts  |

### Crop planning
| Method | Path | Auth | Role |
|--------|------|------|------|
| GET | /crop-plans/mine | Yes | farmer |
| POST | /crop-plans | Yes | farmer |
| PATCH | /crop-plans/:id | Yes | farmer |
| GET | /crop-plans/dashboard | Yes | government |
| GET | /crop-plans/aggregates | Yes | government |
| GET | /crop-plans/insights | Yes | government |

Query filters on government routes: `cropType`, `district`, `dsDivision`, `village`, `month`, `year`, `groupBy` (`crop` \| `district` \| `dsDivision` \| `village` \| `period`).

### Reference
| Method | Path               | Description     |
|--------|--------------------|-----------------|
| GET    | /reference/crops   | Crop types      |
| GET    | /reference/regions | Sri Lanka regions |
| GET    | /reference/units   | Quantity units  |
| GET    | /reference/geo     | District / DS Division / village tree |

## Authentication

Send JWT in the `Authorization` header:

```
Authorization: Bearer <accessToken>
```

## Example: Login

```bash
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"farmer@agrilink.lk","password":"password123"}'
```

## Production (PostgreSQL)

Update `prisma/schema.prisma`:

```prisma
datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}
```

Set `DATABASE_URL` in `.env` and run `npm run prisma:migrate`.

## Flutter integration

Point the mobile app to:

```
http://localhost:3000/api/v1        # iOS simulator
http://10.0.2.2:3000/api/v1         # Android emulator
```
