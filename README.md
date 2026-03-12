# vehicle-tracking-system
Enterprise Vehicle Tracking Management System

## Security Rollout Notes (March 2026)

This project now uses Supabase Auth sessions for app login and includes hardened RLS migration scripts.

### What changed

- Frontend login now authenticates with Supabase Auth (`signInWithPassword`).
- Session bootstrap now reads Supabase session and maps user profile from `public.users`.
- New migration `supabase/migrations/20260312_harden_auth_and_rls.sql`:
	- Adds `auth_user_id` support to `public.users`.
	- Restricts `public.users` access to self/admin policies.
	- Replaces anon-access table policies with authenticated-only policies.
	- Revokes `anon` access from key data tables and dashboard summary view.

### Required deployment steps

1. Run Supabase migrations (including `20260312_harden_auth_and_rls.sql`).
2. Ensure every app user has a valid Supabase Auth account (email/password).
3. After first login, the app auto-links `public.users.auth_user_id` where possible.
4. Users should sign in with email address (not username).

### Master account

- Master username alias: `Master`
- Master email login: `muhammadrizwan@connectia.io`
- Run migration `supabase/migrations/20260312_seed_master_admin_profile.sql` to seed/update admin profile.
- In Supabase Auth dashboard, create user with email `muhammadrizwan@connectia.io` and your chosen password.
- The app maps username `Master` to that email during sign-in.

### Important

- If your existing workflows depend on anonymous access, those requests will be blocked after migration.
- Admin permissions are resolved from `public.users.role = 'admin'`.
