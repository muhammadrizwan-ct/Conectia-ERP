-- Create vendors table for persistent vendor storage

CREATE TABLE IF NOT EXISTS public.vendors (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    vendor_id text,
    name text NOT NULL,
    email text,
    phone text,
    address text,
    ntn text,
    status text NOT NULL DEFAULT 'Active',
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_vendors_name ON public.vendors(name);
CREATE INDEX IF NOT EXISTS idx_vendors_status ON public.vendors(status);

-- Enable RLS
ALTER TABLE public.vendors ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'public' AND tablename = 'vendors' AND policyname = 'vendors_select_all'
    ) THEN
        CREATE POLICY vendors_select_all
            ON public.vendors
            FOR SELECT
            TO anon, authenticated
            USING (true);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'public' AND tablename = 'vendors' AND policyname = 'vendors_insert_all'
    ) THEN
        CREATE POLICY vendors_insert_all
            ON public.vendors
            FOR INSERT
            TO anon, authenticated
            WITH CHECK (true);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'public' AND tablename = 'vendors' AND policyname = 'vendors_update_all'
    ) THEN
        CREATE POLICY vendors_update_all
            ON public.vendors
            FOR UPDATE
            TO anon, authenticated
            USING (true)
            WITH CHECK (true);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'public' AND tablename = 'vendors' AND policyname = 'vendors_delete_all'
    ) THEN
        CREATE POLICY vendors_delete_all
            ON public.vendors
            FOR DELETE
            TO anon, authenticated
            USING (true);
    END IF;
END
$$;
