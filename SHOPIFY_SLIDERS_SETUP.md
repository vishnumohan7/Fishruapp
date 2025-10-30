# How to Add Sliders/Banners in Shopify

There are two ways to add sliders to your Shopify store:

## Option 1: Using Shopify Metafields (Recommended)

This is the **recommended approach** as it stores slider data directly in Shopify.

### Step 1: Go to Shopify Admin

1. Log in to your Shopify Admin panel
2. Go to **Settings** → **Custom data** (or **Online Store** → **Themes** → **Customize** → **Metafields**)

### Step 2: Create a Shop Metafield

1. Click **Add definition**
2. Select **Shop** as the resource type
3. Configure the metafield:
   - **Name**: Home Page Sliders (or any name you prefer)
   - **Namespace and key**: 
     - Namespace: `banner`
     - Key: `home_sliders` (or `sliders`, `carousel`)
   - **Type**: `JSON` (JSON text)
   - **Description**: "Sliders for the home page carousel"

### Step 3: Add Slider Data

1. After creating the metafield, go to **Settings** → **Custom data** → **Shop**
2. Find your metafield and click **Add value**
3. Paste the following JSON structure:

```json
[
  {
    "imageUrl": "https://cdn.shopify.com/s/files/1/0000/0000/files/banner1.jpg",
    "title": "Get 20% Off",
    "subtitle": "On your first order",
    "linkUrl": "collection:123456789",
    "linkText": "Shop Now"
  },
  {
    "imageUrl": "https://cdn.shopify.com/s/files/1/0000/0000/files/banner2.jpg",
    "title": "New Arrivals",
    "subtitle": "Check out our latest products",
    "linkUrl": "collection:987654321",
    "linkText": "Explore"
  }
]
```

### Step 4: JSON Structure Explanation

Each slider object should have:
- `imageUrl` (required): Full URL to the banner image
- `title` (optional): Main heading text
- `subtitle` (optional): Subheading/description text
- `linkUrl` (optional): Navigation link (formats: `collection:ID`, `product:ID`, or full URL)
- `linkText` (optional): Button text (defaults to "Shop Now")

### Step 5: Upload Images

1. Go to **Content** → **Files** in Shopify Admin
2. Upload your banner images
3. Copy the image URLs and paste them in the `imageUrl` field

### Step 6: Find Collection IDs

To create collection links (`collection:123456789`):
1. Go to **Products** → **Collections**
2. Click on a collection
3. Look at the URL: `admin.shopify.com/store/YOUR-STORE/collections/1234567890`
4. The number at the end is the collection ID
5. Use it in your slider: `"linkUrl": "collection:1234567890"`

## Option 2: Using Backend API

If you prefer using a separate backend API instead of Shopify metafields:

### Backend Endpoint

Create an endpoint: `GET /api/sliders`

### Response Format

Return either:

```json
[
  {
    "imageUrl": "https://example.com/banner1.jpg",
    "title": "Get 20% Off",
    "subtitle": "On your first order",
    "linkUrl": "collection:123",
    "linkText": "Shop Now"
  }
]
```

Or:

```json
{
  "sliders": [
    {
      "imageUrl": "https://example.com/banner1.jpg",
      "title": "Get 20% Off",
      "subtitle": "On your first order",
      "linkUrl": "collection:123",
      "linkText": "Shop Now"
    }
  ]
}
```

### Configure Backend URL

Set `BACKEND_BASE_URL` in your `.env` file:
```
BACKEND_BASE_URL=https://your-backend-api.com
```

## Current Implementation

The app tries both methods:
1. **First**: Fetches from Shopify metafields (if configured)
2. **Fallback**: Fetches from backend API (if Shopify has no sliders)

## Testing

1. Configure sliders in Shopify Admin using Option 1, OR
2. Set up backend API using Option 2
3. Restart the app
4. Check the home screen - sliders should appear automatically

## Troubleshooting

### Sliders not showing?

1. **Check console logs**:
   - "Loading sliders from Shopify..."
   - "Loaded X sliders"

2. **Verify metafield configuration**:
   - Namespace should be: `banner` or `slider` or `app`
   - Key should be: `home_sliders` or `sliders` or `carousel`
   - Type should be: `JSON`

3. **Verify image URLs**:
   - Must be full URLs (starting with `https://`)
   - Images must be publicly accessible
   - Check if images load in a browser

4. **Verify JSON format**:
   - Must be valid JSON
   - Should be an array of objects
   - Each object must have `imageUrl` at minimum

## Example Slider Configurations

### Simple Slider (Image Only)
```json
[
  {
    "imageUrl": "https://cdn.shopify.com/s/files/1/0000/0000/files/banner.jpg"
  }
]
```

### Slider with Collection Link
```json
[
  {
    "imageUrl": "https://cdn.shopify.com/s/files/1/0000/0000/files/banner.jpg",
    "title": "Summer Sale",
    "subtitle": "Up to 50% off selected items",
    "linkUrl": "collection:123456789",
    "linkText": "Shop Now"
  }
]
```

### Multiple Sliders
```json
[
  {
    "imageUrl": "https://cdn.shopify.com/s/files/1/0000/0000/files/banner1.jpg",
    "title": "New Collection",
    "linkUrl": "collection:111"
  },
  {
    "imageUrl": "https://cdn.shopify.com/s/files/1/0000/0000/files/banner2.jpg",
    "title": "Sale Items",
    "linkUrl": "collection:222"
  }
]
```

