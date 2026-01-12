# DEV REQUIREMENT #1: Create RMAVENDOR Role & Vendor Assignment - RMA Entry Screen

**Title:** Create RMAVENDOR Role and Vendor Assignment System for RMA Entry Screen

**Background:**
- Program: 10068 (ADT)
- Need to create new role: `RMAVENDOR`
- RMAVENDOR users will be able to:
  - View RMA Entry screen (filtered to their vendor only)
  - Edit RMA tickets (for their vendor only)
  - Approve RMA tickets (for their vendor only)
  - Give credit back once received on their end
- Need to link RMAVENDOR users to specific vendors

**Requirements:**

## 1. Create New Role

- Create role: `RMAVENDOR` for Program 10068
- Define role permissions:
  - Access to RMA Entry screen
  - Edit RMA tickets (vendor-scoped)
  - Approve RMA tickets (vendor-scoped)
  - Give credit back (vendor-scoped)
- Add role to role management system

## 2. Automatic Vendor Access via Email Matching

**Priority:** This automatic assignment takes precedence over manual assignment in user management.

### Logic
- When a user logs in, check if their email address matches any "Request" contact email in VENDOR_CONTACTS table
- Query: `SELECT C01 AS Vendor FROM Plus.pls.CodeGenericTable WHERE GenericTableDefinitionID = 245 AND UPPER(LTRIM(RTRIM(C02))) = UPPER(@UserEmail) AND UPPER(LTRIM(RTRIM(C03))) = 'REQUEST'`
- If match found:
  - Automatically grant user RMAVENDOR role access (if not already assigned)
  - Automatically assign matched vendor to user
  - User can immediately access RMA Entry screen with vendor filtering applied
- If no match found:
  - User must be manually assigned via user management (see section 3)

### Benefits
- Vendors can access system immediately without admin intervention
- No manual user management required for vendor contacts
- Self-service access based on email in VENDOR_CONTACTS table

### Implementation Notes
- Email matching should be case-insensitive and trim whitespace
- If user email matches multiple vendors, use most recent contact (by LastActivityDate DESC, ID DESC)
- Automatic assignment should be checked on every login/session start
- Manual assignment in user management can override automatic assignment if needed

## 3. User Management Enhancement (Manual Assignment)

- Add "Assigned Vendor" field/dropdown to user management page
- Show/apply to users with role: `RMAVENDOR` (Program 10068)
- Dropdown populated from **VENDOR_CONTACTS** table (distinct vendor names from C01)
- Optional field (automatic assignment via email matching is preferred)
- Store assignment (UserAttribute, User table, or appropriate location)
- **Note:** Manual assignment can override automatic email-based assignment

## 4. RMA Entry Screen Filtering

- Query checks user's role and assigned vendor
- **For RMAVENDOR users with assigned vendor:**
  - Filter: `WHERE vlm.Vendor = @UserAssignedVendor`
  - Show only their vendor's parts/locations/data
  - Hide vendor column (they only see their own)
- **For internal users (non-RMAVENDOR):**
  - No filter (show all vendors, all locations, all parts)
  - Show all columns including vendor assignments

## 5. Query Logic

- Get user's role and assigned vendor from user management
- Apply conditional WHERE clause in `RMAVendorLocations` query:
  ```sql
  AND (
      @UserRole != 'RMAVENDOR'  -- Internal users see all
      OR vlm.Vendor = @UserAssignedVendor  -- RMAVENDOR users see only their vendor
  )
  ```

**Acceptance Criteria:**
- [ ] RMAVENDOR role created in system (Program 10068)
- [ ] Role permissions defined and configured
- [ ] **Automatic vendor access works:**
  - [ ] User email matches VENDOR_CONTACTS "Request" email → automatically gets RMAVENDOR access
  - [ ] Automatic assignment checked on login/session start
  - [ ] Email matching is case-insensitive with whitespace trimming
  - [ ] If multiple matches, most recent contact is used
- [ ] **Manual assignment (user management):**
  - [ ] User management shows "Assigned Vendor" field for RMAVENDOR role users
  - [ ] Vendor dropdown populated from VENDOR_CONTACTS table (C01)
  - [ ] Can manually assign vendor to user (optional, can override automatic)
- [ ] RMA Entry screen filters data based on vendor assignment (automatic or manual)
- [ ] RMAVENDOR users see only their assigned vendor's data
- [ ] Internal users (non-RMAVENDOR) see all data

**Technical Implementation:**

### Automatic Vendor Access
1. On user login/session start:
   - Get user's email address from user record
   - Query VENDOR_CONTACTS table:
     ```sql
     SELECT TOP 1 C01 AS Vendor
     FROM Plus.pls.CodeGenericTable
     WHERE GenericTableDefinitionID = 245  -- VENDOR_CONTACTS
       AND UPPER(LTRIM(RTRIM(C02))) = UPPER(@UserEmail)  -- Email match (case-insensitive)
       AND UPPER(LTRIM(RTRIM(C03))) = 'REQUEST'  -- Request contact type
     ORDER BY LastActivityDate DESC, ID DESC  -- Most recent if multiple
     ```
   - If vendor found:
     - Assign RMAVENDOR role to user (if not already assigned)
     - Set user's assigned vendor to matched vendor
     - Store assignment (UserAttribute, User table, or appropriate location)

### Manual Assignment
- Create RMAVENDOR role in role management system
- Add vendor assignment capability to user management (dropdown from VENDOR_CONTACTS.C01)
- Manual assignment can override automatic assignment

### Query Filtering
- Modify `RMAVendorLocations` query to accept `@UserID` or `@UserEmail` parameter
- Lookup user's role and assigned vendor (check both automatic and manual assignment)
- Apply conditional filtering based on role and vendor assignment:
  ```sql
  AND (
      @UserRole != 'RMAVENDOR'  -- Internal users see all
      OR vlm.Vendor = @UserAssignedVendor  -- RMAVENDOR users see only their vendor
  )
  ```

