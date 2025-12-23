# Warehouse Cycle Count Module - Requirements and Design

## 1. Purpose and scope

This document defines the requirements and design constraints for a warehouse cycle count module implemented as a web application. It covers Raw Goods, Production, and Finished Goods counting, guided task journals, automated recount workflows, transaction-aware variance review, role-based approvals, verified counter escalation, manual Excel imports for OnHand and Transactions, shift-based availability, and storage-aware retention.

### 1.1 Primary objectives
- Improve inventory accuracy while counting during live production operations.
- Minimize wasted recounts by using transaction-aware reconciliation and deterministic automation rules.
- Provide an operator-first guided experience that reduces cognitive load and preserves efficient routes.
- Ensure governance and segregation of duties (assignment vs approval vs verification).
- Operate with manual OnHand and Transaction import dumps while maintaining auditability.

### 1.2 Out of scope (v1)
- Direct integration to WMS/ERP APIs (v1 uses manual Excel imports).
- Real-time WMS hard locks on locations (v1 may implement soft 'Under Count' flags only).
- Warehouse-to-warehouse competition/leaderboards (foundation may exist but not required for v1).

## 2. Definitions and system concepts

### 2.1 Warehouses and product types
- **WarehouseType**: Rawgoods, Production, Finishedgoods.
- **ProductType examples**: Laptop, Server, Switches, Desktop, AIO (configurable list).
- **Finished Goods** are always serialized.
- **Raw Goods** may require serial capture depending on the part (RawGoodsSerialRequired flag in Item Master).

### 2.2 Counting attempts
- **Count 1**: Initial count submission by the assigned operator.
- **Count 2**: Automatic recount created and auto-assigned to a different eligible operator when Count 1 fails (non-Finishedgoods contexts).
- **Count 3 (Verified Count)**: Optional escalation count performed by a Verified Counter (Level 3 Lead+), initiated from the Raw Goods variance review screen.

### 2.3 Verified Counter
Verified Counter is a user certification (capability), not a role. Verified Counts are reserved for trusted Level 3 Lead+ counters.

- A Lead can assign/reassign work but cannot verify counts unless granted Verified Counter capability.
- Granting or revoking Verified Counter capability requires two management-chain sign-offs: IC Manager AND Warehouse Manager.
- Verified Counts can be assigned even if the Verified Counter already has other work, and may be cross-warehouse.

## 3. Roles, permissions, and governance

### 3.1 Roles
Roles define access to screens and actions. Verified Counter is a certification flag applied to users.

| Role | Primary responsibilities | Key constraints |
|------|-------------------------|-----------------|
| **Admin** | System configuration; user provisioning; master data maintenance | Cannot bypass dual-approval rules without auditable override |
| **IC Owner** | Inventory control ownership; policies; oversight | No implicit dual-approval bypass |
| **IC Manager** | Variance review; approvals; verified counter governance signoff | Dual approval required with Warehouse Manager for high-impact and verified counter certification |
| **Warehouse Manager** | Same functions as IC Manager/Super in this module; additional sign-off for high-impact items | Dual sign-off required with IC Manager for defined high-impact categories |
| **Warehouse Supervisor** | Operational oversight; assist assignment and queue management | Cannot grant Verified Counter; approval scope may be restricted by policy |
| **Lead** | Assign/reassign work; manage dispatch pool | Cannot verify counts unless certified (dual approval); cannot approve adjustments unless separately authorized |
| **Operator** | Execute guided journals; submit counts; capture serials; attach evidence when required | Sees only assigned work and required context |
| **Viewer** | Read-only access to dashboards/metrics | No write actions |

### 3.2 High-impact and dual approval
- For defined high-impact items (e.g., high-cost or ABC=A), approvals require IC Manager AND Warehouse Manager sign-off.
- Finishedgoods mismatches route to approval (no recount) and require location photo evidence.
- All approval decisions must be auditable (who, when, comments, decision).

## 4. Location model and routing

### 4.1 Canonical location structure
Locations follow the canonical schema: `Warehouse.Business.Aisle.Bay.PositionLevel`. 

**Example**: `Reimage.ARB.AB.01.01A`

### 4.2 Parsing and validation (hard rules)
- Exactly 5 dot-delimited segments.
- Bay is numeric (e.g., 01, 12).
- PositionLevel is digits followed by a single letter (e.g., 01A).
- Level letter normalized to uppercase.
- Invalid locations are rejected on import and routed to a data quality queue.

### 4.3 Guided route ordering (deterministic)
Default route sort order used to sequence journal lines:
1. Warehouse
2. Business
3. Aisle
4. BayNum (numeric)
5. PositionNum (numeric)
6. Level (letter)

Verified Count lines appended into an active journal must be appended at the end (highest sequence number).

## 5. Zones and journals

### 5.1 Zones
- Zones group locations for efficiency, planning, and assignment.
- Zones are a parameter for journal creation and operator access control.
- Zones can be used to generate journals in 30-line packets (configurable).

### 5.2 Task journals
- A journal is a guided work packet consisting of N location lines.
- Operator experience is guided and checkpointed; the system advances to the next incomplete line after submission.
- If an operator leaves mid-journal, the journal can be reassigned and resumed from the last incomplete line.
- A journal may be pooled (claim-based) or explicitly assigned.

### 5.3 Reassignment behavior
- If a journal is reassigned, completed lines remain completed.
- In-progress line claims time out; on timeout the line reverts to Unstarted unless submitted.
- Verified Count (Count 3) can be appended to the Verified Counter's current active journal, cross-warehouse, without blocking due to existing workload; it is appended to the end.

## 6. Counting workflows

### 6.1 Finishedgoods workflow (serialized; no recount)
- Finishedgoods are always serialized.
- If a Finishedgoods count does not match expected, a picture of the location label is required.
- No recount is created for Finishedgoods mismatches; the case routes to approval.
- Approval requires IC Manager or Warehouse Manager; dual approval for high-impact items.

### 6.2 Rawgoods/Production workflow (Count 1 -> Count 2 automation)
- If Count 1 fails (outside tolerance or serialized mismatch for RG serial-required parts), the system auto-creates Count 2 and auto-assigns it to another eligible operator with no interaction required.
- Auto-assignment selects only operators who are Present and Available.
- If no operator is available, the task enters the Dispatch Pool and generates an alert to Lead/Super/IC Manager/Warehouse Manager.

### 6.3 Raw Goods variance review screen (IC/Super/Manager)
The Raw Goods variance review grid must show, at minimum:
- Part Number (SKU)
- Expected Qty
- Count 1 value
- Count 2 value
- Delta: Expected vs Count 1
- Delta: Expected vs Count 2
- Delta: Count 1 vs Count 2

The screen must include an action: **Send to Verified Counter (Count 3)**.

### 6.4 Verified Count (Count 3) workflow
- Initiated from Raw Goods variance review screen by IC/Super/Manager based on configurable percent thresholds.
- Assigned only to users with Verified Counter certification.
- May be cross-warehouse relative to the counter's current journal.
- May be assigned even if the Verified Counter already has active work; the verified line is appended at the end of their current journal.

## 7. Transaction-aware variance review

### 7.1 Transaction types in scope
- Moves (move-in / move-out)
- Receipts / Putaway
- Picks / Issues to production
- Scrap
- Adjustments
- Serialized move visibility where applicable

### 7.2 Transaction reconciliation window (locked)
For variance review, the system must consider all transactions that occurred from when the count task/line was created (LineCreatedTimestamp / journal release timestamp) through the moment that specific line/location was submitted.

**Window**: `TxnTime` between `LineCreatedTimestamp` and `LineSubmitTimestamp`.

### 7.3 Reconciliation outputs retained long-term
- ExpectedQty (snapshot)
- NetMovementDuringWindow
- ReconciledExpectedQty
- UnexplainedDeltaQty
- ExplainedByTxn flag

## 8. Shifts, presence, and availability

### 8.1 Shift master
- The system stores shift definitions A/B/C including shift start/end, breaks, and lunches.
- Operators are mapped to shifts for planning and availability.
- Count windows may be aligned around shift change using stored shift definitions.

### 8.2 Availability rules (locked)
- Operators become Present/Available on daily sign-in or first action.
- Operators become Not Available on sign-out or inactivity timeout.
- Breaks: operators remain Available.
- Lunches: operators are Not Available (excluded from auto-assign).

### 8.3 Dispatch pool during lunch (locked)
- Tasks enter Dispatch Pool when no eligible operators are Present + Available.
- When an operator becomes Present + Available, the system immediately attempts dispatch assignment in priority order.
- If a task is assigned but not started and the assignee goes to lunch, it remains assigned but is blocked from new auto-assign until start-SLA escalation triggers (if configured).

## 9. SLA, risk locations, and compliance

### 9.1 SLA matrix
SLA cadence must be configurable by:
- ABC class (A/B/C)
- ProductType (Laptop/Server/Switches/Desktop/AIO/etc.)
- WarehouseType (Rawgoods/Production/Finishedgoods)

### 9.2 Risk locations
- Locations can be flagged as Risk Locations with structured reason + notes.
- Risk locations can have an SLA override: `FinalFrequencyDays = min(SLA frequency, RiskPolicy max frequency)`.
- Reporting must separate risk vs non-risk performance and variance trends.

## 10. Manual imports and data quality

### 10.1 OnHand import contract (Excel)
**Required headers (exact)**:
- AsOfTimestamp
- LocationCode
- PartNumber
- ExpectedQty

**Recommended**: Keep only columns required for the module; avoid importing unused fields to reduce storage and complexity.

### 10.2 Transaction import contract (Excel)
**Required headers (exact)**:
- TxnId
- TxnTime
- TxnType
- PartNumber
- Qty
- FromLocation
- ToLocation
- RefDoc

### 10.3 Validation rules (locked)
- Invalid LocationCode format is rejected and routed to Data Quality issues.
- Duplicate TxnId in the same batch is ignored and logged.
- Unknown SKU/ProductType/ABC/Cost may be imported but must create a Data Quality issue; adjustments should be blocked if cost is missing per policy.

## 11. Review cycles and retention

### 11.1 Review cycle definition (locked)
- **Weekdays (Mon-Fri)**: review period closes at end-of-day local time.
- **Weekends (Sat/Sun)** when operating: review period closes at 4:00 PM local time.
- Transactions are imported right before the variance review period.
- OnHand and Transactions are treated as current-cycle raw data only.

### 11.2 Current-only raw data retention (locked)
- Keep only the current OnHand snapshot lines and the current transaction batch in Postgres.
- After the review period closes, purge raw OnHand snapshot lines and raw transaction rows for that cycle.
- Retain long-term: plans/journals/lines, submissions (Count 1/2/3), approvals, audit log, and reconciliation summaries.
- Store ExpectedQtyAtCount and StandardCostAtCount on the journal line to preserve historical reporting after snapshot purge.

## 12. Notifications and alerting
- If a recount cannot be assigned due to no eligible operators available, create a Dispatch Pool record and a dispatch alert visible to Lead/Super/Managers.
- MVP notification channel: in-app alerts/queues (email/Teams optional later).

## 13. Reporting and dashboards
- SLA compliance by WarehouseType, ProductType, ABC, and Zone.
- Risk location compliance and variance trend (risk vs non-risk).
- Recount rates, explained-by-transaction rates, and time-to-close metrics.
- Verified Count volume and outcomes (Count 3).
- Operator productivity and throughput, with shift segmentation.

## 14. Technical requirements and recommended stack

### 14.0 Recommended technology stack

#### 14.0.1 Frontend stack
**Framework**: Next.js 14 (App Router)
- TypeScript for type safety
- React 18 for UI components
- App Router for file-based routing
- Server Components for performance

**Styling**: Tailwind CSS
- Utility-first CSS framework
- Responsive design (mobile-first)
- Optional: shadcn/ui for pre-built components

**Forms**: React Hook Form + Zod
- React Hook Form for form management
- Zod for type-safe validation
- Excellent performance and DX

**State Management**: Zustand + TanStack Query
- Zustand for client state (lightweight, simple)
- TanStack Query (React Query) for server state
- Minimal boilerplate

**Offline Support**: Progressive Web App (PWA)
- next-pwa for Service Worker
- IndexedDB (via idb library) for local storage
- Offline-first architecture
- Installable on mobile devices

**Additional Libraries**:
- Lucide React for icons
- react-webcam or @capacitor/camera for photo capture
- date-fns for date manipulation

#### 14.0.2 Backend stack
**Database & Backend**: Supabase
- PostgreSQL database (managed)
- Built-in authentication (Supabase Auth)
- Object storage (Supabase Storage) for photos/evidence
- Edge Functions (Deno runtime) for serverless functions
- Row-level security (RLS) for permissions
- Auto-generated REST API
- Real-time subscriptions (optional)

**Data Sync**: Supabase Edge Functions
- TypeScript-based serverless functions
- Scheduled via Supabase Cron
- Connects to SQL Server replication
- Syncs OnHand and Transaction data to Supabase
- Runs on schedule (hourly/daily)

#### 14.0.3 Hosting and deployment
**Frontend Hosting**: Vercel
- Zero-config deployment
- Automatic deployments from Git
- Edge network for global performance
- Free tier: Unlimited projects
- Paid tier: $20/month (if needed)

**Backend Hosting**: Supabase Cloud
- Managed PostgreSQL
- Managed storage
- Managed Edge Functions
- Free tier: 500MB database, 1GB storage, 50K MAU
- Paid tier: $25/month (if needed)

**Total Cost**: $0/month (free tier), scales to ~$45/month if needed

#### 14.0.4 Data integration
**SQL Server Replication Access**:
- Read-only connection to Microsoft SQL Server replication database
- Edge Functions query replication for OnHand and Transactions
- Scheduled sync jobs (hourly/daily)
- Data flows: SQL Server → Supabase → Flutter App

**Connection Method**:
- Use `mssql` or `tedious` npm package in Edge Functions
- Connection string with read-only credentials
- Query OnHand snapshots and transaction history
- Upsert into Supabase PostgreSQL

#### 14.0.5 Development tools
**Package Manager**: npm or pnpm
**Version Control**: Git + GitHub
**Type Checking**: TypeScript (strict mode)
**Linting**: ESLint + Prettier
**Database Migrations**: Supabase CLI
**Local Development**: 
- Next.js dev server (localhost:3000)
- Supabase local instance (optional) or cloud
- Hot reload enabled

#### 14.0.6 Project structure
```
cycle-count-app/
├── app/                          # Next.js App Router
│   ├── (auth)/                   # Auth routes
│   ├── (operator)/               # Operator routes
│   ├── (manager)/                # Manager routes
│   ├── (admin)/                  # Admin routes
│   └── api/                      # API routes
├── components/                   # React components
│   ├── ui/                       # Reusable UI
│   ├── forms/                    # Form components
│   └── layouts/                  # Layouts
├── lib/                          # Utilities
│   ├── supabase/                 # Supabase client
│   ├── sql-server/               # SQL Server utils
│   ├── hooks/                    # Custom hooks
│   └── utils/                    # Helpers
├── supabase/
│   ├── functions/                # Edge Functions
│   │   ├── sync-onhand/
│   │   └── sync-transactions/
│   └── migrations/               # DB migrations
├── store/                        # Zustand stores
├── types/                        # TypeScript types
└── public/
    └── manifest.json             # PWA manifest
```

#### 14.0.7 Key packages
| Package | Purpose | Version |
|---------|---------|---------|
| next | Framework | ^14.0.0 |
| react | UI library | ^18.0.0 |
| @supabase/supabase-js | Supabase client | ^2.38.0 |
| @supabase/ssr | Supabase SSR | ^0.0.10 |
| zustand | State management | ^4.4.0 |
| @tanstack/react-query | Server state | ^5.0.0 |
| react-hook-form | Forms | ^7.48.0 |
| zod | Validation | ^3.22.0 |
| tailwindcss | Styling | ^3.3.0 |
| next-pwa | PWA support | ^5.6.0 |
| idb | IndexedDB | ^8.0.0 |
| lucide-react | Icons | ^0.290.0 |
| mssql | SQL Server client | ^10.0.0 |

#### 14.0.8 Quick start commands
```bash
# 1. Create Next.js app
npx create-next-app@latest cycle-count-app --typescript --tailwind --app

# 2. Install core dependencies
cd cycle-count-app
npm install @supabase/supabase-js @supabase/ssr
npm install zustand @tanstack/react-query
npm install react-hook-form zod
npm install next-pwa idb
npm install lucide-react
npm install mssql  # for SQL Server connection

# 3. Setup Supabase
npm install supabase --save-dev
npx supabase init
npx supabase start  # for local dev

# 4. Deploy to Vercel
npm install -g vercel
vercel
```

#### 14.0.9 Architecture overview
```
┌─────────────────┐
│   Flutter App   │  (Next.js PWA)
│   (Mobile/Web)  │
└────────┬────────┘
         │
         │ HTTPS
         │
┌────────▼────────┐
│    Supabase     │
│  - PostgreSQL   │
│  - Auth         │
│  - Storage      │
│  - Edge Funcs   │
└────────┬────────┘
         │
         │ Scheduled Sync
         │
┌────────▼────────┐
│  SQL Server     │
│  Replication    │
│  (Read-only)    │
└─────────────────┘
```

**Data Flow**:
1. SQL Server replication → Edge Function (scheduled)
2. Edge Function → Supabase PostgreSQL (sync)
3. Supabase → Next.js App (API calls)
4. Next.js App → User (rendered UI)
5. User actions → Supabase (writes)
6. Supabase → Export to Plus ERP (adjustments)

### 14.1 Security model
- Authentication via Supabase Auth.
- Row-level security (RLS) enforces org boundaries and role-based access.
- Operators see only assigned journals/lines and their own submissions; leads manage assignment/dispatch but cannot verify unless certified; managers handle approvals and governance.
- All key actions write to an append-only audit log.

### 14.2 Background jobs
- Auto-close review cycles at the configured cutoff times (weekday EOD; weekend 4 PM).
- Purge raw OnHand/Transaction rows immediately after cycle close (or via scheduled job).
- Optional: periodic inactivity check to set operators Not Available.

### 14.3 Evidence storage
- Finishedgoods mismatch requires a location photo before submission is accepted.
- Evidence stored in object storage; database stores a reference path and metadata.

## 15. Configurable settings (admin UI)
These are required configuration values and are not hard-coded in application logic:
- Variance percent thresholds (expected vs count; count1 vs count2 disagreement).
- High-impact definitions (ABC=A and/or cost threshold) for dual approval gating.
- Shift definitions (A/B/C) and lunch/break windows.
- Journal size defaults (e.g., 30 lines) and claim timeout values.
- Risk reason list and risk policy overrides.

## 16. MVP delivery plan
1. Auth + org boundary + roles + verified counter governance workflow
2. Master data: locations (with parsing), zones, items
3. Manual imports: OnHand snapshot + Transactions batch; binding to daily ReviewCycle
4. Plans/journals/lines + operator guided runner + checkpointing
5. Auto Count 2 (recount) + dispatch pool + lunch rules
6. Raw Goods variance review grid + Send to Verified Counter (Count 3 append-to-end)
7. Finishedgoods mismatch evidence + approval queue + dual approvals for high-impact
8. Dashboards + audit exports + retention purge job

## 17. Application screens and user flows

### 17.1 Authentication and common screens

#### 17.1.1 Login/Sign-in screen
**Access**: All users (unauthenticated)
**Purpose**: User authentication and daily sign-in
**Key elements**:
- Username/email input
- Password input
- "Sign in" button
- Forgot password link
- Remember device option (optional)

**User flow**:
1. User enters credentials
2. System authenticates via Supabase Auth
3. On successful login:
   - Operator: Sets status to "Present/Available" (Section 8.2)
   - All users: Redirects to role-appropriate home screen

#### 17.1.2 Sign-out screen
**Access**: All authenticated users
**Purpose**: End session and update availability
**Key elements**:
- Confirmation dialog
- "Sign out" button
- Cancel option

**User flow**:
1. User taps sign-out
2. System sets operator status to "Not Available" (if operator)
3. Clears session
4. Redirects to login

---

### 17.2 Operator screens and flows

#### 17.2.1 Operator home/dashboard
**Access**: Operator role
**Purpose**: View assigned work and start counting
**Key elements**:
- Active journal card (if assigned)
  - Journal ID, zone, total lines, completed lines, progress bar
  - "Continue Journal" button
- Available journals pool (if claim-based assignment)
  - List of unclaimed journals
  - "Claim Journal" button
- Status indicator: Present/Available, On Break, On Lunch
- Quick stats: Today's counts completed, accuracy rate

**User flow**:
1. Operator signs in → lands here
2. If active journal exists: "Continue Journal" → Journal detail screen
3. If no active journal: View available pool → Claim journal → Journal detail screen
4. If no work available: "No work assigned" message

#### 17.2.2 Journal detail screen
**Access**: Operator (assigned journal)
**Purpose**: View journal progress and navigate to count lines
**Key elements**:
- Journal header: ID, zone, warehouse, assigned date
- Progress indicator: "X of Y lines completed"
- List of journal lines:
  - Location code
  - Part number
  - Expected qty
  - Status badge: Unstarted, In Progress, Completed, Needs Recount
- "Start Next Line" button (auto-advances to first incomplete)
- "Resume Line" button (if line was in progress)

**User flow**:
1. From home → Journal detail
2. Tap "Start Next Line" → Count screen (next incomplete line)
3. Or tap specific line → Count screen (that line)
4. After count submission → Returns here, shows updated status

#### 17.2.3 Count screen (primary counting interface)
**Access**: Operator (assigned line)
**Purpose**: Execute count for a location
**Key elements**:
- Location header: Full location code (e.g., "Reimage.ARB.AB.01.01A")
- Part information: Part number, description, expected qty
- Count input: Numeric input field (keyboard optimized for numbers)
- Serial capture section (if required):
  - Serial input field with barcode scanner option
  - List of captured serials (add/remove)
  - "Scan Serial" button
- Warehouse type indicator: Rawgoods / Production / Finishedgoods
- Photo capture (if Finishedgoods mismatch):
  - Camera button
  - Preview of captured photo
  - "Retake" option
- "Submit Count" button (disabled until requirements met)
- "Cancel" button (returns to journal, line remains in progress)

**User flow - Rawgoods/Production**:
1. Operator arrives at location
2. Scans location barcode (or manually enters)
3. System validates location matches journal line
4. Operator counts physical quantity
5. Enters count value
6. If serial required: Captures serials (scan or manual)
7. Taps "Submit Count"
8. System validates:
   - If within tolerance → Line marked complete, advances to next
   - If outside tolerance → Auto-creates Count 2, line marked "Needs Recount", advances to next
9. Returns to journal detail

**User flow - Finishedgoods**:
1. Operator arrives at location
2. Scans location barcode
3. Counts serialized items
4. Scans/enters each serial number
5. If count matches expected → Submit (no photo needed)
6. If count doesn't match → System requires location photo
7. Operator captures photo of location label
8. Taps "Submit Count"
9. System routes to approval (no recount)
10. Returns to journal detail

#### 17.2.4 Serial capture screen
**Access**: Operator (when serial required)
**Purpose**: Capture and manage serial numbers
**Key elements**:
- Part number and expected serial count
- Barcode scanner interface (camera view)
- Manual serial input field
- List of captured serials:
  - Serial number
  - Timestamp
  - "Remove" button
- "Add Serial" button
- "Done" button (returns to count screen)
- Validation: Shows if count matches expected

**User flow**:
1. From count screen → Serial capture
2. Scan serial barcode OR manually enter
3. Serial added to list
4. Repeat until all serials captured
5. System validates count matches expected
6. "Done" → Returns to count screen

#### 17.2.5 Photo capture screen
**Access**: Operator (Finishedgoods mismatch only)
**Purpose**: Capture location label photo as evidence
**Key elements**:
- Camera viewfinder
- "Capture Photo" button
- Photo preview (after capture)
- "Retake" button
- "Use Photo" button (confirms and returns)
- Instructions: "Capture photo of location label"

**User flow**:
1. From count screen (mismatch detected) → Photo capture required
2. Operator positions camera on location label
3. Taps "Capture Photo"
4. Reviews preview
5. "Use Photo" → Photo attached, returns to count screen
6. Or "Retake" → New capture

---

### 17.3 Lead screens and flows

#### 17.3.1 Lead dashboard
**Access**: Lead role
**Purpose**: Overview of work assignment and dispatch pool
**Key elements**:
- Dispatch pool alert badge (count of unassigned tasks)
- Active operators list:
  - Operator name, current journal, status (Available/On Break/On Lunch)
  - "View Details" button
- Pending assignments: Journals waiting for operator
- Quick actions:
  - "Manage Dispatch Pool"
  - "Assign Work"
  - "View Operator Status"

**User flow**:
1. Lead signs in → Dashboard
2. Sees dispatch pool alerts
3. Navigates to dispatch pool or assignment screens

#### 17.3.2 Dispatch pool screen
**Access**: Lead, Supervisor, IC Manager, Warehouse Manager
**Purpose**: View and assign unassigned recount tasks
**Key elements**:
- List of tasks in dispatch pool:
  - Location, part number, count type (Count 2)
  - Time in pool, priority
  - "Assign" button
- Available operators filter:
  - Show only Present + Available operators
  - Operator name, current workload, zone
- "Auto-assign" button (system selects best operator)
- Assignment dialog:
  - Select operator dropdown
  - "Assign" button
  - "Cancel" button

**User flow**:
1. Lead views dispatch pool
2. Sees unassigned Count 2 tasks
3. Selects task
4. Views available operators
5. Assigns to operator OR uses auto-assign
6. Task removed from pool, assigned to operator

#### 17.3.3 Journal assignment screen
**Access**: Lead, Supervisor
**Purpose**: Assign or reassign journals to operators
**Key elements**:
- Available journals list:
  - Journal ID, zone, line count, created date
  - "Assign" button
- Operators list:
  - Name, status, current journal (if any), zone
- Assignment dialog:
  - Journal details
  - Operator selector
  - "Assign" or "Reassign" button
- Reassignment option:
  - Shows current assignee
  - "Reassign to..." option

**User flow**:
1. Lead views available journals
2. Selects journal
3. Chooses operator from list
4. Confirms assignment
5. Journal assigned, operator notified (in-app)

#### 17.3.4 Operator status screen
**Access**: Lead, Supervisor
**Purpose**: View operator availability and workload
**Key elements**:
- Operator list with status:
  - Name, shift, status (Present/Available, On Break, On Lunch, Not Available)
  - Current journal (if any), lines completed today
  - "View Details" button
- Filter options: Status, shift, zone
- Manual status override (if needed):
  - "Set Available" / "Set On Break" / "Set On Lunch"

**User flow**:
1. Lead views operator status
2. Sees who's available for assignment
3. Can manually adjust status if needed (with audit log)

---

### 17.4 Manager screens and flows (IC Manager, Warehouse Manager, Supervisor)

#### 17.4.1 Manager dashboard
**Access**: IC Manager, Warehouse Manager, Supervisor
**Purpose**: Overview of cycle count operations and pending actions
**Key elements**:
- Pending approvals badge (count)
- Variance review queue badge (count)
- Today's metrics:
  - Total counts, completed, in progress
  - Variance rate, recount rate
- Quick actions:
  - "Review Variances"
  - "Approval Queue"
  - "View Reports"

**User flow**:
1. Manager signs in → Dashboard
2. Sees pending actions
3. Navigates to variance review or approval queue

#### 17.4.2 Raw Goods variance review screen
**Access**: IC Manager, Warehouse Manager, Supervisor
**Purpose**: Review count discrepancies and transaction reconciliation
**Key elements**:
- Variance grid (table):
  - Columns: Part Number, Location, Expected Qty, Count 1, Count 2, Delta (Expected vs Count 1), Delta (Expected vs Count 2), Delta (Count 1 vs Count 2), Status
  - Sortable columns
  - Filter options: Warehouse, zone, date range, status
- Transaction reconciliation panel (when row selected):
  - Shows transactions during count window
  - Net movement calculation
  - Reconciled expected qty
  - Unexplained delta
  - "Explained by Transactions" flag
- Actions per row:
  - "View Details" (expands reconciliation)
  - "Send to Verified Counter" (Count 3)
  - "Approve Adjustment" (if within authority)
  - "Request Investigation"
- Bulk actions:
  - "Approve Selected" (if all explained by transactions)
  - "Export to Excel"

**User flow**:
1. Manager opens variance review
2. Views grid of discrepancies
3. Selects row → Sees transaction reconciliation
4. Decision:
   - If explained by transactions → Approve (no adjustment)
   - If unexplained → Send to Verified Counter OR Approve adjustment
   - If high-impact → Requires dual approval
5. Action taken, audit logged

#### 17.4.3 Approval queue screen
**Access**: IC Manager, Warehouse Manager
**Purpose**: Review and approve adjustments (especially Finishedgoods)
**Key elements**:
- Approval queue list:
  - Part number, location, expected, count, delta
  - Warehouse type (Finishedgoods highlighted)
  - Photo thumbnail (if Finishedgoods)
  - Requested by, date
  - "Approve" / "Reject" buttons
- Detail view (when item selected):
  - Full count details
  - Photo viewer (if applicable)
  - Transaction history
  - Comments section
  - Approval decision:
    - "Approve" button
    - "Reject" button (with reason required)
    - Comment field
- Dual approval indicator:
  - Shows if high-impact item
  - Shows other approver status (if dual required)
  - "Pending IC Manager" / "Pending Warehouse Manager" badges

**User flow - Single approval**:
1. Manager views approval queue
2. Selects item
3. Reviews details and photo (if Finishedgoods)
4. Enters comment
5. Approves or rejects
6. Item removed from queue, adjustment processed

**User flow - Dual approval (high-impact)**:
1. IC Manager views approval queue
2. Selects high-impact item
3. Reviews and approves
4. Item shows "Pending Warehouse Manager"
5. Warehouse Manager views queue
6. Sees item with IC Manager's approval
7. Reviews and approves
8. Both approvals complete → Adjustment processed

#### 17.4.4 Verified Counter management screen
**Access**: IC Manager, Warehouse Manager (dual approval required)
**Purpose**: Grant or revoke Verified Counter certification
**Key elements**:
- Users list with Verified Counter status:
  - Name, role, current certification status
  - "Grant" / "Revoke" button
- Certification request workflow:
  - Select user
  - "Request Certification" button
  - Requires both IC Manager AND Warehouse Manager approval
- Pending requests:
  - Shows requests awaiting second approval
  - "Approve" / "Reject" buttons
- Audit log: History of certification changes

**User flow**:
1. IC Manager requests Verified Counter for user
2. System creates pending request
3. Warehouse Manager sees request
4. Both approve → Certification granted
5. User can now receive Count 3 assignments

---

### 17.5 Admin screens and flows

#### 17.5.1 Admin dashboard
**Access**: Admin role
**Purpose**: System configuration and master data management
**Key elements**:
- Navigation to:
  - Master data management
  - Import screens
  - User management
  - Configuration settings
  - Data quality issues
- System status:
  - Last import time, data quality issues count
  - Active review cycle status

#### 17.5.2 Master data management screens

##### 17.5.2.1 Locations management
**Access**: Admin
**Purpose**: View and manage location master data
**Key elements**:
- Locations list/grid:
  - Location code, warehouse, zone, risk flag
  - "Edit" / "Delete" buttons
- Add/Edit location form:
  - Location code (validated per Section 4.2)
  - Warehouse, Business, Aisle, Bay, PositionLevel
  - Zone assignment
  - Risk location flag (with reason)
- Import locations (bulk):
  - File upload
  - Validation results
  - Data quality issues queue

##### 17.5.2.2 Zones management
**Access**: Admin
**Purpose**: Create and manage zones
**Key elements**:
- Zones list:
  - Zone code, name, description, warehouse
  - "Edit" / "Delete" buttons
- Add/Edit zone form:
  - Zone code, name, description
  - Warehouse assignment
  - Journal size default (e.g., 30 lines)

##### 17.5.2.3 Items/Products management
**Access**: Admin
**Purpose**: View and manage item master data
**Key elements**:
- Items list:
  - Part number, description, product type, ABC class, cost
  - Serial required flag (Raw Goods)
  - "Edit" button
- Add/Edit item form:
  - Part number, description
  - Product type, ABC class
  - Standard cost
  - Warehouse type
  - RawGoodsSerialRequired flag
- Import items (bulk):
  - File upload
  - Validation and data quality checks

#### 17.5.3 Import screens

##### 17.5.3.1 OnHand import screen
**Access**: Admin, IC Manager
**Purpose**: Import OnHand snapshot from Plus ERP (or SQL replication)
**Key elements**:
- Import method selector:
  - "Upload Excel File" (manual)
  - "Query SQL Replication" (automated, if available)
- Excel upload:
  - File picker
  - Column mapping (if headers don't match exactly)
  - "Import" button
- SQL query (if automated):
  - Query preview
  - "Run Import" button
  - Schedule option (daily, hourly)
- Import results:
  - Success count, error count
  - Data quality issues list
  - "View Issues" button

**User flow**:
1. Admin uploads Excel OR runs SQL query
2. System validates headers (Section 10.1)
3. Validates location codes (Section 4.2)
4. Imports valid records
5. Routes invalid records to data quality queue
6. Shows results summary

##### 17.5.3.2 Transaction import screen
**Access**: Admin, IC Manager
**Purpose**: Import transaction history from Plus ERP
**Key elements**:
- Import method (same as OnHand)
- Date range selector (for SQL query)
- Import results with validation
- Data quality issues

**User flow**: Similar to OnHand import

#### 17.5.4 Configuration settings screen
**Access**: Admin
**Purpose**: Configure system parameters (Section 15)
**Key elements**:
- Settings categories:
  - **Variance thresholds**:
    - Expected vs count tolerance (%)
    - Count 1 vs Count 2 disagreement threshold
  - **High-impact definitions**:
    - ABC class (A/B/C)
    - Cost threshold
  - **Shift definitions**:
    - Shift A/B/C times
    - Break windows
    - Lunch windows
  - **Journal settings**:
    - Default journal size (lines)
    - Claim timeout (minutes)
  - **Risk location policy**:
    - Risk reason list
    - Max frequency override
- Save/Cancel buttons
- Audit log: Shows who changed what and when

#### 17.5.5 User management screen
**Access**: Admin
**Purpose**: Create users and assign roles
**Key elements**:
- Users list:
  - Name, email, role, verified counter status, active
  - "Edit" / "Deactivate" buttons
- Add/Edit user form:
  - Name, email
  - Role selector (Section 3.1)
  - Verified Counter checkbox (requires dual approval)
  - Shift assignment
  - Zone access (if restricted)
- Role permissions preview (read-only)

#### 17.5.6 Data quality issues screen
**Access**: Admin, IC Manager
**Purpose**: Review and resolve data quality problems from imports
**Key elements**:
- Issues list:
  - Issue type (Invalid location, Unknown SKU, Missing cost, etc.)
  - Record details
  - Source (OnHand import, Transaction import)
  - Date created
  - "Resolve" / "Ignore" buttons
- Filter options: Issue type, source, date
- Bulk actions: "Resolve Selected" / "Ignore Selected"

---

### 17.6 Viewer screens

#### 17.6.1 Viewer dashboard
**Access**: Viewer role
**Purpose**: Read-only access to reports and metrics
**Key elements**:
- Key metrics cards:
  - SLA compliance rate
  - Variance rate
  - Recount rate
  - Operator productivity
- Report links:
  - SLA compliance report
  - Variance trends
  - Operator performance
  - Risk location analysis
- No action buttons (read-only)

#### 17.6.2 Reports and dashboards
**Access**: Viewer, Managers, Admins (with write access to export)
**Purpose**: View analytics and export data
**Key elements**:
- **SLA compliance report**:
  - By warehouse type, product type, ABC class, zone
  - Compliance percentage, overdue counts
  - Filterable, exportable
- **Variance analysis**:
  - Variance trends (risk vs non-risk)
  - Explained-by-transaction rate
  - Time-to-close metrics
- **Operator productivity**:
  - Counts per operator, per shift
  - Accuracy rates
  - Throughput metrics
- **Verified Count outcomes**:
  - Count 3 volume and resolution rates
- Export options: Excel, PDF, CSV

---

### 17.7 Core user flows summary

#### Flow 1: Operator counting workflow
1. Login → Operator home
2. View assigned journal → Journal detail
3. Start next line → Count screen
4. Count location → Submit
5. If variance → Auto Count 2 created (operator doesn't see this)
6. Continue to next line → Repeat
7. Complete journal → Return to home

#### Flow 2: Recount workflow (Count 2)
1. Count 1 fails → System auto-creates Count 2
2. System auto-assigns to different operator (if available)
3. If no operator available → Enters dispatch pool
4. Lead views dispatch pool → Assigns to operator
5. Operator receives Count 2 task → Counts location
6. Result → Routes to variance review

#### Flow 3: Variance review and approval
1. Manager views variance review screen
2. Selects variance → Views transaction reconciliation
3. Decision:
   - Explained by transactions → Approve (no adjustment)
   - Unexplained, low value → Approve adjustment
   - Unexplained, high value → Send to Verified Counter
4. If Verified Counter → Count 3 performed
5. Final decision → Adjustment exported to Plus

#### Flow 4: Finishedgoods mismatch
1. Operator counts Finishedgoods → Mismatch detected
2. System requires location photo
3. Operator captures photo → Submits
4. Routes to approval queue (no recount)
5. Manager reviews → Approves or rejects
6. If high-impact → Dual approval required
7. Adjustment processed

#### Flow 5: Daily data import
1. Admin runs OnHand import (SQL query or Excel)
2. System validates and imports
3. Admin runs Transaction import
4. System creates cycle count plan based on SLA
5. System generates journals
6. Journals assigned to operators (auto or manual)
7. Operators begin counting

---

*End of document*
