-- Allow 'Demo' as a valid client status value.
-- The existing clients_status_check constraint only allowed Active/Inactive.

ALTER TABLE public.clients DROP CONSTRAINT IF EXISTS clients_status_check;

ALTER TABLE public.clients
    ADD CONSTRAINT clients_status_check
    CHECK (status IN ('Active', 'Inactive', 'Demo'));
