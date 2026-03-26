// Input Constraints — real-time sanitization and character limits
// Attach to dynamically created inputs via applyInputConstraints()

const INPUT_RULES = {
    // Name fields (person, company, employee)
    name:       { maxLength: 60,  pattern: /[^a-zA-Z\s.\-']/g,         placeholder: 'Letters, spaces, dots, hyphens' },
    // Email
    email:      { maxLength: 254, pattern: /[^a-zA-Z0-9@.\-_+]/g,     placeholder: 'Valid email address' },
    // Phone
    phone:      { maxLength: 15,  pattern: /[^0-9+\-\s]/g,            placeholder: 'Digits, +, -, spaces' },
    // Address
    address:    { maxLength: 200, pattern: /[^a-zA-Z0-9\s,.\-#/()]/g, placeholder: 'Address characters only' },
    // NTN / tax ID
    ntn:        { maxLength: 30,  pattern: /[^a-zA-Z0-9\-/]/g,        placeholder: 'Alphanumeric, -, /' },
    // Vehicle registration / plate
    regNumber:  { maxLength: 20,  pattern: /[^a-zA-Z0-9\-\s]/g,       placeholder: 'Letters, digits, hyphens' },
    // Brand / make
    brand:      { maxLength: 40,  pattern: /[^a-zA-Z0-9\s.\-&]/g,     placeholder: 'Brand name' },
    // Model
    model:      { maxLength: 40,  pattern: /[^a-zA-Z0-9\s.\-/()]/g,   placeholder: 'Model name' },
    // IMEI
    imei:       { maxLength: 20,  pattern: /[^0-9]/g,                  placeholder: 'Digits only' },
    // SIM number
    sim:        { maxLength: 25,  pattern: /[^0-9+\-]/g,              placeholder: 'Digits, +, -' },
    // Year (4 digits)
    year:       { maxLength: 4,   pattern: /[^0-9]/g,                  placeholder: 'e.g. 2026' },
    // Currency amount
    amount:     { maxLength: 15,  pattern: /[^0-9.]/g,                 placeholder: '0.00' },
    // Invoice number / reference
    invoiceNo:  { maxLength: 40,  pattern: /[^a-zA-Z0-9\-/#]/g,       placeholder: 'Invoice/ref number' },
    // Username
    username:   { maxLength: 40,  pattern: /[^a-zA-Z0-9._\-@]/g,      placeholder: 'Letters, digits, ._-@' },
    // Password
    password:   { maxLength: 128, pattern: null,                       placeholder: '' },
    // Notes / comments
    notes:      { maxLength: 300, pattern: /[^\w\s,.\-!?@#()/:;'"&+=%$]/g, placeholder: 'Short notes' },
    // Fleet / department / category name
    category:   { maxLength: 50,  pattern: /[^a-zA-Z0-9\s.\-&_]/g,    placeholder: 'Category name' },
    // Search fields
    search:     { maxLength: 100, pattern: null,                       placeholder: 'Search...' },
    // Working days (integer)
    days:       { maxLength: 3,   pattern: /[^0-9]/g,                  placeholder: '0-366' },
    // OTP
    otp:        { maxLength: 10,  pattern: /[^0-9]/g,                  placeholder: 'Digits only' },
};

// Apply a single rule to an input element
function applyRule(inputEl, ruleName) {
    const rule = INPUT_RULES[ruleName];
    if (!rule || !inputEl) return;

    // Set maxlength
    inputEl.setAttribute('maxlength', rule.maxLength);

    // Real-time sanitization on input
    if (rule.pattern) {
        inputEl.addEventListener('input', function () {
            const pos = this.selectionStart;
            const before = this.value;
            this.value = before.replace(rule.pattern, '');
            // Restore cursor position
            if (this.value.length < before.length) {
                this.setSelectionRange(pos - (before.length - this.value.length), pos - (before.length - this.value.length));
            }
        });

        // Also sanitize on paste
        inputEl.addEventListener('paste', function () {
            setTimeout(() => {
                this.value = this.value.replace(rule.pattern, '').slice(0, rule.maxLength);
            }, 0);
        });
    }

    // Amount fields: prevent multiple dots
    if (ruleName === 'amount') {
        inputEl.addEventListener('input', function () {
            let v = this.value.replace(/[^0-9.]/g, '');
            const parts = v.split('.');
            if (parts.length > 2) {
                v = parts[0] + '.' + parts.slice(1).join('');
            }
            if (parts.length === 2 && parts[1].length > 2) {
                v = parts[0] + '.' + parts[1].slice(0, 2);
            }
            this.value = v.slice(0, rule.maxLength);
        });
    }

    // Email: lowercase on input
    if (ruleName === 'email') {
        inputEl.addEventListener('input', function () {
            this.value = this.value.toLowerCase();
        });
    }

    // Reg number: uppercase on input
    if (ruleName === 'regNumber') {
        inputEl.addEventListener('input', function () {
            this.value = this.value.toUpperCase();
        });
    }
}

// Apply constraints to multiple fields at once
// fieldMap: { 'element-id': 'ruleName', ... }
function applyInputConstraints(fieldMap) {
    for (const [id, ruleName] of Object.entries(fieldMap)) {
        const el = document.getElementById(id);
        if (el) {
            applyRule(el, ruleName);
        }
    }
}

// Validate a value against a rule, returns { valid: boolean, message: string }
function validateField(value, ruleName, label) {
    const rule = INPUT_RULES[ruleName];
    if (!rule) return { valid: true, message: '' };

    const v = String(value || '').trim();
    if (v.length > rule.maxLength) {
        return { valid: false, message: `${label} must be ${rule.maxLength} characters or less.` };
    }
    if (rule.pattern && rule.pattern.test(v)) {
        return { valid: false, message: `${label} contains invalid characters.` };
    }
    return { valid: true, message: '' };
}

window.INPUT_RULES = INPUT_RULES;
window.applyRule = applyRule;
window.applyInputConstraints = applyInputConstraints;
window.validateField = validateField;
