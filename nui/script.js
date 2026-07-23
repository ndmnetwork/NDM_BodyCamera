/* ─────────────────────────────────────────────────────────────────────────────
   NDM Body Camera — NUI Script
   Handles:
     • NUI message routing (open / close)
     • Live clock (updated every second)
     • Drag-to-move widget with localStorage position persistence
     • ESC / close callback to Lua
   ───────────────────────────────────────────────────────────────────────────── */

'use strict';

// ── Element references ────────────────────────────────────────────────────────
const overlay   = document.getElementById('bodycam-overlay');
const widget    = document.getElementById('cam-widget');
const header    = document.getElementById('widget-header');
const datetimeEl = document.getElementById('datetime');

// Info fields
const officerNameEl   = document.getElementById('officer-name');
const callsignEl      = document.getElementById('officer-callsign');
const departmentEl    = document.getElementById('officer-department');
const serialEl        = document.getElementById('cam-serial');

// Label fields
const labelRecEl      = document.getElementById('label-rec');
const labelOfficerEl  = document.getElementById('label-officer');
const labelBadgeEl    = document.getElementById('label-badge');
const labelDeptEl     = document.getElementById('label-dept');
const labelSerialEl   = document.getElementById('label-serial');

// ── Clock ─────────────────────────────────────────────────────────────────────
let clockInterval = null;

function padTwo(n) {
    return String(n).padStart(2, '0');
}

function formatDatetime(d) {
    const date = `${d.getFullYear()}-${padTwo(d.getMonth() + 1)}-${padTwo(d.getDate())}`;
    const time = `${padTwo(d.getHours())}:${padTwo(d.getMinutes())}:${padTwo(d.getSeconds())}`;
    return `${date}  ${time}`;
}

function startClock() {
    datetimeEl.textContent = formatDatetime(new Date());
    clockInterval = setInterval(() => {
        datetimeEl.textContent = formatDatetime(new Date());
    }, 1000);
}

function stopClock() {
    clearInterval(clockInterval);
    clockInterval = null;
    datetimeEl.textContent = '';
}

// ── Widget position ───────────────────────────────────────────────────────────
const POSITION_KEY = 'ndm_bodycam_widget_pos';

function savePosition(x, y) {
    localStorage.setItem(POSITION_KEY, JSON.stringify({ x, y }));
}

function restorePosition() {
    try {
        const raw = localStorage.getItem(POSITION_KEY);
        if (!raw) return;
        const { x, y } = JSON.parse(raw);
        applyPosition(x, y);
    } catch (_) { /* ignore */ }
}

function applyPosition(x, y) {
    // Clamp so widget never leaves the viewport
    const maxX = window.innerWidth  - widget.offsetWidth  - 4;
    const maxY = window.innerHeight - widget.offsetHeight - 4;
    widget.style.left = Math.max(0, Math.min(x, maxX)) + 'px';
    widget.style.top  = Math.max(0, Math.min(y, maxY)) + 'px';
}

// ── Drag-to-move logic ────────────────────────────────────────────────────────
let dragging   = false;
let dragOffsetX = 0;
let dragOffsetY = 0;

header.addEventListener('mousedown', (e) => {
    if (e.button !== 0) return;   // left button only
    dragging   = true;
    const rect = widget.getBoundingClientRect();
    dragOffsetX = e.clientX - rect.left;
    dragOffsetY = e.clientY - rect.top;
    e.preventDefault();
});

document.addEventListener('mousemove', (e) => {
    if (!dragging) return;
    const x = e.clientX - dragOffsetX;
    const y = e.clientY - dragOffsetY;
    applyPosition(x, y);
});

document.addEventListener('mouseup', (e) => {
    if (!dragging || e.button !== 0) return;
    dragging = false;
    const rect = widget.getBoundingClientRect();
    savePosition(rect.left, rect.top);
});

// ── Camera open / close ───────────────────────────────────────────────────────
function openCamera(data) {
    const labels = data.labels || {};

    // Apply custom labels
    if (labels.rec)       labelRecEl.textContent     = labels.rec;
    if (labels.officer)   labelOfficerEl.textContent = labels.officer;
    if (labels.badge)     labelBadgeEl.textContent   = labels.badge;
    if (labels.department) labelDeptEl.textContent   = labels.department;
    if (labels.serial)    labelSerialEl.textContent  = labels.serial;

    // Populate officer info
    officerNameEl.textContent  = data.officerName  || '—';
    callsignEl.textContent     = data.callsign     || 'N/A';
    departmentEl.textContent   = data.department   || '—';
    serialEl.textContent       = data.serial       || '—';

    // Restore saved widget position (so it stays where the user left it)
    restorePosition();

    overlay.classList.remove('hidden');
    startClock();
}

function closeCamera() {
    overlay.classList.add('hidden');
    stopClock();
}

// ── NUI message listener ──────────────────────────────────────────────────────
window.addEventListener('message', (event) => {
    const data = event.data;
    if (!data || !data.type) return;

    switch (data.type) {
        case 'openCamera':
            openCamera(data);
            break;
        case 'closeCamera':
            closeCamera();
            break;
        default:
            break;
    }
});

// ── ESC key — notify Lua to close the camera ──────────────────────────────────
document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && !overlay.classList.contains('hidden')) {
        closeCamera();
        fetch(`https://${GetParentResourceName()}/closeCamera`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({}),
        }).catch(() => {});
    }
});
