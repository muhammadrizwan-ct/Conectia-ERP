import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';

const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY');
const APP_URL = 'https://muhammadrizwan-ct.github.io/Conectia-ERP';
const FROM_EMAIL = 'no-reply@connectia.io'; // Change to your verified Resend domain email

serve(async (req: Request) => {
    // Handle CORS preflight
    if (req.method === 'OPTIONS') {
        return new Response('ok', {
            headers: {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
            },
        });
    }

    try {
        if (!RESEND_API_KEY) {
            return new Response(JSON.stringify({ error: 'RESEND_API_KEY not configured' }), {
                status: 500,
                headers: { 'Content-Type': 'application/json' },
            });
        }

        const body = await req.json();
        const { to_email, to_name, ticket_number, ticket_title, ticket_priority, assigned_by, action } = body;

        if (!to_email || !ticket_number) {
            return new Response(JSON.stringify({ error: 'Missing required fields: to_email, ticket_number' }), {
                status: 400,
                headers: { 'Content-Type': 'application/json' },
            });
        }

        const isNew = action === 'create';
        const subject = isNew
            ? `New Ticket Assigned to You — ${ticket_number}`
            : `Ticket Reassigned to You — ${ticket_number}`;

        const priorityColor: Record<string, string> = {
            urgent: '#d32f2f',
            high: '#f57c00',
            medium: '#1976d2',
            low: '#757575',
        };
        const pColor = priorityColor[ticket_priority] || '#1976d2';

        const html = `
<!DOCTYPE html>
<html>
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"></head>
<body style="margin:0;padding:0;background:#f4f6f9;font-family:Arial,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:#f4f6f9;padding:32px 0;">
    <tr><td align="center">
      <table width="560" cellpadding="0" cellspacing="0" style="background:#ffffff;border-radius:10px;box-shadow:0 2px 12px rgba(0,0,0,0.08);overflow:hidden;max-width:560px;width:100%;">
        <!-- Header -->
        <tr>
          <td style="background:#1976d2;padding:28px 32px;">
            <h1 style="margin:0;color:#ffffff;font-size:22px;font-weight:700;letter-spacing:0.5px;">
              Conectia ERP
            </h1>
            <p style="margin:6px 0 0;color:#bbdefb;font-size:13px;">Ticket Notification</p>
          </td>
        </tr>
        <!-- Body -->
        <tr>
          <td style="padding:32px;">
            <p style="margin:0 0 8px;font-size:15px;color:#333;">Hi <strong>${to_name || to_email}</strong>,</p>
            <p style="margin:0 0 24px;font-size:15px;color:#555;">
              ${isNew ? 'A new ticket has been <strong>assigned to you</strong>.' : 'A ticket has been <strong>reassigned to you</strong>.'}
              ${assigned_by ? ` Assigned by <strong>${assigned_by}</strong>.` : ''}
            </p>
            <!-- Ticket Card -->
            <table width="100%" cellpadding="0" cellspacing="0" style="background:#f0f4ff;border-radius:8px;border:1px solid #dce6ff;">
              <tr>
                <td style="padding:20px 24px;">
                  <p style="margin:0 0 4px;font-size:12px;color:#888;text-transform:uppercase;letter-spacing:0.5px;">Ticket</p>
                  <p style="margin:0 0 12px;font-size:20px;font-weight:700;color:#1976d2;">${ticket_number}</p>
                  <p style="margin:0 0 12px;font-size:15px;color:#222;">${ticket_title || ''}</p>
                  <span style="display:inline-block;background:${pColor};color:#fff;padding:4px 12px;border-radius:4px;font-size:12px;font-weight:700;text-transform:uppercase;">
                    ${ticket_priority || 'medium'}
                  </span>
                </td>
              </tr>
            </table>
            <!-- CTA Button -->
            <table width="100%" cellpadding="0" cellspacing="0" style="margin-top:28px;">
              <tr>
                <td align="center">
                  <a href="${APP_URL}" style="display:inline-block;background:#1976d2;color:#ffffff;text-decoration:none;padding:14px 36px;border-radius:6px;font-size:15px;font-weight:700;letter-spacing:0.3px;">
                    View Ticket in App
                  </a>
                </td>
              </tr>
            </table>
          </td>
        </tr>
        <!-- Footer -->
        <tr>
          <td style="background:#f9fafb;padding:18px 32px;border-top:1px solid #eee;">
            <p style="margin:0;font-size:12px;color:#aaa;text-align:center;">
              This is an automated notification from Conectia ERP. Please do not reply to this email.
            </p>
          </td>
        </tr>
      </table>
    </td></tr>
  </table>
</body>
</html>`;

        const res = await fetch('https://api.resend.com/emails', {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${RESEND_API_KEY}`,
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                from: FROM_EMAIL,
                to: [to_email],
                subject,
                html,
            }),
        });

        const result = await res.json();

        if (!res.ok) {
            console.error('Resend error:', result);
            return new Response(JSON.stringify({ error: result }), {
                status: res.status,
                headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
            });
        }

        return new Response(JSON.stringify({ success: true, id: result.id }), {
            status: 200,
            headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
        });
    } catch (err) {
        console.error('Edge function error:', err);
        return new Response(JSON.stringify({ error: String(err) }), {
            status: 500,
            headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
        });
    }
});
