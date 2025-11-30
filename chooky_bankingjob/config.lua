Config = {}

-- Configuración general
Config.Locale = 'es'
Config.Debug = false

-- Coordenadas del menú banking
Config.BankingCoords = vector3(251.59, 222.91, 107.31)

-- Configuración del job
Config.BankerJob = 'bankero' --Trabajo de Banco
Config.MinGrade = 0 -- Grado mínimo para acceder

-- Configuración de límites
Config.MaxWithdraw = 1000000 -- Máximo para retirar
Config.MaxDeposit = 1000000 -- Máximo para ingresar
Config.MaxLoan = 500000 -- Máximo para préstamos

-- Configuración de préstamos
Config.LoanInterest = 0.05 -- 5% de interés
Config.LoanDuration = 30 -- Días para pagar
Config.LoanPenalty = 0.1 -- 10% de penalización por retraso

-- Configuración de logs
Config.EnableLogs = true
Config.Webhook = "WEBHOOKLINK"
Config.LogChannel = 'Banco Central' -- Canal de Discord para logs

-- Configuración de seguridad
Config.MaxTransactionsPerMinute = 10 -- Límite de transacciones por minuto
Config.RequireConfirmation = true -- Requerir confirmación para transacciones grandes

-- Configuración de notificaciones
Config.NotificationType = 'ox_lib' -- 'esx' o 'ox_lib'

-- Configuración de la interfaz
Config.UI = {
    Theme = 'dark', -- 'dark' o 'light'
    Currency = '$',
    Animations = true,
    SoundEffects = true
}

-- Configuración de comandos
Config.Commands = {
    OpenBanking = 'banking',
    AdminCheck = 'checkbank'
}

-- Configuración de permisos por grado
Config.Grades = {
    [0] = { -- Empleado
        canView = true,
        canWithdraw = false,
        canDeposit = false,
        canGiveLoans = false,
        maxAmount = 0
    },
    [1] = { -- Cajero
        canView = true,
        canWithdraw = true,
        canDeposit = true,
        canGiveLoans = false,
        maxAmount = 10000
    },
    [2] = { -- Gerente
        canView = true,
        canWithdraw = true,
        canDeposit = true,
        canGiveLoans = true,
        maxAmount = 100000
    },
    [3] = { -- Director
        canView = true,
        canWithdraw = true,
        canDeposit = true,
        canGiveLoans = true,
        maxAmount = 1000000
    }
}