local anchoredBoats = {}

-- Notificatie functie
local function sendNotify(type, message, time)
    time = time or Config.NotifyTime
    if Config.NotificationType == 'ox' then
        exports.ox_lib:notify({
            title = type == 'error' and 'Fout' or 'Melding',
            description = message,
            type = type,
            duration = time
        })
    elseif Config.NotificationType == 'wsk' then
        exports['wsk-notifications']:notify(type, message, time)
    else
        print('[AnchorBoat] Notificatie:', message)
    end
end

-- Speel mechanic animatie af
local function playMechanicAnim()
    local ped = PlayerPedId()
    local dict = "mini@repair"
    local anim = "fixing_a_ped"
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(10) end
    TaskPlayAnim(ped, dict, anim, 8.0, -8, 3000, 49, 0, false, false, false)
end

-- Simpele geluiden
local function playAnchorSound(state)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local sound = state and "CLICK_BACK" or "SELECT"
    PlaySoundFromCoord(-1, sound, coords.x, coords.y, coords.z, "HUD_FRONTEND_DEFAULT_SOUNDSET", false, 0, true)
end

-- Zet anchor status
local function setAnchorState(entity, state)
    if DoesEntityExist(entity) then
        SetBoatAnchor(entity, state)
    end
end

-- Toggle anchor functie
local function toggleAnchor(entity)
    if not DoesEntityExist(entity) then
        sendNotify('error', 'Boot bestaat niet.')
        return
    end
    local model = GetEntityModel(entity)
    if not IsThisModelABoat(model) then
        sendNotify('error', 'Dit is geen boot.')
        return
    end

    if Config.Debug then print('[AnchorBoat] toggleAnchor gestart') end

    playMechanicAnim()

    local netId = NetworkGetNetworkIdFromEntity(entity)
    if netId == 0 then Wait(50) netId = NetworkGetNetworkIdFromEntity(entity) end

    local coords = GetEntityCoords(entity)
    TriggerServerEvent('anchorboat:toggleAnchor', netId, coords)
end

-- Alleen spelers in de buurt krijgen notificatie
RegisterNetEvent('anchorboat:updateAnchorState', function(netId, state)
    local entity = NetworkGetEntityFromNetworkId(netId)
    anchoredBoats[netId] = state
    setAnchorState(entity, state)

    playAnchorSound(state)
    sendNotify('success', state and "Anker neergelaten." or "Anker opgehaald.")
end)

-- Synchronisatie zonder notificatie
RegisterNetEvent('anchorboat:syncAnchorState', function(netId, state)
    local entity = NetworkGetEntityFromNetworkId(netId)
    anchoredBoats[netId] = state
    setAnchorState(entity, state)
end)

-- Reset alle ankers
RegisterNetEvent('anchorboat:resetAnchors', function()
    anchoredBoats = {}
    if Config.Debug then print('[AnchorBoat] Alle ankers gereset.') end
end)

-- Blokkeer gas bij anker
CreateThread(function()
    local lastNotify = 0
    while true do
        Wait(0)
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)
        if veh ~= 0 and IsThisModelABoat(GetEntityModel(veh)) then
            local netId = NetworkGetNetworkIdFromEntity(veh)
            if anchoredBoats[netId] then
                if IsControlPressed(0, 71) then -- Forward/gas
                    DisableControlAction(0, 71, true)
                    if GetGameTimer() - lastNotify > 5000 then
                        sendNotify('error', 'Anker staat uit. Je kunt geen gas geven.')
                        lastNotify = GetGameTimer()
                    end
                end
                SetEntityVelocity(veh, 0.0, 0.0, 0.0)
                SetVehicleForwardSpeed(veh, 0.0)
            end
        end
    end
end)

-- ox_target interactie
CreateThread(function()
    exports.ox_target:addGlobalVehicle({
        {
            name = 'anchor_toggle',
            icon = 'anchor',
            label = Config.Labels.anchorToggle or "Anker bedienen",
            canInteract = function(entity, distance)
                local isBoat = IsThisModelABoat(GetEntityModel(entity))
                local toestaan = isBoat and distance < 3.0
                if Config.Debug then
                    print(('[AnchorBoat][DEBUG] canInteract | isBoat: %s afstand: %s toestaan: %s'):
                        format(isBoat and 1 or 0, distance, toestaan and "true" or "false"))
                end
                return toestaan
            end,
            onSelect = function(data)
                if Config.Debug then print("[AnchorBoat][DEBUG] onSelect | Entity:", data.entity) end
                toggleAnchor(data.entity)
            end
        }
    })
end)
