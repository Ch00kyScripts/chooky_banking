ESX = exports['es_extended']:getSharedObject()
local transactionsCache = {}
local loansCache = {}

-- Nombre de la cuenta de la sociedad
local SOCIETY_ACCOUNT_NAME = 'society_bankero'

-- Obtiene la cuenta de la sociedad (callback)
local function GetSocietyAccount(cb)
    TriggerEvent('esx_addonaccount:getSharedAccount', SOCIETY_ACCOUNT_NAME, function(account)
        cb(account)
    end)
end

-- Envío a Discord (si Config.Webhook está definido)
local function sendToDiscord(title, description, color)
    if not Config or not Config.EnableLogs or not Config.Webhook or Config.Webhook == '' then
        return
    end

    local embed = {
        {
            ["title"] = title,
            ["description"] = description,
            ["color"] = color or 3447003,
            ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ", os.time())
        }
    }

    PerformHttpRequest(Config.Webhook, function(err, text, headers)
        if err and err ~= 200 and err ~= 204 then
            print(('[esx_banking] sendToDiscord err: %s'):format(tostring(err)))
        end
    end, 'POST', json.encode({ username = "BANKING LOGS", embeds = embed }), { ['Content-Type'] = 'application/json' })
end

-- Función para verificar permisos (usa tu Config tal cual)
function HasBankingPermission(source, action, amount)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return false end

    if xPlayer.job.name ~= Config.BankerJob then
        return false
    end

    local grade = xPlayer.job.grade
    local gradeConfig = Config.Grades[grade]

    if not gradeConfig then return false end

    if action == 'view' then
        return gradeConfig.canView
    elseif action == 'withdraw' then
        return gradeConfig.canWithdraw and amount <= gradeConfig.maxAmount
    elseif action == 'deposit' then
        return gradeConfig.canDeposit and amount <= gradeConfig.maxAmount
    elseif action == 'loan' then
        return gradeConfig.canGiveLoans and amount <= Config.MaxLoan
    end

    return false
end

-- Función para registrar logs en DB y enviar a Discord
function LogTransaction(source, target, action, amount, reason)
    if not Config.EnableLogs then return end

    local xPlayer = ESX.GetPlayerFromId(source)
    local targetPlayer = ESX.GetPlayerFromId(target)

    local logData = {
        timestamp = os.time(),
        banker = xPlayer and xPlayer.getName() or 'Unknown',
        bankerId = source,
        target = targetPlayer and targetPlayer.getName() or 'Unknown',
        targetId = target,
        action = action,
        amount = amount,
        reason = reason or 'No reason provided'
    }

    -- Insertar en tabla de logs
    MySQL.insert('INSERT INTO banking_logs (banker, banker_id, target, target_id, action, amount, reason, timestamp) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', {
        logData.banker,
        logData.bankerId,
        logData.target,
        logData.targetId,
        logData.action,
        logData.amount,
        logData.reason,
        logData.timestamp
    })

    -- Discord
    local title = ("[Banking] %s"):format(action)
    local desc = string.format("**Banquero:** %s (ID: %s)\n**Ciudadano:** %s (ID: %s)\n**Acción:** %s\n**Cantidad:** %s\n**Razón:** %s\n**Fecha:** %s",
        logData.banker, logData.bankerId, logData.target, logData.targetId, action, tostring(amount), logData.reason, os.date("%Y-%m-%d %H:%M:%S", logData.timestamp))
    sendToDiscord(title, desc)

    -- También consola (como placeholder)
    if Config.LogChannel then
        print(string.format('[BANKING LOG] %s - %s %s $%s de/a %s - Razón: %s',
            logData.banker, logData.action, Config.UI and Config.UI.Currency or '', logData.amount, logData.target, logData.reason))
    end
end

-- Límite de transacciones por minuto por usuario
function CheckTransactionLimit(source)
    local currentTime = os.time()
    transactionsCache[source] = transactionsCache[source] or {}

    for i = #transactionsCache[source], 1, -1 do
        if currentTime - transactionsCache[source][i] > 60 then
            table.remove(transactionsCache[source], i)
        end
    end

    if #transactionsCache[source] >= Config.MaxTransactionsPerMinute then
        return false
    end

    table.insert(transactionsCache[source], currentTime)
    return true
end

-- Obtener cuentas de jugadores conectados (para UI)
RegisterNetEvent('esx_banking:getAccounts', function()
    local src = source

    if not HasBankingPermission(src, 'view', 0) then
        TriggerClientEvent('esx:showNotification', src, 'No tienes permisos para acceder al sistema bancario')
        return
    end

    if not CheckTransactionLimit(src) then
        TriggerClientEvent('esx:showNotification', src, 'Has excedido el límite de transacciones')
        return
    end

    local accounts = {}
    local players = ESX.GetExtendedPlayers()

    for _, xPlayer in ipairs(players) do
        local identifier = xPlayer.identifier
        local accountsData = xPlayer.getAccounts()

        for _, account in ipairs(accountsData) do
            if account.name == 'bank' then
                table.insert(accounts, {
                    identifier = identifier,
                    name = xPlayer.getName(),
                    bank = account.money,
                    source = xPlayer.source
                })
                break
            end
        end
    end

    TriggerClientEvent('esx_banking:receiveAccounts', src, accounts)
end)

-- RETIRAR: la sociedad entrega dinero y ese importe se añade al account 'bank' del jugador
RegisterNetEvent('esx_banking:withdrawMoney', function(targetId, amount, reason)
    local src = source
    amount = tonumber(amount)

    if not amount or amount <= 0 then
        TriggerClientEvent('esx:showNotification', src, 'Cantidad inválida')
        return
    end

    if not HasBankingPermission(src, 'withdraw', amount) then
        TriggerClientEvent('esx:showNotification', src, 'No tienes permisos para retirar esa cantidad')
        return
    end

    if not CheckTransactionLimit(src) then
        TriggerClientEvent('esx:showNotification', src, 'Has excedido el límite de transacciones')
        return
    end

    local targetPlayer = ESX.GetPlayerFromId(targetId)
    if not targetPlayer then
        TriggerClientEvent('esx:showNotification', src, 'Jugador no encontrado')
        return
    end

    GetSocietyAccount(function(account)
        if not account then
            TriggerClientEvent('esx:showNotification', src, 'Error con la cuenta de la sociedad')
            return
        end

        if account.money < amount then
            TriggerClientEvent('esx:showNotification', src, 'La sociedad no tiene suficiente dinero')
            return
        end

        account.removeMoney(amount)
        targetPlayer.addAccountMoney('bank', amount)
        LogTransaction(src, targetId, 'withdraw', amount, reason)

        TriggerClientEvent('esx:showNotification', src, string.format('Has retirado $%s y se ha añadido al banco de %s', amount, targetPlayer.getName()))
        TriggerClientEvent('esx:showNotification', targetId, string.format('Se te ha añadido $%s a tu cuenta bancaria', amount))

        TriggerEvent('esx_banking:getAccounts', src)
    end)
end)

-- DEPOSITAR: quitar dinero del account 'bank' del jugador y añadirlo a la sociedad
RegisterNetEvent('esx_banking:depositMoney', function(targetId, amount, reason)
    local src = source
    amount = tonumber(amount)

    if not amount or amount <= 0 then
        TriggerClientEvent('esx:showNotification', src, 'Cantidad inválida')
        return
    end

    if not HasBankingPermission(src, 'deposit', amount) then
        TriggerClientEvent('esx:showNotification', src, 'No tienes permisos para depositar esa cantidad')
        return
    end

    if not CheckTransactionLimit(src) then
        TriggerClientEvent('esx:showNotification', src, 'Has excedido el límite de transacciones')
        return
    end

    local targetPlayer = ESX.GetPlayerFromId(targetId)
    if not targetPlayer then
        TriggerClientEvent('esx:showNotification', src, 'Jugador no encontrado')
        return
    end

    if targetPlayer.getAccount('bank').money < amount then
        TriggerClientEvent('esx:showNotification', src, 'El jugador no tiene suficiente dinero en su banco')
        return
    end

    targetPlayer.removeAccountMoney('bank', amount)

    GetSocietyAccount(function(account)
        if not account then
            TriggerClientEvent('esx:showNotification', src, 'Error con la cuenta de la sociedad')
            return
        end

        account.addMoney(amount)
        LogTransaction(src, targetId, 'deposit', amount, reason)

        TriggerClientEvent('esx:showNotification', src, string.format('Has movido $%s del banco de %s a la sociedad', amount, targetPlayer.getName()))
        TriggerClientEvent('esx:showNotification', targetId, string.format('Se te han descontado $%s de tu cuenta bancaria', amount))

        TriggerEvent('esx_banking:getAccounts', src)
    end)
end)

-- DAR PRÉSTAMO: la sociedad presta el dinero → se añade al account 'bank' del jugador
RegisterNetEvent('esx_banking:giveLoan', function(targetId, amount, duration, interest)
    local src = source
    amount = tonumber(amount)
    duration = tonumber(duration) or Config.LoanDuration
    interest = tonumber(interest) or Config.LoanInterest

    if not amount or amount <= 0 then
        TriggerClientEvent('esx:showNotification', src, 'Cantidad inválida')
        return
    end

    if not HasBankingPermission(src, 'loan', amount) then
        TriggerClientEvent('esx:showNotification', src, 'No tienes permisos para dar préstamos de esa cantidad')
        return
    end

    if not CheckTransactionLimit(src) then
        TriggerClientEvent('esx:showNotification', src, 'Has excedido el límite de transacciones')
        return
    end

    local targetPlayer = ESX.GetPlayerFromId(targetId)
    if not targetPlayer then
        TriggerClientEvent('esx:showNotification', src, 'Jugador no encontrado')
        return
    end

    local totalAmount = amount + (amount * interest)
    local dueDate = os.time() + (duration * 24 * 60 * 60)

    GetSocietyAccount(function(account)
        if not account then
            TriggerClientEvent('esx:showNotification', src, 'Error con la cuenta de la sociedad')
            return
        end

        if account.money < amount then
            TriggerClientEvent('esx:showNotification', src, 'La sociedad no tiene suficiente dinero para dar el préstamo')
            return
        end

        MySQL.insert('INSERT INTO banking_loans (borrower, borrower_id, amount, total_amount, interest, duration, due_date, given_by, given_by_id, status) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', {
            targetPlayer.getName(),
            targetId,
            amount,
            totalAmount,
            interest,
            duration,
            dueDate,
            ESX.GetPlayerFromId(src) and ESX.GetPlayerFromId(src).getName() or 'Unknown',
            src,
            'active'
        }, function(loanId)
            if loanId then
                account.removeMoney(amount)
                targetPlayer.addAccountMoney('bank', amount)
                LogTransaction(src, targetId, 'loan', amount, string.format('Préstamo de $%s con %s%% de interés, vence en %s días', amount, interest * 100, duration))

                TriggerClientEvent('esx:showNotification', src, string.format('Préstamo de $%s otorgado a %s', amount, targetPlayer.getName()))
                TriggerClientEvent('esx:showNotification', targetId, string.format('Has recibido un préstamo de $%s. Debes pagar $%s en %s días', amount, totalAmount, duration))

                TriggerEvent('esx_banking:getAccounts', src)
            else
                TriggerClientEvent('esx:showNotification', src, 'Error al crear el préstamo en la base de datos')
            end
        end)
    end)
end)

-- Obtener préstamos activos
RegisterNetEvent('esx_banking:getLoans', function()
    local src = source

    if not HasBankingPermission(src, 'view', 0) then
        TriggerClientEvent('esx:showNotification', src, 'No tienes permisos para ver préstamos')
        return
    end

    MySQL.query('SELECT * FROM banking_loans WHERE status = ?', {'active'}, function(loans)
        TriggerClientEvent('esx_banking:receiveLoans', src, loans or {})
    end)
end)

-- PAGAR PRÉSTAMO: quitar del bank del jugador → añadir a sociedad y marcar como pagado
RegisterNetEvent('esx_banking:payLoan', function(loanId)
    local src = source

    if not HasBankingPermission(src, 'loan', 0) then
        TriggerClientEvent('esx:showNotification', src, 'No tienes permisos para gestionar préstamos')
        return
    end

    MySQL.query('SELECT * FROM banking_loans WHERE id = ?', {loanId}, function(result)
        if result and #result > 0 then
            local loan = result[1]
            local borrowerId = tonumber(loan.borrower_id)
            local player = ESX.GetPlayerFromId(borrowerId)

            if not player then
                TriggerClientEvent('esx:showNotification', src, 'El prestatario no está conectado')
                return
            end

            local remaining = tonumber(loan.total_amount) or tonumber(loan.remaining) or 0

            if player.getAccount('bank').money < remaining then
                TriggerClientEvent('esx:showNotification', src, 'El jugador no tiene suficiente dinero en su banco para pagar el préstamo')
                return
            end

            player.removeAccountMoney('bank', remaining)

            GetSocietyAccount(function(account)
                if account then
                    account.addMoney(remaining)
                end
            end)

            MySQL.update('UPDATE banking_loans SET status = ?, paid_date = ? WHERE id = ?', {
                'paid',
                os.time(),
                loanId
            })

            LogTransaction(src, borrowerId, 'loan_paid', remaining, string.format('Préstamo pagado: $%s', remaining))

            TriggerClientEvent('esx:showNotification', src, 'Préstamo marcado como pagado')
            TriggerClientEvent('esx:showNotification', borrowerId, 'Tu préstamo ha sido pagado y procesado')

            TriggerEvent('esx_banking:getLoans', src)
            TriggerEvent('esx_banking:getAccounts', src)
        else
            TriggerClientEvent('esx:showNotification', src, 'Préstamo no encontrado')
        end
    end)
end)

-- Comando para abrir UI de banking (manteniendo tu lógica original)
RegisterCommand(Config.Commands.OpenBanking, function(source, args, rawCommand)
    if not HasBankingPermission(source, 'view', 0) then
        TriggerClientEvent('esx:showNotification', source, 'No tienes permisos para acceder al sistema bancario')
        return
    end

    TriggerClientEvent('esx_banking:openUI', source)
end, false)

-- Comando admin para verificar cuenta (mantener compatibilidad)
RegisterCommand(Config.Commands.AdminCheck, function(source, args, rawCommand)
    if source ~= 0 and not HasBankingPermission(source, 'view', 0) then
        TriggerClientEvent('esx:showNotification', source, 'No tienes permisos')
        return
    end

    local targetId = tonumber(args[1])
    if not targetId then
        if source ~= 0 then
            TriggerClientEvent('esx:showNotification', source, 'Uso: /checkbank [id]')
        end
        return
    end

    local targetPlayer = ESX.GetPlayerFromId(targetId)
    if not targetPlayer then
        if source ~= 0 then
            TriggerClientEvent('esx:showNotification', source, 'Jugador no encontrado')
        end
        return
    end

    local bankMoney = targetPlayer.getAccount('bank').money
    local cashMoney = targetPlayer.getMoney()

    local message = string.format('Jugador: %s | Efectivo: $%s | Banco: $%s',
        targetPlayer.getName(), cashMoney, bankMoney)

    if source == 0 then
        print(message)
    else
        TriggerClientEvent('esx:showNotification', source, message)
    end
end, false)

-- Callback para verificar permisos desde cliente
ESX.RegisterServerCallback('esx_banking:checkPermission', function(source, cb)
    cb(HasBankingPermission(source, 'view', 0))
end)

print('[esx_banking] server.lua cargado correctamente.')
