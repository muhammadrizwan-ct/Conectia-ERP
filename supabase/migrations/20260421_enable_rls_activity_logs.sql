-- Enable Row Level Security (RLS) on activity_logs
ALTER TABLE activity_logs ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users to insert audit logs
CREATE POLICY activity_logs_authenticated_insert ON activity_logs
    FOR INSERT TO authenticated
    WITH CHECK (auth.role() = 'authenticated');

-- Allow authenticated users to select their own logs (optional, for viewing)
CREATE POLICY activity_logs_authenticated_select ON activity_logs
    FOR SELECT TO authenticated
    USING (auth.role() = 'authenticated');
