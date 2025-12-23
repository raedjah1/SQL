# Cycle Count Approval - Requirements Document

## Background
I've been reviewing the cycle count approval process and comparing what we have today vs what operations needs. There are some significant gaps in the current implementation, especially around location tracking. This doc outlines what's missing and my recommendations for fixing it.

---

## Current State Analysis

### What Works Today
The system handles basic quantity adjustments fine - if you count 10 but system has 12, it can add or remove. It tracks iterations (1st count vs 2nd count) and validates serial numbers. The Match/Excess/Short logic works but it's only looking at quantity, not location.

### What's Missing
The big gap is location tracking. Right now if a part is supposed to be in location A but was counted in location B, the system has no idea. It only cares about quantity differences. We need to add location comparison and mismatch handling.

---

## Required Scenarios & Implementation

### Scenario 1: Location Mismatch Detection

**The Problem:**
Right now, if a part is supposed to be in ARB.0.0.0 but was counted in ARB.1.1.1, the system has no way to know this. It only checks if the quantity matches.

**What We Need:**
1. A field where users can enter where they actually found the part ("Location Counted")
2. A way to compare system location vs counted location
3. Display "Location Match" as YES or NO

**Implementation:**
- Add new field C15 = "Location Counted" (text input)
- Display system location from PartSerial.LocationID as "PLUS Location" (read-only)
- Calculate Location Match: if PLUS Location = Location Counted then YES, else NO
- Show this comparison on the approval screen

**Code Changes:**
- Add C15 to the InputFields list (line 2 in the script)
- Need calculation to compare system location vs C15
- Screen needs to show both locations so users can see the mismatch

---

### Scenario 2: 2nd Count Workflow

**The Problem:**
When a location mismatch happens on 1st count, we need a 2nd count. But the system doesn't preserve what was counted in the 1st count, so the 2nd count screen has no context.

**What We Need:**
1. A checkbox to flag parts needing 2nd count
2. Store the 1st count location data
3. Display 1st count result on 2nd count screen

**Implementation:**
- Add checkbox field C16 = "Needs 2nd Count" (only show on iteration 1)
- When approved on 1st count with mismatch, save Location Counted to new column `FirstCountLocation` in CycleCountTaskSerialNo table
- On iteration 2, query and display FirstCountLocation in "First Count Result" column
- Hide "Needs 2nd Count" column on 2nd count (not needed anymore)

**Database Changes:**
Need to add two columns to CycleCountTaskSerialNo:
- `FirstCountLocation` VARCHAR - stores where it was found on 1st count
- `NeedsSecondCount` BIT - flag for 2nd count

**Code Changes:**
When user approves on 1st count and C16 is checked, save C15 value to FirstCountLocation. Then on iteration 2, pull that value back and show it. Also need to hide C16 field when iteration = 2.

---

### Scenario 3: Auto-Drop Matching Parts

**The Problem:**
If a part matches (system location = counted location), it still stays in the approval queue even though no adjustment is needed. This creates unnecessary work.

**What We Need:**
- When Location Match = YES and user approves, automatically mark as verified
- Remove from approval queue
- Don't create any PartTransaction (nothing to adjust)

**Implementation:**
- In the approval logic, check Location Match before processing
- If Location Match = YES, update CycleCountTaskSerialNo status to 'VERIFIED'
- Skip PartTransaction creation
- Filter approval queue to exclude VERIFIED status

**Code Changes:**
In the approval logic (ExecuteQuery section), before creating PartTransaction, check if Location Match = YES. If yes, just update the status to VERIFIED and skip the transaction. Also need to make sure the approval queue query filters out VERIFIED status parts.

---

### Scenario 4: Move to Missing Location

**The Problem:**
When location mismatch is confirmed on 2nd count, we need an easy way to move the part to where it was actually found. Currently MOVE-INVENTORY exists but isn't enabled/visible.

**What We Need:**
1. A checkbox "Move to Missing Location"
2. When checked, auto-fill the TO_LOCATION field with the Location Counted value
3. Enable MOVE-INVENTORY direction automatically

**Implementation:**
- Add checkbox field C17 = "Move to Missing Location"
- Only enable when: Iteration = 2 AND Location Match = NO
- When checked: Set C14 (TO_LOCATION) = C15 (Location Counted)
- Set Direction = 'MOVE-INVENTORY' when checkbox is checked
- Enable ProgramAttribute CycleCountMoveToLocation = 'TRUE' for the program

**Code Changes:**
Add C17 to InputFields. When it's checked, automatically set C14 = C15 and set Direction to 'MOVE-INVENTORY'. Also need to make sure the ProgramAttribute CycleCountMoveToLocation is set to TRUE for the program (currently it's not enabled based on my query).

---

### Scenario 5: Missing Parts (Not Found)

**The Problem:**
When a part isn't found at all (Location Counted is empty), it currently just errors out. We need to handle this differently - trigger 2nd count automatically.

**What We Need:**
- Detect when Location Counted is empty/null
- Automatically check "Needs 2nd Count" 
- On 2nd count, if still not found, show "Move to Missing Location" checkbox
- This enables automated MPS (Missing Part Search) process

**Implementation:**
- Add validation: IF C15 IS NULL/EMPTY THEN auto-check C16
- On 2nd count iteration, if C15 still NULL, enable C17
- When C17 checked and C15 NULL, trigger MPS workflow (different from normal move)

**Code Changes:**
When C15 is empty/null, automatically check the C16 checkbox. On 2nd count, if C15 is still empty and C17 is checked, that should trigger the MPS workflow instead of a normal move transaction. This might need a separate process or flag.

---

### Scenario 6: Location Display

**The Problem:**
Users can't easily see the comparison between system location and counted location. It's not clear what the mismatch is.

**What We Need:**
- Always show system location (PLUS Location column)
- Always show counted location (Location Counted column)  
- Show Location Match calculation clearly
- Visual indication of mismatches

**Implementation:**
- Query PartSerial.LocationID and display as "PLUS Location" (read-only, always visible)
- Display C15 as "Location Counted" (user input field)
- Calculate and display "Location Match" = YES/NO
- Add conditional formatting: Red when NO, Green when YES

**Code Changes:**
Need to query PartSerial.LocationID to get the system location and display it. Calculate Location Match by comparing that to C15. The screen layout should show PLUS Location, Location Counted, and Location Match all together so it's easy to see mismatches.

---

## Implementation Checklist

### Database Updates
- [ ] Add `LocationCounted` VARCHAR column to CycleCountTaskSerialNo
- [ ] Add `FirstCountLocation` VARCHAR column to CycleCountTaskSerialNo  
- [ ] Add `NeedsSecondCount` BIT column to CycleCountTaskSerialNo
- [ ] Add 'VERIFIED' status to CodeStatus (if doesn't exist)

### Form/Script Updates
- [ ] Add C15 = "Location Counted" to InputFields
- [ ] Add C16 = "Needs 2nd Count" checkbox (show only Iteration 1)
- [ ] Add C17 = "Move to Missing Location" checkbox
- [ ] Add "PLUS Location" display field (read-only)
- [ ] Add "Location Match" calculated field
- [ ] Add "First Count Result" display field (show only Iteration 2)

### Logic Updates
- [ ] Calculate Location Match (System Location = Location Counted)
- [ ] Auto-check "Needs 2nd Count" when mismatch or not found
- [ ] Save Location Counted to FirstCountLocation on 1st count approval
- [ ] Display FirstCountLocation on 2nd count
- [ ] Auto-drop parts when Location Match = YES
- [ ] Auto-populate TO_LOCATION when Move checkbox checked
- [ ] Enable MOVE-INVENTORY ProgramAttribute

### Workflow Updates
- [ ] Hide "Needs 2nd Count" on Iteration 2
- [ ] Show "First Count Result" only on Iteration 2
- [ ] Enable "Move to Missing Location" only when appropriate
- [ ] Filter verified parts from approval queue

---

## Priority Order

1. **Location Mismatch Detection** - Foundation, need this first
2. **Location Display** - Users need to see the comparison
3. **2nd Count Workflow** - Core functionality for handling mismatches
4. **Auto-Drop Matching** - Efficiency improvement
5. **Move to Missing Location** - Adjustment capability
6. **Missing Parts Handling** - Edge case but important

---

## Technical Notes

I've been looking at the Cyclecount script file. Here are the key areas:

- Line 2 shows all the input fields (C01-C14) - no location counted field exists
- Line 4 has the C09 DETAIL dropdown that shows Match/Excess/Short - but this is quantity based, not location
- Line 11 shows C14 TO_LOCATION logic - it shows system location on REMOVE but doesn't compare
- Line 392-393 has iteration increment - but doesn't preserve 1st count data
- Line 3 has MOVE-INVENTORY calculation but it's conditional on ProgramAttribute

Key tables involved:
- CycleCountTaskSerialNo - where we'd need to add new columns
- CycleCountActivity - tracks iterations
- PartSerial - has the system location we need to compare
- PartLocation - location master
- ProgramAttribute - need to enable MOVE-INVENTORY here

---

## Open Questions

1. Is there a limit on how many fields we can add to the DataEntry script? Need to add at least 3 new ones.
2. Does the system already support conditional field visibility? Need to show/hide fields based on iteration.
3. For storing FirstCountLocation - should we add a column to CycleCountTaskSerialNo or use a separate table? I'm thinking new column is simpler.
4. For the VERIFIED status - should we create a new CodeStatus entry or can we reuse an existing one? Need to check what statuses exist.
5. The MPS (Missing Part Search) workflow - is this a separate process or should it be part of the approval? Operations wasn't clear on this.

---

## Testing Scenarios

Need to test these cases once implemented:

1. 1st count with location mismatch (part in ARB.0.0.0, counted in ARB.1.1.1) - should flag for 2nd count
2. 2nd count where location now matches - should auto-drop when approved
3. 2nd count where location still mismatches - should show Move checkbox
4. Part not found on 1st count - should auto-flag for 2nd count
5. Part still not found on 2nd count - should enable Move checkbox for MPS

These match the scenarios operations provided in their requirements.

---

---
*Created: [Date]*  
*Last Updated: [Date]*

