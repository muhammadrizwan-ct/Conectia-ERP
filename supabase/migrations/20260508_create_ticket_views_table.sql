-- Create ticket_views table to persist per-user, per-ticket "last viewed" timestamps.
-- This replaces the localStorage approach which gets wiped on logout.

BEGIN;

CREATE TABLE IF NOT EXISTS public.ticket_views (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    ticket_id uuid NOT NULL REFERENCES public.tickets(id) ON DELETE CASCADE,
    viewed_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (user_id, ticket_id)
);

CREATE INDEX IF NOT EXISTS idx_ticket_views_user_id ON public.ticket_views(user_id);
CREATE INDEX IF NOT EXISTS idx_ticket_views_ticket_id ON public.ticket_views(ticket_id);

-- RLS
ALTER TABLE public.ticket_views ENABLE ROW LEVEL SECURITY;

-- Users can only read/write their own view records
CREATE POLICY ticket_views_select_own ON public.ticket_views
    FOR SELECT TO authenticated USING (user_id = auth.uid());

CREATE POLICY ticket_views_insert_own ON public.ticket_views
    FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());

CREATE POLICY ticket_views_update_own ON public.ticket_views
    FOR UPDATE TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

CREATE POLICY ticket_views_delete_own ON public.ticket_views
    FOR DELETE TO authenticated USING (user_id = auth.uid());

COMMIT;
