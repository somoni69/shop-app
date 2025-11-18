# Admin Notes for shop_app

This document contains notes for administrators or developers for maintaining the app's backend.

## Supabase `cart_items` Table

The application requires a table named `cart_items` in the `public` schema of your Supabase database. If users are reporting errors related to the cart being unavailable, it's likely this table is missing or misconfigured.

### SQL to Create `cart_items` Table

Run this SQL script in your Supabase SQL editor to create the table with the correct schema and enable Row Level Security (RLS).

```sql
-- Create the cart_items table
CREATE TABLE public.cart_items (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL,
    product_id uuid NOT NULL,
    quantity integer NOT NULL,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    price numeric NOT NULL,
    title text NOT NULL,
    CONSTRAINT cart_items_pkey PRIMARY KEY (id),
    CONSTRAINT cart_items_product_id_fkey FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    CONSTRAINT cart_items_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE
);

-- Add comments to the columns
COMMENT ON COLUMN public.cart_items.id IS 'Primary key for the cart item';
COMMENT ON COLUMN public.cart_items.user_id IS 'Foreign key to the user who owns this cart item';
COMMENT ON COLUMN public.cart_items.product_id IS 'Foreign key to the product in the cart';
COMMENT ON COLUMN public.cart_items.quantity IS 'Quantity of the product in the cart';
COMMENT ON COLUMN public.cart_items.created_at IS 'Timestamp when the item was added';
COMMENT ON COLUMN public.cart_items.price IS 'Price of the product at the time of adding to cart';
COMMENT ON COLUMN public.cart_items.title IS 'Title of the product';

-- Enable Row Level Security
ALTER TABLE public.cart_items ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
-- 1. Users can see their own cart items
CREATE POLICY "Users can see their own cart items"
ON public.cart_items
FOR SELECT USING (auth.uid() = user_id);

-- 2. Users can insert their own cart items
CREATE POLICY "Users can insert their own cart items"
ON public.cart_items
FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 3. Users can update their own cart items
CREATE POLICY "Users can update their own cart items"
ON public.cart_items
FOR UPDATE USING (auth.uid() = user_id);

-- 4. Users can delete their own cart items
CREATE POLICY "Users can delete their own cart items"
ON public.cart_items
FOR DELETE USING (auth.uid() = user_id);

```

### Remediation Steps

1.  **Connect to your Supabase project.**
2.  **Navigate to the SQL Editor.**
3.  **Paste the script above and run it.**

This will resolve the "table not found" errors that users might be experiencing.
