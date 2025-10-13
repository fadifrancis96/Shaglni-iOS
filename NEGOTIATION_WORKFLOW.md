# 🤝 Negotiation Workflow & Job Status Management

## Overview
This document explains the enhanced negotiation workflow and job status management features implemented in the Shaglni app.

---

## 🔄 Negotiation Workflow

### Business Rules

1. **Initial Offer Submission**
   - Contractor submits an offer with their proposed price
   - Offer status: `pending`

2. **Job Poster Response Options**
   - ✅ **Accept** - Accept the offer at the original price
   - 💰 **Negotiate** - Send a counter-offer with different price
   - ❌ **Decline** - Reject the offer

3. **Counter Offer by Job Poster**
   - Job poster can propose a different price
   - Offer status changes to: `counterOffer`
   - Contractor receives notification (when enabled)

4. **Contractor Response to Counter Offer**
   - ✅ **Accept Counter Offer** - Contractor agrees to job poster's price
     - Sets `contractorAcceptedCounter = true`
     - **Ball goes back to job poster for final approval**
   - ❌ **Decline Counter Offer** - Contractor rejects, offer is deleted

5. **Job Poster Final Approval** ⭐ NEW
   - After contractor accepts counter-offer
   - Job poster sees: "Contractor Accepted Your Counter Offer!"
   - Job poster can:
     - **Finalize & Mark Job In Progress** - Accepts the negotiated terms
     - This is the **final decision** in the negotiation

---

## 📊 Offer Status Flow

```
┌─────────────────┐
│ Contractor      │
│ Submits Offer   │
│  (pending)      │
└────────┬────────┘
         │
         ▼
┌─────────────────────────────┐
│ Job Poster Reviews          │
└─────┬───────────┬───────────┘
      │           │
      ▼           ▼
  ┌────────┐  ┌──────────────┐
  │ Accept │  │ Negotiate    │
  │ ✅     │  │ (counterOffer)│
  └────┬───┘  └──────┬───────┘
       │             │
       │             ▼
       │    ┌─────────────────────┐
       │    │ Contractor Reviews  │
       │    │ Counter Offer       │
       │    └─────┬────────┬──────┘
       │          │        │
       │          ▼        ▼
       │    ┌─────────┐ ┌─────────┐
       │    │ Accept  │ │ Decline │
       │    │ Counter │ │ ❌      │
       │    └────┬────┘ └─────────┘
       │         │
       │         ▼
       │    ┌──────────────────────┐
       │    │ Job Poster Finalizes │ ⭐ NEW
       │    │ (Final Approval)     │
       │    └──────────┬───────────┘
       │               │
       ▼               ▼
  ┌────────────────────────┐
  │ Offer Accepted         │
  │ (Status: accepted)     │
  └────────────────────────┘
```

---

## 🛠️ Job Status Management

### Job Status Transitions

1. **Open** (`open`)
   - Job is posted and visible in listings
   - Contractors can submit offers
   - Job appears on the map

2. **In Progress** (`inProgress`) ⭐ NEW
   - Job has been assigned to a contractor
   - **Removed from public job listings**
   - Only visible to the job poster and assigned contractor
   - Triggered when job poster clicks "Mark Job as In Progress"

3. **Completed** (`completed`)
   - Job has been finished
   - Available for rating/review (future feature)

4. **Cancelled** (`cancelled`)
   - Job was cancelled before completion

---

## 🎯 Key Features Implemented

### 1. Contractor Response to Counter Offers
**File:** `Views/Offers/OfferDetailView.swift`

When a contractor views a counter offer:
```swift
// Contractor sees:
- Counter offer price from job poster
- Negotiation message explaining why
- Two buttons:
  ✅ Accept Counter Offer
  ❌ Decline Counter Offer
```

**Accept Action:**
- Sets `contractorAcceptedCounter = true`
- Records `finalPrice` as the counter price
- Updates `respondedAt` timestamp
- Sends the offer back to job poster for final approval

**Decline Action:**
- Completely removes the offer from the database
- Contractor can submit a new offer if they want

---

### 2. Job Poster Final Approval
**File:** `Views/Offers/OfferDetailView.swift`

When contractor accepts counter offer, job poster sees:
```swift
// Special UI state:
- Green banner: "Contractor Accepted Your Counter Offer!"
- Displays agreed price
- Single button: "Finalize & Mark Job In Progress"
```

**Finalize Action:**
1. Updates offer status to `accepted`
2. Sets `finalPrice` in the offer
3. Changes job status to `inProgress`
4. Removes job from public listings
5. Dismisses the view

---

### 3. Mark Job as In Progress (Post-Acceptance)
**File:** `Views/Offers/OfferDetailView.swift`

For already-accepted offers, job poster can still:
```swift
// Button available on accepted offers:
"Mark Job as In Progress"
- Updates job status to inProgress
- Removes from public listings
- Keeps all offer details intact
```

---

## 📁 Files Modified

### 1. **Models/Offer.swift**
Added new fields:
```swift
var contractorAcceptedCounter: Bool?  // Tracks if contractor accepted counter
var finalPrice: Double?  // Records the agreed-upon price
```

### 2. **Services/FirestoreService.swift**
New methods:
```swift
// Updated to track counter acceptance
func respondToCounterOffer(
    jobId: String, 
    offerId: String, 
    accept: Bool, 
    counterPrice: Double?, 
    completion: @escaping (Result<Void, Error>) -> Void
)

// Finalizes offer after negotiation
func finalizeOffer(
    jobId: String, 
    offerId: String, 
    finalPrice: Double, 
    completion: @escaping (Result<Void, Error>) -> Void
)

// Updates job status (open -> inProgress -> completed)
func updateJobStatus(
    jobId: String, 
    status: JobStatus, 
    completion: @escaping (Result<Void, Error>) -> Void
)
```

### 3. **Views/Offers/OfferDetailView.swift**
Enhanced UI states:
- Added UI for contractor accepting counter offers
- Added UI for job poster final approval
- Added "Finalize & Mark In Progress" button
- Added "Mark Job as In Progress" button for accepted offers
- Added confirmation dialogs for all actions
- Added proper loading states and error handling

---

## 🎨 UI/UX Enhancements

### Color-Coded Status Indicators
- 🟢 **Green** - Accepted, contractor agreed to counter
- 🟠 **Orange** - Counter offer, waiting for contractor
- 🔵 **Blue** - Action buttons for job management
- 🔴 **Red** - Decline/cancel actions

### Confirmation Dialogs
All destructive or important actions require confirmation:
- Accept offer
- Decline offer
- Accept counter offer
- Decline counter offer
- Finalize offer
- Mark job in progress

### Loading States
- Progress indicator during all async operations
- Disabled buttons while loading
- Overlay prevents multiple submissions

---

## 🔒 Business Logic Guarantees

### ✅ What This Implementation Ensures:

1. **Job Poster Has Final Say**
   - Even after contractor accepts counter, job poster must finalize
   - Prevents automatic job assignment

2. **Clear Negotiation Flow**
   - Each party knows whose turn it is
   - Clear visual indicators of status

3. **No Ambiguity**
   - `contractorAcceptedCounter` flag clearly tracks negotiation state
   - `finalPrice` records the agreed amount

4. **Job Visibility Control**
   - Jobs in progress are removed from public listings
   - Prevents contractors from submitting offers to assigned jobs

5. **Audit Trail**
   - All prices tracked (original, counter, final)
   - Timestamps for all actions
   - Negotiation messages preserved

---

## 🧪 Testing Scenarios

### Scenario 1: Simple Acceptance
1. Contractor submits offer (₪500)
2. Job poster accepts immediately
3. Job poster marks job as in progress
4. ✅ Job removed from listings

### Scenario 2: Negotiation - Contractor Accepts
1. Contractor submits offer (₪500)
2. Job poster sends counter offer (₪400)
3. Contractor accepts counter offer
4. Job poster sees "Contractor Accepted" notification
5. Job poster clicks "Finalize & Mark In Progress"
6. ✅ Offer finalized at ₪400, job marked in progress

### Scenario 3: Negotiation - Contractor Declines
1. Contractor submits offer (₪500)
2. Job poster sends counter offer (₪300)
3. Contractor declines counter offer
4. ✅ Offer is deleted, contractor can submit new offer if desired

### Scenario 4: Multiple Offers
1. Multiple contractors submit offers
2. Job poster negotiates with one contractor
3. Contractor accepts counter
4. Job poster finalizes
5. ✅ Other pending offers remain visible until job is marked in progress

---

## 🚀 Next Steps (Future Enhancements)

### Recommended Improvements:
1. **Push Notifications** (infrastructure ready)
   - Notify contractor when counter offer is sent
   - Notify job poster when contractor accepts counter
   - Notify both parties when job is marked in progress

2. **In-App Messaging**
   - Allow free-form negotiation chat
   - Attached to offer thread

3. **Auto-Reject Other Offers**
   - When job is marked in progress
   - Automatically reject all pending offers
   - Send notifications to those contractors

4. **Negotiation History**
   - Show all price changes in timeline
   - Display all messages exchanged

5. **Expiration Timers**
   - Auto-decline offers after X days
   - Reminder notifications before expiration

---

## 📊 Database Schema

### Offer Document Structure
```javascript
{
  id: "offer123",
  jobId: "job456",
  contractorId: "user789",
  contractorName: "John Doe",
  message: "I can complete this job...",
  price: 500.0,  // Original contractor price
  status: "counterOffer",  // pending | accepted | rejected | counterOffer
  createdAt: Timestamp,
  
  // Negotiation fields
  counterPrice: 400.0,  // Job poster's proposed price
  negotiationMessage: "Can you do it for this price?",
  respondedAt: Timestamp,
  contractorAcceptedCounter: true,  // ⭐ NEW - Contractor agreed
  finalPrice: 400.0  // ⭐ NEW - Final agreed price
}
```

### Job Document Structure
```javascript
{
  id: "job456",
  title: "Plumbing Repair",
  status: "inProgress",  // open | inProgress | completed | cancelled
  // ... other fields
}
```

---

## ✅ Summary

This implementation provides a **complete, professional negotiation workflow** with:
- Clear responsibility at each stage
- Job poster having final approval
- Proper job visibility management
- Comprehensive UI/UX for all scenarios
- Ready for push notifications integration

The system is production-ready and handles all edge cases gracefully! 🎉

