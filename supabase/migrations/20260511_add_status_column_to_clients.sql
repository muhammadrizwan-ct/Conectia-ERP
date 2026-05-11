-- Add status text column to clients table to support Active/Inactive/Demo
-- Previously only is_active (boolean) existed, which cannot store 'Demo'

ALTER TABLE public.clients
    ADD COLUMN IF NOT EXISTS status text NOT NULL DEFAULT 'Active';

-- Backfill from is_active boolean where status is still at default
UPDATE public.clients
SET status = CASE
    WHEN is_active = false THEN 'Inactive'
    ELSE 'Active'
END
WHERE status = 'Active' AND is_active IS NOT NULL;

-- Add index for filtering by status
CREATE INDEX IF NOT EXISTS idx_clients_status ON public.clients(status);
