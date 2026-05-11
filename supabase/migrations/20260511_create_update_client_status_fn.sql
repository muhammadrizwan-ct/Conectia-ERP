-- RPC function to update a client's status directly in SQL,
-- bypassing PostgREST schema-cache column validation.
-- Call via: supabase.rpc('update_client_status', { p_client_id: '<uuid>', p_status: 'Demo' })

CREATE OR REPLACE FUNCTION public.update_client_status(p_client_id uuid, p_status text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    UPDATE public.clients
    SET status = p_status
    WHERE id = p_client_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.update_client_status(uuid, text) TO authenticated;

-- Also reload PostgREST schema cache so the status column is visible in select/update
NOTIFY pgrst, 'reload schema';
