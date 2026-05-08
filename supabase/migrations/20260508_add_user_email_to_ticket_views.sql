-- Add user_email column to ticket_views for human-readable identification in the dashboard.
ALTER TABLE public.ticket_views
    ADD COLUMN IF NOT EXISTS user_email text;
