-- Adds invoice_no to client payments so ledger can display invoice numbers for payments

ALTER TABLE public.payments
    ADD COLUMN IF NOT EXISTS invoice_no text;

UPDATE public.payments AS p
SET invoice_no = COALESCE(
    invoice_no,
    CASE WHEN (to_jsonb(p) -> 'details' ->> 'invoiceNo') ~ '.*\S.*' THEN (to_jsonb(p) -> 'details' ->> 'invoiceNo') END,
    CASE WHEN (to_jsonb(p) -> 'details' ->> 'invoice_no') ~ '.*\S.*' THEN (to_jsonb(p) -> 'details' ->> 'invoice_no') END,
    CASE WHEN (to_jsonb(p) ->> 'invoiceNo') ~ '.*\S.*' THEN (to_jsonb(p) ->> 'invoiceNo') END,
    CASE WHEN (to_jsonb(p) ->> 'invoice_no') ~ '.*\S.*' THEN (to_jsonb(p) ->> 'invoice_no') END,
    ''
);
