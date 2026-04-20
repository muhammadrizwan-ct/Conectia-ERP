// =============================
// AUTO-REFRESH TICKETS PAGE
// =============================
let ticketsPageAutoRefreshTimer = null;

function setupTicketsPageAutoRefresh() {
    clearTicketsPageAutoRefresh();
    const isTickets = document.querySelector('.nav-item.active')?.textContent.includes('Tickets');
    if (isTickets) {
        ticketsPageAutoRefreshTimer = setInterval(() => {
            // Only refresh if still on Tickets page
            const stillOnTickets = document.querySelector('.nav-item.active')?.textContent.includes('Tickets');
            if (stillOnTickets && typeof loadTickets === 'function') {
                loadTickets();
            } else {
                clearTicketsPageAutoRefresh();
            }
        }, 30000);
    }
}

function clearTicketsPageAutoRefresh() {
    if (ticketsPageAutoRefreshTimer) {
        clearInterval(ticketsPageAutoRefreshTimer);
        ticketsPageAutoRefreshTimer = null;
    }
}
// =============================
// TICKETS MODULE (CLEAN VERSION)
// =============================

var supabase = window.supabaseClient;

// =============================
// CONFIG & STORAGE
// =============================
const TICKETS_LAST_VIEWED_KEY = 'vts_tickets_last_viewed';
const TICKETS_LAST_SEEN_KEY = 'vts_tickets_last_seen';

let ticketDotAutoHideTimer = null;
let ticketsSubscribed = false;
const activePopups = new Set();

// =============================
// LOCAL STORAGE HELPERS
// =============================
function getTicketsLastViewed() {
    try {
        return JSON.parse(localStorage.getItem(TICKETS_LAST_VIEWED_KEY) || '{}');
    } catch {
        return {};
    }
}

function setTicketLastViewed(ticketId) {
    const viewed = getTicketsLastViewed();
    viewed[ticketId] = new Date().toISOString();
    localStorage.setItem(TICKETS_LAST_VIEWED_KEY, JSON.stringify(viewed));
}

function getTicketLastViewed(ticketId) {
    return getTicketsLastViewed()[ticketId] || '1970-01-01T00:00:00Z';
}

function markTicketsSeen() {
    localStorage.setItem(TICKETS_LAST_SEEN_KEY, new Date().toISOString());
    updateTicketsBadge(0);
}

// =============================
// SUPABASE SUBSCRIPTION
// =============================
function subscribeToTicketUpdates() {
    if (ticketsSubscribed || !supabase?.channel) return;
    ticketsSubscribed = true;

    supabase.channel('tickets-changes')
        .on('postgres_changes', { event: '*', schema: 'public', table: 'tickets' }, p =>
            handleRealtime(p, 'ticket')
        )
        .subscribe();

    supabase.channel('ticket-comments-changes')
        .on('postgres_changes', { event: '*', schema: 'public', table: 'ticket_comments' }, p =>
            handleRealtime(p, 'comment')
        )
        .subscribe();
}

// =============================
// REALTIME HANDLER (FIXED)
// =============================
async function handleRealtime(payload, type) {
    const ticketId = payload.new?.id || payload.old?.id;

    if (type === 'comment' && ticketId) {
        await showPopupSafe(ticketId, payload);
        return;
    }

    if (type === 'ticket') {
        const number = payload.new?.ticket_number || '';
        const title = payload.new?.title || '';

        if (payload.eventType === 'INSERT') {
            showToolbarTicketAlert();
        }

        const isOnTickets = document.querySelector('.nav-item.active')?.textContent.includes('Tickets');
        if (isOnTickets) {
            showTicketPopup(
                `Ticket updated: <b>${escapeHtml(number)}</b> - ${escapeHtml(title)}`,
                ticketId
            );
            setupAutoHideDot();
        }
    }
}

// Prevent popup spam
async function showPopupSafe(ticketId, payload) {
    if (activePopups.has(ticketId)) return;

    activePopups.add(ticketId);
    setTimeout(() => activePopups.delete(ticketId), 5000);

    await fetchTicketAndShowPopup(ticketId);
}

// =============================
// TOOLBAR DOTS
// =============================
function showToolbarTicketAlert() {
    let dot = document.getElementById('tickets-alert-dot');

    if (!dot) {
        const parent = document.getElementById('header-actions') || document.body;

        dot = document.createElement('span');
        dot.id = 'tickets-alert-dot';
        dot.className = 'toolbar-alert-dot';
        dot.style.display = 'inline-block';

        parent.appendChild(dot);
    } else {
        dot.style.display = 'inline-block';
    }

    let pageDot = document.getElementById('tickets-page-alert-dot');
    if (!pageDot) {
        const title = document.getElementById('page-title');
        if (title) {
            pageDot = document.createElement('span');
            pageDot.id = 'tickets-page-alert-dot';
            pageDot.className = 'toolbar-alert-dot';
            title.appendChild(pageDot);
        }
    } else {
        pageDot.style.display = 'inline-block';
    }
}

function hideTicketAlertDots() {
    ['tickets-alert-dot', 'tickets-page-alert-dot'].forEach(id => {
        const el = document.getElementById(id);
        if (el) el.style.display = 'none';
    });
}

function setupAutoHideDot() {
    const isTickets = document.querySelector('.nav-item.active')?.textContent.includes('Tickets');
    if (!isTickets) return;

    clearTimeout(ticketDotAutoHideTimer);
    ticketDotAutoHideTimer = setTimeout(hideTicketAlertDots, 20000);
}

// =============================
// FETCH TICKET + COMMENTS FIXED
// =============================
async function fetchTicketActivity(ticketId) {
    const ticket = (window._allTickets || []).find(t => t.id === ticketId)
        || (await supabase.from('tickets').select('*').eq('id', ticketId).single()).data;

    const { data: comment } = await supabase
        .from('ticket_comments')
        .select('created_at')
        .eq('ticket_id', ticketId)
        .order('created_at', { ascending: false })
        .limit(1)
        .single();

    return {
        ticket,
        latestActivity: Math.max(
            new Date(ticket?.updated_at || 0),
            new Date(comment?.created_at || 0)
        )
    };
}

// =============================
// POPUP
// =============================
function showTicketPopup(message, ticketId) {
    const header = document.getElementById('header-actions');
    if (!header) return;

    const existing = document.getElementById('ticket-realtime-popup');
    if (existing) existing.remove();

    const popup = document.createElement('div');
    popup.id = 'ticket-realtime-popup';

    popup.innerHTML = `
        <i class="fas fa-bell"></i>
        <span>${message}</span>
        <button onclick="viewTicketDetail('${ticketId}'); closeTicketPopup();">View</button>
        <button onclick="closeTicketPopup()">Dismiss</button>
    `;

    header.appendChild(popup);
    setTimeout(() => popup.remove(), 15000);
}

window.closeTicketPopup = () => {
    document.getElementById('ticket-realtime-popup')?.remove();
};

// =============================
// COMMENTS SECURITY FIX
// =============================
function isValidImage(file) {
    return file?.type?.startsWith('image/');
}

// =============================
// BADGE SYSTEM (FIXED)
// =============================
async function checkTicketUpdates() {
    try {
        const lastSeen = localStorage.getItem(TICKETS_LAST_SEEN_KEY) || '1970-01-01';

        const { data: tickets } = await supabase
            .from('tickets')
            .select('id')
            .gt('updated_at', lastSeen);

        const { data: comments } = await supabase
            .from('ticket_comments')
            .select('ticket_id')
            .gt('created_at', lastSeen);

        const ids = new Set();

        (tickets || []).forEach(t => ids.add(t.id));
        (comments || []).forEach(c => ids.add(c.ticket_id));

        updateTicketsBadge(ids.size);
    } catch {}
}

function updateTicketsBadge(count) {
    const badge = document.getElementById('tickets-badge');
    if (!badge) return;

    badge.style.display = count ? '' : 'none';
    badge.textContent = count > 99 ? '99+' : count;
}

// =============================
// INTERVAL CLEANUP
// =============================
if (!window._ticketIntervalsInitialized) {
    window._ticketIntervalsInitialized = true;

    setInterval(() => {
        if (Auth?.isLoggedIn?.()) checkTicketUpdates();
    }, 10000);
}

// =============================
// INIT SUBSCRIPTION SAFE
// =============================
setTimeout(subscribeToTicketUpdates, 2000);

// =============================
// GLOBAL EXPORTS
// =============================
window.markTicketsSeen = markTicketsSeen;
window.checkTicketUpdates = checkTicketUpdates;
window.showToolbarTicketAlert = showToolbarTicketAlert;
window.hideTicketAlertDots = hideTicketAlertDots;
window.setupTicketsPageAutoRefresh = setupTicketsPageAutoRefresh;
window.clearTicketsPageAutoRefresh = clearTicketsPageAutoRefresh;
// =============================
// INIT AUTO-REFRESH ON PAGE LOAD
// =============================
document.addEventListener('DOMContentLoaded', () => {
    // Try to set up auto-refresh if on Tickets page
    setupTicketsPageAutoRefresh();
    // Also re-setup auto-refresh whenever navigation occurs
    document.body.addEventListener('click', function (e) {
        // If a nav-item is clicked, re-setup auto-refresh
        if (e.target.closest('.nav-item')) {
            setTimeout(setupTicketsPageAutoRefresh, 500);
        }
    });
});
