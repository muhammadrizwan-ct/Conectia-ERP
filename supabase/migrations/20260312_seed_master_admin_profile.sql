-- Seed/ensure Master admin profile in public.users and link to existing Supabase auth user.
-- Note: this migration does NOT store plaintext passwords and does not create auth users directly.
-- Create the auth user in Supabase Auth dashboard with:
--   email: muhammadrizwan@connectia.io
--   password: <set a strong password in Supabase Auth dashboard>

BEGIN;

DO $$
DECLARE
    master_email text := 'muhammadrizwan@connectia.io';
    master_username text := 'Master';
    master_fullname text := 'Master';
    linked_auth_user_id uuid;
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.tables
        WHERE table_schema = 'public' AND table_name = 'users'
    ) THEN
        RAISE NOTICE 'public.users table not found; skipping Master profile seed.';
        RETURN;
    END IF;

    SELECT au.id
    INTO linked_auth_user_id
    FROM auth.users au
    WHERE lower(COALESCE(au.email, '')) = lower(master_email)
    LIMIT 1;

    UPDATE public.users
    SET
        username = master_username,
        email = master_email,
        fullname = COALESCE(NULLIF(fullname, ''), master_fullname),
        role = 'admin',
        status = 'active',
        auth_user_id = COALESCE(auth_user_id, linked_auth_user_id)
    WHERE lower(COALESCE(email, '')) = lower(master_email)
       OR lower(COALESCE(username, '')) = lower(master_username);

    IF NOT FOUND THEN
        INSERT INTO public.users (username, email, fullname, role, status, auth_user_id)
        VALUES (master_username, master_email, master_fullname, 'admin', 'active', linked_auth_user_id);
    END IF;
END
$$;

COMMIT;
