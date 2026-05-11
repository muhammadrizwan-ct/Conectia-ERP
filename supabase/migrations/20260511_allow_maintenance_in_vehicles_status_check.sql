-- Allow 'Maintenance' as a valid vehicle status.
-- The original schema only permitted 'Active' and 'Inactive', causing
-- PATCH requests for Maintenance vehicles to be rejected by the DB.

ALTER TABLE public.vehicles DROP CONSTRAINT IF EXISTS vehicles_status_check;
ALTER TABLE public.vehicles ADD CONSTRAINT vehicles_status_check
    CHECK (status IN ('Active', 'Inactive', 'Maintenance'));
