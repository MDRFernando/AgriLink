# AgriLink — Unified Multi-Role Agricultural Dashboard

An elegant, fully-responsive Next.js 16 (React 19 + Tailwind CSS v4) agricultural marketplace and intelligence dashboard built for Sri Lanka's **AgriLink** platform.

This dashboard operates entirely on realistic in-memory test data (no external API calls or database connections required during testing phase).

---

## 👥 Supported Roles

The dashboard features an instant role switcher in the header to preview and interact as:

1. **🌾 Farmer (`farmer`)**
   * **Live Auctions & Wholesale Bids**: Real-time buyer bids with accept/audit actions and soft-close countdowns.
   * **Produce Batch Inventory**: Graded batches (Grade A, B, C) with harvest dates, reserve prices, and stage tracking.
   * **Seasonal Crop Planning**: Maha / Yala cultivation plans, target acreage, and yield forecasts.
   * **Interactive Income Calculator**: Dynamic slider calculating net profit gain vs traditional middleman deductions.

2. **🏢 Wholesale Buyer (`buyer`)**
   * **Produce Marketplace**: Real-time filtering by commodity, district, and quality grade.
   * **Live Bidding Desk**: Place bids with increment controls and soft-close auto-extension.
   * **Sourcing Demands Board**: Track forward contract fulfillment progress against targets.
   * **Order Waybill Tracking**: Farmgate pickup to wholesale distribution center tracking.

3. **🚚 Logistics Transporter (`transporter`)**
   * **Freight Marketplace**: Accept farmgate cargo requests with vehicle type and payout details.
   * **Waybill Dispatch Stepper**: Advance trip status from `assigned` → `arrived_at_pickup` → `loaded` → `in_transit` → `delivered` → `buyer_confirmed`.
   * **OTP Delivery Proof**: Cryptographic delivery verification code for cargo sign-off.
   * **Fleet Management**: Live tracking of vehicle statuses, capacities, and fuel efficiencies.

4. **🏛️ Government / Admin Officer (`government`)**
   * **National Agro Observatory**: Macro indicators, cultivation acreage, and Intermediary Dependency Index.
   * **Visual District Supply & Demand Equilibrium**: Dual-bar comparison of harvest yields vs market demand.
   * **7-Day Price Discovery Chart**: Interactive SVG price movement curves for key commodities.
   * **KYC & Verification Desk**: Review and approve wholesale buyer and freight carrier credentials.

---

## 🚀 Running the Dashboard

```bash
cd dashboard
bun run dev
```

Open [http://localhost:3000](http://localhost:3000) in your browser.
