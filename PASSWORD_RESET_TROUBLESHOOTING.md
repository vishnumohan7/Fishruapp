# Password Reset Email Troubleshooting Guide

If password reset emails are not being received, follow these steps to diagnose and fix the issue.

## Common Issues and Solutions

### 1. **Email Notifications Disabled in Shopify**

**Problem:** Shopify email notifications for password reset are disabled.

**Solution:**
1. Log in to your Shopify Admin
2. Go to **Settings** > **Notifications**
3. Scroll down to **Customer account** section
4. Find **"Customer account password reset"** email
5. Click **"Enable"** or **"Edit"** to ensure it's enabled
6. Save changes

**Note:** If you don't see this option, you may need to enable customer accounts first:
- Go to **Settings** > **Customer accounts**
- Enable customer accounts if not already enabled

### 2. **Storefront API Token Missing Permissions**

**Problem:** The Storefront API token doesn't have permission to send password reset emails.

**Solution:**
1. Go to Shopify Admin > **Settings** > **Apps and sales channels**
2. Click **"Develop apps"** (or **"Manage private apps"** in older versions)
3. Find your Storefront API app
4. Click on it to view permissions
5. Ensure the following permissions are enabled:
   - `unauthenticated_read_customer_reset` (for password reset)
   - `unauthenticated_write_customers` (if needed)
6. Regenerate the token if permissions were changed
7. Update the `SHOPIFY_STOREFRONT_TOKEN` in your `.env` file

### 3. **Email Address Not in Customer Database**

**Problem:** The email address doesn't exist in your Shopify customer database.

**Solution:**
1. Go to Shopify Admin > **Customers**
2. Search for the email address
3. If the customer doesn't exist, they need to register first
4. If the customer exists, verify the email is correct and active

**Note:** For security reasons, Shopify always returns "success" even if the email doesn't exist. This prevents email enumeration attacks.

### 4. **Email Service Not Configured**

**Problem:** Shopify's email service is not properly configured.

**Solution:**
1. Go to Shopify Admin > **Settings** > **Notifications**
2. Check if email service is configured
3. Verify your store's email settings
4. Test sending a test email from Shopify Admin

### 5. **Email Going to Spam/Junk Folder**

**Problem:** The password reset email is being filtered as spam.

**Solution:**
1. Check the spam/junk folder
2. Wait 5-10 minutes (emails may be delayed)
3. Add Shopify's email address to contacts/whitelist
4. Check email filters and rules

### 6. **Incorrect Storefront API Token**

**Problem:** The `SHOPIFY_STOREFRONT_TOKEN` in `.env` file is incorrect or expired.

**Solution:**
1. Verify the token in your `.env` file matches the Storefront API token in Shopify
2. Check that the token hasn't been regenerated or revoked
3. Ensure there are no extra spaces or characters in the token
4. Regenerate the token if needed and update `.env`

### 7. **Wrong Store Domain**

**Problem:** The store domain in `.env` file is incorrect.

**Solution:**
1. Verify `SHOPIFY_STORE_DOMAIN` in `.env` file
2. It should be in format: `yourstore.myshopify.com` (without `https://`)
3. Check that the domain matches your Shopify store exactly

## Debugging Steps

### Check App Logs

When you request a password reset, check the console/logs for:

1. **Token verification:**
   ```
   Storefront Token present: true/false
   ```

2. **API response:**
   ```
   === Password Recovery Response ===
   Has exception: true/false
   Result data: {...}
   ```

3. **Error messages:**
   - Look for authentication errors (401, 403)
   - Check for GraphQL errors
   - Note any network errors

### Test the API Directly

You can test the password reset mutation directly using GraphQL:

```graphql
mutation {
  customerRecover(email: "customer@example.com") {
    customerUserErrors {
      field
      message
      code
    }
  }
}
```

Use this in:
- Shopify GraphQL Admin API explorer
- Postman or similar tool
- Your app's GraphQL client

## Verification Checklist

Before reporting an issue, verify:

- [ ] Email notifications are enabled in Shopify Admin
- [ ] Storefront API token has correct permissions
- [ ] `SHOPIFY_STOREFRONT_TOKEN` is correctly set in `.env` file
- [ ] `SHOPIFY_STORE_DOMAIN` is correctly set in `.env` file
- [ ] Customer email exists in Shopify customer database
- [ ] Checked spam/junk folder
- [ ] Waited 5-10 minutes for email delivery
- [ ] Email service is configured in Shopify
- [ ] No firewall or email filtering blocking Shopify emails

## Testing

1. **Test with a known customer email:**
   - Use an email that you know exists in your customer database
   - Request password reset
   - Check email inbox and spam folder

2. **Check app logs:**
   - Look for success/error messages
   - Verify API calls are being made
   - Check for authentication errors

3. **Verify in Shopify Admin:**
   - Check customer account settings
   - Verify email notifications are enabled
   - Check if there are any email delivery issues

## Additional Resources

- [Shopify Customer Account API Documentation](https://shopify.dev/api/customer-account)
- [Shopify Email Notifications Guide](https://help.shopify.com/en/manual/orders/notifications)
- [Storefront API Permissions](https://shopify.dev/api/storefront)

## Still Not Working?

If you've checked all the above and emails still aren't being sent:

1. **Contact Shopify Support:**
   - They can verify email service configuration
   - Check for account-level issues
   - Verify API permissions

2. **Check Shopify Status:**
   - Visit [status.shopify.com](https://status.shopify.com)
   - Check for any service outages

3. **Review App Logs:**
   - Share error messages with your development team
   - Check for specific error codes or messages

4. **Alternative Solution:**
   - Consider implementing a custom password reset flow
   - Use Admin API if Storefront API has limitations
   - Implement email sending through your own backend

