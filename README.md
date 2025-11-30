# chooky_banking
# ESX Banking - Sistema de Banca Corporativa by Ch00kyScripts

## Descripción

Sistema de banca avanzado para ESX Legacy que permite a jugadores con el job adecuado gestionar cuentas bancarias, realizar transacciones y otorgar préstamos a otros jugadores.


<img width="1024" height="1536" alt="12f96022-a778-4ea4-b377-99113f0cbfa6" src="https://github.com/user-attachments/assets/d03227d3-c729-4d59-8613-acdcd880ea07" />

## Características

- ✅ **Gestión de Cuentas**: Ver saldos de todos los jugadores
- ✅ **Transacciones**: Retirar y depositar dinero de cuentas bancarias
- ✅ **Sistema de Préstamos**: Otorgar préstamos con intereses y plazos
- ✅ **Logs de Transacciones**: Registro completo de todas las operaciones
- ✅ **Seguridad**: Sistema de permisos por grados y límites de transacciones
- ✅ **Interfaz Moderna**: UI intuitiva y responsive con temas claro/oscuro
- ✅ **Punto de Interacción**: Menú accesible en coordenadas específicas

## Requisitos

- **ESX Legacy** (1.8.5 o superior)
- **ox_lib** (para la interfaz)
- **oxmysql** (para la base de datos)

## Instalación

### 1. Descarga y Colocación

1. Descarga el script y colócalo en tu carpeta `resources`:
   ```
   resources/[esx]/esx_banking/
   ```

### 2. Configuración de la Base de Datos

El script creará automáticamente las tablas necesarias al iniciar:
- `banking_logs` - Registro de transacciones
- `banking_loans` - Gestión de préstamos

### 3. Configuración del Servidor

Asegúrate de que los siguientes recursos estén iniciados antes que `esx_banking`:
```
ensure es_extended
ensure ox_lib
ensure oxmysql
```

### 4. Iniciar el Script

Agrega a tu `server.cfg`:
```
ensure esx_banking
```

## Configuración

Edita el archivo `config.lua` para personalizar el sistema:

```


## Uso

### Acceder al Sistema

1. **Ubicación física**: Ve a las coordenadas configuradas 
2. **Comando**: Usa `/banking` para abrir el menú
3. **Interacción**: Presiona `E` cerca del punto de interacción

### Funcionalidades

#### Gestión de Cuentas
- Ver todos los jugadores y sus saldos bancarios
- Buscar jugadores específicos
- Acceso a cuentas de jugadores online y offline

#### Transacciones
- **Retirar**: Sacar dinero de la cuenta bancaria de un jugador
- **Depositar**: Agregar dinero a la cuenta bancaria
- **Razón**: Todas las transacciones requieren una razón (se registra en logs)
- **Confirmación**: Transacciones grandes requieren confirmación adicional

#### Sistema de Préstamos
- **Otorgar Préstamos**: Dar dinero con interés y plazo definido
- **Monitorear**: Ver todos los préstamos activos
- **Marcar como Pagado**: Los préstamos pueden ser marcados como pagados
- **Intereses**: Cálculo automático de intereses

#### Logs del Sistema
- Todas las transacciones se registran automáticamente
- Información detallada: quién, cuándo, cuánto y por qué
- Compatible con Discord webhooks (configurable)

### Comandos

- `/banking` - Abre el menú de banca (solo para job "bankero")
- `/checkbank [id]` - Verificar cuenta de un jugador (comando admin)

## Seguridad

### Sistema de Permisos
- Permisos basados en grados del job "bankero"
- Límites máximos por grado
- Verificación de job antes de permitir acceso

### Prevención de Abuso
- Límite de transacciones por minuto (configurable)
- Confirmación requerida para transacciones grandes
- Registro completo de todas las operaciones

### Logs de Auditoría
- Todas las acciones se registran en la base de datos
- Información completa para auditorías
- Compatible con sistemas de logging externos

## Temas de Interfaz

El sistema incluye dos temas de interfaz:

### Tema Oscuro (por defecto)
- Colores oscuros y modernos
- Ideal para uso nocturno
- Contraste alto para mejor legibilidad

### Tema Claro
- Colores claros y limpios
- Ideal para uso diurno
- Menos fatiga visual en entornos brillantes

Para cambiar el tema, modifica en `config.lua`:
```lua
Config.UI = {
    Theme = 'light', -- 'dark' o 'light'
    -- ... otras configuraciones
}
```



## Créditos

Desarrollado por Ch00ky para ESX Legacy con las siguientes tecnologías:
- ESX Framework
- ox_lib (interfaz)
- Inter font family
- Font Awesome icons

## Licencia

Este script es gratuito para uso en servidores de FiveM.
Se permite la modificación y distribución con créditos al autor original.

---

**¡Disfruta del sistema de banca corporativa!** 💰🏦
