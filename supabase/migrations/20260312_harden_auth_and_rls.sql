-- Harden access model:
-- 1) Bind app users to Supabase Auth identities via auth_user_id
-- 2) Replace anon-access policies with authenticated-only policies
-- 3) Restrict users table to self/admin access

BEGIN;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.tables
        WHERE table_schema = 'public' AND table_name = 'users'
    ) THEN
        ALTER TABLE public.users ADD COLUMN IF NOT EXISTS auth_user_id uuid;
        CREATE INDEX IF NOT EXISTS idx_users_auth_user_id ON public.users(auth_user_id);
    END IF;
END
$$;

CREATE OR REPLACE FUNCTION public.current_app_role()
RETURNS text
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    resolved_role text;
    has_auth_user_id boolean := false;
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.tables
        WHERE table_schema = 'public' AND table_name = 'users'
    ) THEN
        RETURN 'user';
    END IF;

    SELECT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'users'
          AND column_name = 'auth_user_id'
    )
    INTO has_auth_user_id;

    IF has_auth_user_id THEN
        SELECT lower(COALESCE(u.role, 'user'))
        INTO resolved_role
        FROM public.users u
        WHERE (u.auth_user_id IS NOT NULL AND u.auth_user_id = auth.uid())
           OR (COALESCE(u.email, '') <> '' AND lower(u.email) = lower(COALESCE(auth.jwt() ->> 'email', '')))
        ORDER BY CASE WHEN u.auth_user_id IS NOT NULL THEN 0 ELSE 1 END
        LIMIT 1;
    ELSE
        SELECT lower(COALESCE(u.role, 'user'))
        INTO resolved_role
        FROM public.users u
        WHERE COALESCE(u.email, '') <> ''
          AND lower(u.email) = lower(COALESCE(auth.jwt() ->> 'email', ''))
        LIMIT 1;
    END IF;

    RETURN COALESCE(resolved_role, 'user');
END;
$$;

CREATE OR REPLACE FUNCTION public.is_app_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT public.current_app_role() = 'admin';
$$;

REVOKE ALL ON FUNCTION public.current_app_role() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.is_app_admin() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.current_app_role() TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_app_admin() TO authenticated;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.tables
        WHERE table_schema = 'public' AND table_name = 'users'
    ) THEN
        ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

        DROP POLICY IF EXISTS users_select_all ON public.users;
        DROP POLICY IF EXISTS users_insert_all ON public.users;
        DROP POLICY IF EXISTS users_update_all ON public.users;
        DROP POLICY IF EXISTS users_delete_all ON public.users;

        DROP POLICY IF EXISTS users_self_select ON public.users;
        DROP POLICY IF EXISTS users_self_update ON public.users;
        DROP POLICY IF EXISTS users_admin_all ON public.users;

        CREATE POLICY users_self_select
            ON public.users
            FOR SELECT
            TO authenticated
            USING (
                auth_user_id = auth.uid()
                OR lower(COALESCE(email, '')) = lower(COALESCE(auth.jwt() ->> 'email', ''))
                OR public.is_app_admin()
            );

        CREATE POLICY users_self_update
            ON public.users
            FOR UPDATE
            TO authenticated
            USING (
                auth_user_id = auth.uid()
                OR lower(COALESCE(email, '')) = lower(COALESCE(auth.jwt() ->> 'email', ''))
                OR public.is_app_admin()
            )
            WITH CHECK (
                auth_user_id = auth.uid()
                OR lower(COALESCE(email, '')) = lower(COALESCE(auth.jwt() ->> 'email', ''))
                OR public.is_app_admin()
            );

        CREATE POLICY users_admin_all
            ON public.users
            FOR ALL
            TO authenticated
            USING (public.is_app_admin())
            WITH CHECK (public.is_app_admin());

        REVOKE ALL ON public.users FROM anon;
        GRANT SELECT, INSERT, UPDATE, DELETE ON public.users TO authenticated;
    END IF;
END
$$;

DO $$
DECLARE
    target_table text;
    target_tables text[] := ARRAY[
        'clients',
        'vehicles',
        'invoices',
        'payments',
        'vendor_payments',
        'vendor_invoices',
        'salary_expenses',
        'daily_expenses'
    ];
BEGIN
    FOREACH target_table IN ARRAY target_tables LOOP
        IF EXISTS (
            SELECT 1
            FROM information_schema.tables
            WHERE table_schema = 'public' AND table_name = target_table
        ) THEN
            EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', target_table);

            EXECUTE format('DROP POLICY IF EXISTS %I_select_all ON public.%I', target_table, target_table);
            EXECUTE format('DROP POLICY IF EXISTS %I_insert_all ON public.%I', target_table, target_table);
            EXECUTE format('DROP POLICY IF EXISTS %I_update_all ON public.%I', target_table, target_table);
            EXECUTE format('DROP POLICY IF EXISTS %I_delete_all ON public.%I', target_table, target_table);

            EXECUTE format('DROP POLICY IF EXISTS %I_authenticated_select ON public.%I', target_table, target_table);
            EXECUTE format('DROP POLICY IF EXISTS %I_authenticated_insert ON public.%I', target_table, target_table);
            EXECUTE format('DROP POLICY IF EXISTS %I_authenticated_update ON public.%I', target_table, target_table);
            EXECUTE format('DROP POLICY IF EXISTS %I_authenticated_delete ON public.%I', target_table, target_table);

            EXECUTE format(
                'CREATE POLICY %I_authenticated_select ON public.%I FOR SELECT TO authenticated USING (auth.role() = ''authenticated'')',
                target_table,
                target_table
            );

            EXECUTE format(
                'CREATE POLICY %I_authenticated_insert ON public.%I FOR INSERT TO authenticated WITH CHECK (auth.role() = ''authenticated'')',
                target_table,
                target_table
            );

            EXECUTE format(
                'CREATE POLICY %I_authenticated_update ON public.%I FOR UPDATE TO authenticated USING (auth.role() = ''authenticated'') WITH CHECK (auth.role() = ''authenticated'')',
                target_table,
                target_table
            );

            EXECUTE format(
                'CREATE POLICY %I_authenticated_delete ON public.%I FOR DELETE TO authenticated USING (auth.role() = ''authenticated'')',
                target_table,
                target_table
            );

            EXECUTE format('REVOKE ALL ON public.%I FROM anon', target_table);
            EXECUTE format('GRANT SELECT, INSERT, UPDATE, DELETE ON public.%I TO authenticated', target_table);
        END IF;
    END LOOP;
END
$$;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.views
        WHERE table_schema = 'public' AND table_name = 'dashboard_monthly_summary'
    ) THEN
        REVOKE ALL ON public.dashboard_monthly_summary FROM anon;
        GRANT SELECT ON public.dashboard_monthly_summary TO authenticated;
    END IF;
END
$$;

COMMIT;
