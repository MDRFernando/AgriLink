# Bit App — Existing System Analysis (Phase 1)

**Inspected project:** `/Users/dhanushafernando/my_app`  
**Finding:** There is no separate “Bit App” repository. The working codebase is **AgriLink**, a Flutter + NestJS agricultural marketplace prototype. Bit App enhancements are built **on top of AgriLink**, not as a greenfield rewrite.

## 1. Project structure

| Area | Location |
|------|----------|
| Flutter client | `lib/` (feature-first: auth, onboarding, farmer, business, government) |
| Tests | `test/widget_test.dart` |
| NestJS API | `backend/src/` |
| Database | `backend/prisma/schema.prisma`, SQLite `dev.db` |
| Seed | `backend/prisma/seed.ts` |

## 2. Frontend

- **Flutter** (Dart 3.7+), Material 3
- **Riverpod** state, **go_router** navigation
- **fl_chart** for government analytics
- In-memory mock store (`lib/shared/providers/app_providers.dart`) — UI does **not** yet call the API by default

## 3. Backend

- **NestJS 10**, JWT (`passport-jwt`), bcrypt
- Global prefix: `/api/v1`
- Modules: `auth`, `productions`, `demands`, `interests`, `analytics`, `reference`

## 4. Database (existing)

- SQLite via Prisma
- Models: `User`, `Production`, `DemandRequest`, `PurchaseInterest`
- Enums: `UserRole` (`farmer` \| `business` \| `government`), production/demand/interest statuses

## 5. Auth / authz

- Register/login JWT
- Role middleware (`JwtAuthGuard`, `RolesGuard`)
- Profile completion sets `isVerified: true` (no document verification)

## 6. Roles (existing → Bit App labels)

| DB / code value | Old UI | Bit App UI |
|-----------------|--------|------------|
| `farmer` | Farmer | Farmer |
| `business` | Business | **Buyer** (backward-compatible enum) |
| `government` | Government | **Admin** (research + ops) |

## 7. Farmer features (existing)

Register, profile, add/list productions, update status, view purchase interests (accept/reject), view demand board.

## 8. Buyer features (existing as Business)

Browse/filter productions, express purchase interest, view own interests, demand list.

## 9. Bidding (existing)

**Not a real auction.** `PurchaseInterest` is a request-to-buy with accept/reject. No bid price, increment, countdown, or auto-close.

## 10. APIs (existing)

`/auth/*`, `/productions*`, `/demands*`, `/interests*`, `/analytics*` (government JWT), `/reference/*`

## 11. Dashboards (existing)

Farmer/business stat cards; government regional charts (mock + API aggregates).

## 12. Payments / orders

**None.** No order workflow, payments, receipts, or delivery.

## 13. Reusable components

`AppButton`, `AppTextField`, `StatCard`, `ProductionCard`, `DemandCard`, `InterestCard`, `RoleScaffold`, theme in `app_colors.dart`.

## 14. Limitations

- Flutter not wired to Nest by default (demo uses memory)
- No auctions, NIC, farm size, quality grade, listing codes
- No transportation, income impact, research metrics
- Government “analytics” used illustrative series; must be labeled DEMO vs TRANSACTION
- Buyer “verification” is just profile complete

## 15. Gaps filled by this enhancement

Smart farmer registration, listing IDs, real-time bidding engine, rule-based price recommendation (ML-ready), market intelligence, buyer matching, buyer verification, transport/net income, Farmer Income Impact Calculator, Intermediary Dependency Index, order/payment sandbox, quality grades, role dashboards, notifications, research data layer, audit logs, tests for calculations.

## Compatibility rules

- Keep `User`, `Production`, `DemandRequest`, `PurchaseInterest`
- Keep role enum values `business` and `government`
- Extend schema; do not drop working tables
- Demo/seed market prices are tagged `DEMO_SEED` — never presented as official Sri Lanka statistics
