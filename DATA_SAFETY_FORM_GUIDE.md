# Google Play Data Safety Form - Complete Guide

Based on your app's functionality, here's how to fill out the form:

## 1. Data collection and security

### Does your app collect or share any of the required user data types?
**Answer: Yes**

(You've already declared "Device or other IDs" - make sure all other collected data types are also declared)

### Is all of the user data collected by your app encrypted in transit?
**Answer: Yes**

✅ Your app uses:
- HTTPS for all API calls (Shopify API)
- Secure authentication tokens
- Encrypted payment processing (Stripe)

## 2. Account creation methods

### Which of the following methods of account creation does your app support?

**Select:**
- ✅ **Username and password** (Email + Password)
- ❌ Username and other authentication (Not used)
- ❌ Username, password, and other authentication (Not used)
- ❌ OAuth (Not used)
- ❌ Other (Not used)
- ❌ My app does not allow users to create an account (FALSE - your app does allow account creation)

**Note:** Your app uses email as username with password authentication.

## 3. Delete account URL

### Add a link that users can use to request that their account and associated data is deleted

**URL:** `https://freshbe.in/policies/privacy-policy`

**Important:** Make sure this page:
- ✅ Refers to your app or developer name (Freshbe/DSG)
- ✅ Prominently features steps to request account deletion
- ✅ Specifies what data is deleted vs. kept
- ✅ Mentions any additional retention periods (e.g., transaction records for legal compliance)

**If your privacy policy page doesn't have account deletion instructions yet, you should add:**

```
Account Deletion Request

To request deletion of your account and associated data, please:
1. Log in to your account
2. Go to Profile → Settings → Delete Account
OR
3. Send an email to [your support email] with subject "Account Deletion Request"
4. Include your registered email address

What gets deleted:
- User profile information
- Saved addresses
- Wishlist items
- Account preferences

What is retained (for legal/compliance):
- Order history and transaction records (required for tax/compliance)
- Payment records (required by payment processors)

Data will be deleted within 30 days of your request.
```

## 4. Data deletion without account deletion

### Do you provide a way for users to request that some or all of their data is deleted, without requiring them to delete their account?

**Recommended Answer: Yes** (if you support partial data deletion)

**OR**

**Answer: No** (if users must delete their entire account to delete data)

**OR**

**Answer: No, but user data is automatically deleted within 90 days** (if you have automatic deletion)

**For your e-commerce app, I recommend:**
- **Answer: No** (if you don't have partial deletion)
- **OR: Yes** (if users can delete wishlist, addresses, etc. without deleting account)

## 5. Additional badges (Optional)

You may be eligible for badges like:
- **Data safety section** - Shows you've completed data safety declarations
- **Family-friendly** - If your app is appropriate for children

## Summary of Your Answers

```
1. Does your app collect user data? → Yes
2. Is data encrypted in transit? → Yes
3. Account creation methods:
   ✅ Username and password (Email + Password)
4. Delete account URL: https://freshbe.in/policies/privacy-policy
5. Partial data deletion: No (or Yes, if supported)
```

## Action Items

1. ✅ Fill out the form with the answers above
2. ⚠️ **IMPORTANT:** Update your privacy policy page (`https://freshbe.in/policies/privacy-policy`) to include:
   - Clear account deletion instructions
   - What data is deleted vs. retained
   - How long deletion takes
   - Contact information for deletion requests
3. ✅ Save the form in Play Console
4. ✅ Submit a new release (even if it's the same version, this triggers review)

## Verification Checklist

Before submitting, ensure:
- [ ] All collected data types are declared (Device IDs, Email, Name, Phone, Address, Payment info, etc.)
- [ ] Account creation method is correctly selected
- [ ] Delete account URL is accessible and contains deletion instructions
- [ ] Privacy policy is up to date
- [ ] Data encryption is declared as "Yes"

## Common Data Types to Declare for E-commerce Apps

Make sure you've declared:
- ✅ Device or other IDs (Already done)
- ✅ Email address (Account creation, orders)
- ✅ Name (User profile, orders)
- ✅ Phone number (User profile, orders)
- ✅ Physical address (Shipping addresses)
- ✅ Payment info (Stripe payment processing)
- ✅ Purchase history (Order records)
- ✅ App activity (Product views, searches)

