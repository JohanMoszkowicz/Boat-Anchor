local anchors = {}

RegisterNetEvent('anchorboat:toggleAnchor', function(netId, coords)
    anchors[netId] = not anchors[netId]

    -- Sync naar alle clients zonder notificatie
    TriggerClientEvent('anchorboat:syncAnchorState', -1, netId, anchors[netId])

    -- Alleen notificatie naar spelers binnen 5 meter van de boot
    for _, playerId in ipairs(GetPlayers()) do
        local ped = GetPlayerPed(playerId)
        if ped then
            local pedCoords = GetEntityCoords(ped)
            if #(pedCoords - vector3(coords.x, coords.y, coords.z)) <= 5.0 then
                TriggerClientEvent('anchorboat:updateAnchorState', playerId, netId, anchors[netId])
            end
        end
    end
end)
