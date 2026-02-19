const API_URL = '/api/contacts';

// DOM Elements
const contactsList = document.getElementById('contactsList');
const searchInput = document.getElementById('searchInput');
const searchBtn = document.getElementById('searchBtn');
const addContactBtn = document.getElementById('addContactBtn');
const contactModal = document.getElementById('contactModal');
const contactForm = document.getElementById('contactForm');
const modalTitle = document.getElementById('modalTitle');
const cancelBtn = document.getElementById('cancelBtn');
const emptyState = document.getElementById('emptyState');

// State
let isEditing = false;
let currentContactId = null;

// Initialization
document.addEventListener('DOMContentLoaded', async () => {
    try {
        const response = await fetch('/api/health');
        if (!response.ok) throw new Error('Health check failed');
        fetchContacts();
    } catch (e) {
        window.location.href = 'maintenance.html';
    }
});

// Event Listeners
addContactBtn.addEventListener('click', () => openModal());
cancelBtn.addEventListener('click', closeModal);
searchBtn.addEventListener('click', () => fetchContacts(searchInput.value));
searchInput.addEventListener('keyup', (e) => {
    if (e.key === 'Enter') {
        fetchContacts(searchInput.value);
    }
});

// Event Delegation for Edit/Delete
contactsList.addEventListener('click', (e) => {
    const target = e.target.closest('.action-btn');
    if (!target) return;

    if (target.classList.contains('edit')) {
        const contact = {
            id: target.dataset.id,
            name: target.dataset.name,
            phone: target.dataset.phone,
            email: target.dataset.email,
            address: target.dataset.address
        };
        openModal(contact);
    } else if (target.classList.contains('delete')) {
        deleteContact(target.dataset.id);
    }
});

contactForm.addEventListener('submit', async (e) => {
    e.preventDefault();
    const contactData = {
        name: document.getElementById('name').value,
        phone: document.getElementById('phone').value,
        email: document.getElementById('email').value,
        address: document.getElementById('address').value
    };

    if (isEditing) {
        await updateContact(currentContactId, contactData);
    } else {
        await createContact(contactData);
    }
    closeModal();
    fetchContacts();
});

// API Calls
async function fetchContacts(search = '') {
    try {
        let url = API_URL;
        if (search) {
            url += `?search=${encodeURIComponent(search)}`;
        }
        const response = await fetch(url);
        const contacts = await response.json();
        renderContacts(contacts);
    } catch (error) {
        console.error('Error fetching contacts:', error);
    }
}

async function createContact(data) {
    try {
        console.log('Sending POST request to:', API_URL, 'with data:', data);
        const response = await fetch(API_URL, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(data)
        });
        if (!response.ok) {
            const errText = await response.text();
            throw new Error(`Server responded with ${response.status}: ${errText}`);
        }
        return await response.json();
    } catch (error) {
        console.error('Error creating contact:', error);
        alert(`Failed to create contact: ${error.message}`);
    }
}


async function updateContact(id, data) {
    try {
        const response = await fetch(`${API_URL}/${id}`, {
            method: 'PUT',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(data)
        });
        if (!response.ok) throw new Error('Failed to update contact');
        return await response.json();
    } catch (error) {
        console.error('Error updating contact:', error);
        alert('Failed to update contact');
    }
}

async function deleteContact(id) {
    if (!confirm('Are you sure you want to delete this contact?')) return;
    try {
        const response = await fetch(`${API_URL}/${id}`, {
            method: 'DELETE'
        });
        if (!response.ok) throw new Error('Failed to delete contact');
        fetchContacts();
    } catch (error) {
        console.error('Error deleting contact:', error);
        alert('Failed to delete contact');
    }
}

// UI Functions
function renderContacts(contacts) {
    contactsList.innerHTML = '';

    if (contacts.length === 0) {
        emptyState.classList.remove('hidden');
        return;
    }

    emptyState.classList.add('hidden');

    contacts.forEach(contact => {
        const card = document.createElement('div');
        card.className = 'contact-card';
        card.innerHTML = `
            <div class="contact-header">
                <div class="avatar">${getInitials(contact.name)}</div>
                <div class="contact-info">
                    <h3>${escapeHtml(contact.name)}</h3>
                </div>
            </div>
            <div class="contact-details">
                ${contact.phone ? `<div class="detail-item">📞 ${escapeHtml(contact.phone)}</div>` : ''}
                ${contact.email ? `<div class="detail-item">✉️ ${escapeHtml(contact.email)}</div>` : ''}
                ${contact.address ? `<div class="detail-item">📍 ${escapeHtml(contact.address)}</div>` : ''}
            </div>
            <div class="card-actions">
                <button class="action-btn edit" 
                    data-id="${contact.id}"
                    data-name="${escapeHtml(contact.name)}"
                    data-phone="${escapeHtml(contact.phone || '')}"
                    data-email="${escapeHtml(contact.email || '')}"
                    data-address="${escapeHtml(contact.address || '')}">
                    Edit
                </button>
                <button class="action-btn delete" data-id="${contact.id}">Delete</button>
            </div>
        `;
        contactsList.appendChild(card);
    });
}

function openModal(contact = null) {
    contactModal.classList.add('active');
    if (contact) {
        isEditing = true;
        currentContactId = contact.id;
        modalTitle.textContent = 'Edit Contact';
        document.getElementById('name').value = contact.name;
        document.getElementById('phone').value = contact.phone;
        document.getElementById('email').value = contact.email;
        document.getElementById('address').value = contact.address;
    } else {
        isEditing = false;
        currentContactId = null;
        modalTitle.textContent = 'Add Contact';
        contactForm.reset();
    }
}

function closeModal() {
    contactModal.classList.remove('active');
}

// Helpers
function getInitials(name) {
    return name
        .split(' ')
        .map(n => n[0])
        .slice(0, 2)
        .join('')
        .toUpperCase();
}

function escapeHtml(text) {
    if (!text) return '';
    return text
        .replace(/&/g, "&amp;")
        .replace(/</g, "&lt;")
        .replace(/>/g, "&gt;")
        .replace(/"/g, "&quot;")
        .replace(/'/g, "&#039;");
}
