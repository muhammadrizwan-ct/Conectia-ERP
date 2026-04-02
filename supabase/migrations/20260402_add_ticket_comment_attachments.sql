-- Add attachment_url column to ticket_comments for screenshot uploads
ALTER TABLE public.ticket_comments
ADD COLUMN IF NOT EXISTS attachment_url TEXT DEFAULT NULL;

-- Create storage bucket for ticket attachments
INSERT INTO storage.buckets (id, name, public)
VALUES ('ticket-attachments', 'ticket-attachments', true)
ON CONFLICT (id) DO NOTHING;

-- Allow authenticated users to upload to ticket-attachments bucket
CREATE POLICY "Authenticated users can upload ticket attachments"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'ticket-attachments');

-- Allow anyone to read ticket attachment files (public bucket)
CREATE POLICY "Public read access for ticket attachments"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'ticket-attachments');

-- Allow users to delete their own uploads
CREATE POLICY "Users can delete own ticket attachments"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'ticket-attachments');
