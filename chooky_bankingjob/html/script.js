// Variables globales
let currentSection = 'accounts';
let accountsData = [];
let loansData = [];
let pendingTransaction = null;

// Funciones de utilidad
function formatMoney(amount) {
    return '$' + parseInt(amount).toLocaleString();
}

function formatDate(timestamp) {
    if (!timestamp) return 'N/A';
    return new Date(timestamp * 1000).toLocaleDateString('es-ES');
}

function formatTimeAgo(timestamp) {
    if (!timestamp) return 'Nunca';
    const now = Math.floor(Date.now() / 1000);
    const diff = now - timestamp;
    
    if (diff < 60) return 'Hace unos segundos';
    if (diff < 3600) return `Hace ${Math.floor(diff / 60)} minutos`;
    if (diff < 86400) return `Hace ${Math.floor(diff / 3600)} horas`;
    return `Hace ${Math.floor(diff / 86400)} días`;
}

// Funciones de la UI
function closeUI() {
    document.getElementById('bankingUI').style.display = 'none';
    fetch(`https://${GetParentResourceName()}/closeUI`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({})
    });
}

function showSection(sectionName) {
    // Ocultar todas las secciones
    document.querySelectorAll('.section').forEach(section => {
        section.classList.remove('active');
    });
    
    // Mostrar la sección seleccionada
    document.getElementById(sectionName + '-section').classList.add('active');
    
    // Actualizar navegación
    document.querySelectorAll('.nav-item').forEach(item => {
        item.classList.remove('active');
    });
    event.target.classList.add('active');
    
    currentSection = sectionName;
}

function refreshData() {
    fetch(`https://${GetParentResourceName()}/refreshData`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({})
    });
    
    showNotification('Datos actualizados', 'success');
}

// Funciones de cuentas
function updateAccounts(accounts) {
    accountsData = accounts;
    const grid = document.getElementById('accountsGrid');
    if (!grid) return;

    if (accounts.length === 0) {
        grid.innerHTML = `
            <div class="empty-state">
                <i class="fas fa-users"></i>
                <h3>No hay cuentas disponibles</h3>
                <p>No se encontraron cuentas bancarias en el sistema.</p>
            </div>
        `;
        return;
    }

    grid.innerHTML = accounts.map(account => `
        <div class="account-card">
            <div class="account-header">
                <div class="account-avatar">
                    <i class="fas fa-user"></i>
                </div>
                <div class="account-info">
                    <h3>${account.name}</h3>
                    <span class="account-id">ID para transacciones: ${account.source}</span>
                </div>
                <div class="account-balance">
                    <span class="balance-amount">${formatMoney(account.bank)}</span>
                </div>
            </div>
            <!-- Sin botones -->
        </div>
    `).join('');
}

function searchPlayer() {
    const searchTerm = document.getElementById('searchInput').value.toLowerCase();
    
    if (!searchTerm) {
        updateAccounts(accountsData);
        return;
    }
    
    const filteredAccounts = accountsData.filter(account => 
        account.name && account.name.toLowerCase().includes(searchTerm)
    );
    
    updateAccounts(filteredAccounts);
}

// Funciones de transacciones
function prepareTransaction(type, targetId) {
    document.getElementById('transactionTargetId').value = targetId;
    document.getElementById('transactionType').value = type;
    document.getElementById('transactionAmount').focus();
    
    showSection('transactions');
}

function executeTransaction() {
    const targetId = document.getElementById('transactionTargetId').value;
    const type = document.getElementById('transactionType').value;
    const amount = document.getElementById('transactionAmount').value;
    const reason = document.getElementById('transactionReason').value;
    
    if (!targetId || !amount || amount <= 0) {
        showNotification('Por favor completa todos los campos', 'error');
        return;
    }
    
    const data = {
        targetId: parseInt(targetId),
        amount: parseInt(amount),
        reason: reason || 'Sin razón especificada'
    };
    
    fetch(`https://${GetParentResourceName()}/${type === 'withdraw' ? 'withdrawMoney' : 'depositMoney'}`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify(data)
    });
    
    // Limpiar formulario
    document.getElementById('transactionAmount').value = '';
    document.getElementById('transactionReason').value = '';
}

// Funciones de préstamos
function prepareLoan(targetId) {
    document.getElementById('loanTargetId').value = targetId;
    document.getElementById('loanAmount').focus();
    
    showSection('loans');
}

function giveLoan() {
    const targetId = document.getElementById('loanTargetId').value;
    const amount = document.getElementById('loanAmount').value;
    const duration = document.getElementById('loanDuration').value;
    const interest = document.getElementById('loanInterest').value;
    
    if (!targetId || !amount || amount <= 0) {
        showNotification('Por favor completa todos los campos requeridos', 'error');
        return;
    }
    
    const data = {
        targetId: parseInt(targetId),
        amount: parseInt(amount),
        duration: parseInt(duration) || 30,
        interest: parseFloat(interest) || 5
    };
    
    fetch(`https://${GetParentResourceName()}/giveLoan`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify(data)
    });
    
    // Limpiar formulario
    document.getElementById('loanAmount').value = '';
    document.getElementById('loanDuration').value = '30';
    document.getElementById('loanInterest').value = '5';
}

function updateLoans(loans) {
    loansData = loans;
    const list = document.getElementById('loansList');
    
    if (loans.length === 0) {
        list.innerHTML = `
            <div class="empty-state">
                <i class="fas fa-hand-holding-usd"></i>
                <h3>No hay préstamos activos</h3>
                <p>No se encontraron préstamos en el sistema.</p>
            </div>
        `;
        return;
    }
    
    list.innerHTML = loans.map(loan => {
        const isOverdue = loan.due_date < Math.floor(Date.now() / 1000) && loan.status === 'active';
        const statusClass = isOverdue ? 'status-overdue' : `status-${loan.status}`;
        
        return `
            <div class="loan-card ${statusClass}">
                <div class="loan-header">
                    <div class="loan-info">
                        <h3>${loan.borrower}</h3>
                        <span class="loan-id">ID: ${loan.borrower_id}</span>
                    </div>
                    <div class="loan-status ${statusClass}">
                        ${loan.status === 'active' ? (isOverdue ? 'VENCIDO' : 'ACTIVO') : 'PAGADO'}
                    </div>
                </div>
                <div class="loan-details">
                    <div class="detail-item">
                        <span>Monto Original:</span>
                        <span class="amount">${formatMoney(loan.amount)}</span>
                    </div>
                    <div class="detail-item">
                        <span>Monto Total:</span>
                        <span class="amount">${formatMoney(loan.total_amount)}</span>
                    </div>
                    <div class="detail-item">
                        <span>Interés:</span>
                        <span>${(loan.interest * 100).toFixed(1)}%</span>
                    </div>
                    <div class="detail-item">
                        <span>Vence:</span>
                        <span>${formatDate(loan.due_date)}</span>
                    </div>
                    <div class="detail-item">
                        <span>Otorgado por:</span>
                        <span>${loan.given_by}</span>
                    </div>
                </div>
                ${loan.status === 'active' ? `
                    <div class="loan-actions">
                        <button class="btn-success" onclick="payLoan(${loan.id})">
                            <i class="fas fa-check"></i> Marcar como Pagado
                        </button>
                    </div>
                ` : ''}
            </div>
        `;
    }).join('');
}

function payLoan(loanId) {
    fetch(`https://${GetParentResourceName()}/payLoan`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({ loanId: loanId })
    });
}

// Modal de confirmación
function showConfirmation(type, data) {
    const modal = document.getElementById('confirmationModal');
    const details = document.getElementById('confirmationDetails');
    const confirmBtn = document.getElementById('confirmButton');
    
    let detailsHTML = '';
    if (type === 'withdraw') {
        detailsHTML = `
            <div class="detail-item">
                <span>Tipo:</span>
                <span>Retiro</span>
            </div>
            <div class="detail-item">
                <span>ID Ciudadano:</span>
                <span>${data.targetId}</span>
            </div>
            <div class="detail-item">
                <span>Cantidad:</span>
                <span class="amount">${formatMoney(data.amount)}</span>
            </div>
            <div class="detail-item">
                <span>Razón:</span>
                <span>${data.reason}</span>
            </div>
        `;
    } else if (type === 'deposit') {
        detailsHTML = `
            <div class="detail-item">
                <span>Tipo:</span>
                <span>Depósito</span>
            </div>
            <div class="detail-item">
                <span>ID Ciudadanor:</span>
                <span>${data.targetId}</span>
            </div>
            <div class="detail-item">
                <span>Cantidad:</span>
                <span class="amount">${formatMoney(data.amount)}</span>
            </div>
            <div class="detail-item">
                <span>Razón:</span>
                <span>${data.reason}</span>
            </div>
        `;
    }
    
    details.innerHTML = detailsHTML;
    
    confirmBtn.onclick = () => {
        closeConfirmation();
        const eventName = type === 'withdraw' ? 'withdrawMoney' : 'depositMoney';
        fetch(`https://${GetParentResourceName()}/${eventName}`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(data)
        });
    };
    
    modal.style.display = 'flex';
}

function closeConfirmation() {
    document.getElementById('confirmationModal').style.display = 'none';
}

// Funciones de configuración
function viewLogs() {
    showNotification('Función de logs no implementada aún', 'info');
}

function showNotification(message, type) {
    // Crear notificación temporal
    const notification = document.createElement('div');
    notification.className = `notification ${type}`;
    notification.innerHTML = `
        <i class="fas ${type === 'success' ? 'fa-check-circle' : type === 'error' ? 'fa-exclamation-circle' : 'fa-info-circle'}"></i>
        <span>${message}</span>
    `;
    
    document.body.appendChild(notification);
    
    setTimeout(() => {
        notification.classList.add('show');
    }, 100);
    
    setTimeout(() => {
        notification.classList.remove('show');
        setTimeout(() => {
            document.body.removeChild(notification);
        }, 300);
    }, 3000);
}

// Eventos NUI
window.addEventListener('message', function(event) {
    const data = event.data;
    
    switch (data.action) {
        case 'showUI':
            document.getElementById('bankingUI').style.display = 'flex';
            if (data.theme) {
                document.body.className = data.theme;
            }
            break;
            
        case 'updateAccounts':
            updateAccounts(data.accounts);
            break;
            
        case 'updateLoans':
            updateLoans(data.loans);
            break;
            
        case 'updateSearchResults':
            updateAccounts(data.accounts);
            break;
            
        case 'hideUI':
            document.getElementById('bankingUI').style.display = 'none';
            break;
            
        case 'showConfirmation':
            showConfirmation(data.type, data.data);
            break;
    }
});

// Cerrar modal al hacer clic fuera
window.onclick = function(event) {
    const modal = document.getElementById('confirmationModal');
    if (event.target === modal) {
        closeConfirmation();
    }
}

// Prevenir envío de formularios con Enter
document.addEventListener('keydown', function(event) {
    if (event.key === 'Enter') {
        event.preventDefault();
    }
    
    if (event.key === 'Escape') {
        closeUI();
        closeConfirmation();
    }
});