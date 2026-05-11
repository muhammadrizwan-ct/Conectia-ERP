-- Add status text column to clients table to support Active/Inactive/Demo

ALTER TABLE public.clients
    ADD COLUMN IF NOT EXISTS status text NOT NULL DEFAULT 'Active';

-- Add index for filtering by status
CREATE INDEX IF NOT EXISTS idx_clients_status ON public.clients(status);
