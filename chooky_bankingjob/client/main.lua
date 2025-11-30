local ESX = exports['es_extended']:getSharedObject()
local isUIOpen = false
local currentAccounts = {}
local currentLoans = {}

-- Asegurar que la UI esté oculta al iniciar
Citizen.CreateThread(function()
    Citizen.Wait(1000) -- Esperar a que todo se cargue
    SendNUIMessage({
        action = 'hideUI'
    })
end)

-- Funciones auxiliares
function ShowNotification(message, type)
    if Config.NotificationType == 'ox_lib' then
        lib.notify({
            title = 'Sistema Bancario',
            description = message,
            type = type or 'info',
            duration = 5000
        })
    else
        ESX.ShowNotification(message)
    end
end

function FormatMoney(amount)
    return Config.UI.Currency .. string.format('%d', amount)
end

-- Crear punto de interacción en las coordenadas
Citizen.CreateThread(function()
    local coords = Config.BankingCoords
    
    -- Crear blip si es necesario
    if Config.ShowBlip then
        local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
        SetBlipSprite(blip, 106)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, 0.8)
        SetBlipColour(blip, 2)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString('Banca Corporativa')
        EndTextCommandSetBlipName(blip)
    end
    
    -- Crear marker
    while true do
        Citizen.Wait(0)
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local distance = #(playerCoords - coords)
        
        if distance < 10.0 then
           -- DrawMarker(1, coords.x, coords.y, coords.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.5, 1.5, 1.0, 0, 255, 0, 100, false, true, 2, false, nil, nil, false)
            
            if distance < 1.5 then
                ESX.ShowHelpNotification('[E] Ordenador')
                
                if IsControlJustReleased(0, 38) then -- E key
                    TriggerEvent('esx_banking:openUI')
                end
            end
        else
            Citizen.Wait(500)
        end
    end
end)

-- Abrir interfaz
RegisterNetEvent('esx_banking:openUI', function()
    if isUIOpen then return end
    
    ESX.TriggerServerCallback('esx_banking:checkPermission', function(hasPermission)
        if hasPermission then
            isUIOpen = true
            SetNuiFocus(true, true)
            SendNUIMessage({
                action = 'showUI',
                theme = Config.UI.Theme
            })
            
            -- Cargar datos
            TriggerServerEvent('esx_banking:getAccounts')
            TriggerServerEvent('esx_banking:getLoans')
        else
            ShowNotification('No tienes permisos para acceder al sistema bancario', 'error')
        end
    end)
end)

-- Recibir cuentas del servidor
RegisterNetEvent('esx_banking:receiveAccounts', function(accounts)
    currentAccounts = accounts
    SendNUIMessage({
        action = 'updateAccounts',
        accounts = accounts
    })
end)

-- Recibir préstamos del servidor
RegisterNetEvent('esx_banking:receiveLoans', function(loans)
    currentLoans = loans
    SendNUIMessage({
        action = 'updateLoans',
        loans = loans
    })
end)

-- Callbacks NUI
RegisterNUICallback('closeUI', function(data, cb)
    isUIOpen = false
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('withdrawMoney', function(data, cb)
    local targetId = tonumber(data.targetId)
    local amount = tonumber(data.amount)
    local reason = data.reason
    
    if not targetId or not amount or amount <= 0 then
        ShowNotification('Datos inválidos', 'error')
        cb('error')
        return
    end
    
    if Config.RequireConfirmation and amount > 10000 then
        SendNUIMessage({
            action = 'showConfirmation',
            type = 'withdraw',
            data = data
        })
        cb('confirm')
        return
    end
    
    TriggerServerEvent('esx_banking:withdrawMoney', targetId, amount, reason)
    cb('ok')
end)

RegisterNUICallback('depositMoney', function(data, cb)
    local targetId = tonumber(data.targetId)
    local amount = tonumber(data.amount)
    local reason = data.reason
    
    if not targetId or not amount or amount <= 0 then
        ShowNotification('Datos inválidos', 'error')
        cb('error')
        return
    end
    
    if Config.RequireConfirmation and amount > 10000 then
        SendNUIMessage({
            action = 'showConfirmation',
            type = 'deposit',
            data = data
        })
        cb('confirm')
        return
    end
    
    TriggerServerEvent('esx_banking:depositMoney', targetId, amount, reason)
    cb('ok')
end)

RegisterNUICallback('giveLoan', function(data, cb)
    local targetId = tonumber(data.targetId)
    local amount = tonumber(data.amount)
    local duration = tonumber(data.duration) or Config.LoanDuration
    local interest = tonumber(data.interest) or Config.LoanInterest
    
    if not targetId or not amount or amount <= 0 then
        ShowNotification('Datos inválidos', 'error')
        cb('error')
        return
    end
    
    TriggerServerEvent('esx_banking:giveLoan', targetId, amount, duration, interest)
    cb('ok')
end)

RegisterNUICallback('payLoan', function(data, cb)
    local loanId = tonumber(data.loanId)
    
    if not loanId then
        ShowNotification('ID de préstamo inválido', 'error')
        cb('error')
        return
    end
    
    TriggerServerEvent('esx_banking:payLoan', loanId)
    cb('ok')
end)

RegisterNUICallback('refreshData', function(data, cb)
    TriggerServerEvent('esx_banking:getAccounts')
    TriggerServerEvent('esx_banking:getLoans')
    cb('ok')
end)

RegisterNUICallback('searchPlayer', function(data, cb)
    local searchTerm = data.searchTerm:lower()
    local filteredAccounts = {}
    
    for _, account in ipairs(currentAccounts) do
        if account.name and account.name:lower():find(searchTerm) then
            table.insert(filteredAccounts, account)
        end
    end
    
    SendNUIMessage({
        action = 'updateSearchResults',
        accounts = filteredAccounts
    })
    
    cb('ok')
end)

-- Comandos
RegisterCommand(Config.Commands.OpenBanking, function()
    TriggerEvent('esx_banking:openUI')
end, false)

-- Key mapping
if Config.KeyMapping then
    RegisterKeyMapping(Config.Commands.OpenBanking, 'Abrir sistema bancario', 'keyboard', Config.DefaultKey)
end

-- Eventos de notificación
RegisterNetEvent('esx_banking:notification', function(message, type)
    ShowNotification(message, type)
end)

-- Limpiar cache cuando el jugador se desconecta
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        if isUIOpen then
            SetNuiFocus(false, false)
        end
    end
end)