local RSGCore = exports['rsg-core']:GetCoreObject()

-- Function to get current player money
local function GetPlayerMoney()
    local PlayerData = RSGCore.Functions.GetPlayerData()
    return {
        bloodmoney = PlayerData.money['bloodmoney'] or 0,
        cash = PlayerData.money['cash'] or 0
    }
end

-- Table to track all spawned peds for cleanup
local spawnedPeds = {}

Citizen.CreateThread(function()
    RegisterNUICallback('getItems', function(data, cb)
        cb(Config.Locations[data.blackmarket].sellItems)
    end)
    
    RegisterNUICallback('getSellableItems', function(data, cb)
        local items = RSGCore.Functions.GetPlayerData().items
        local tableData = {}
        for _, v in pairs(Config.Locations[data.blackmarket].buyItems) do
            for _, item in pairs(items) do
                if item.name == v.name and item.amount > 0 then
                    tableData[#tableData + 1] = {
                        label = v.label,
                        image = v.image,
                        name = v.name,
                        amount = item.amount,
                        price = v.price,
                    }
                end
            end
        end
        Wait(100)
        cb(tableData)
    end)
    
    RegisterNUICallback('getInventory', function(data, cb)
        cb(Config.Inventory)
    end)
    
    RegisterNUICallback('getPlayerMoney', function(data, cb)
        cb(GetPlayerMoney())
    end)
    
    RegisterNUICallback('close', function(data, cb)
        SetNuiFocus(false, false)
        cb('ok')
    end)
    
    RegisterNUICallback('buyItem', function(data, cb)
        local PlayerData = RSGCore.Functions.GetPlayerData()
        local totalPrice = data.price * data.amount
        
        if PlayerData.money['bloodmoney'] >= totalPrice then
            TriggerServerEvent('blackmarket:server:buyItem', data.item, data.amount, data.price)
            
            -- Update local config amounts if globalAmount is enabled
            for _, v in pairs(Config.Locations[data.blackmarket].sellItems) do
                if v.name == data.item then
                    if Config.Locations[data.blackmarket].globalAmount then
                        if v.amount then
                            v.amount = math.max(0, v.amount - data.amount)
                            break
                        end
                    end
                end
            end
            
            -- Send updated money to NUI
            Wait(100)
            SendNUIMessage({
                type = 'updateMoney',
                money = GetPlayerMoney()
            })
            
            RSGCore.Functions.Notify('Purchase successful!', 'success')
        else
            RSGCore.Functions.Notify('You don\'t have enough blood money!', 'error')
        end
        cb('ok')
    end)
    
    RegisterNUICallback('sellItem', function(data, cb)
        if RSGCore.Functions.HasItem(data.item, tonumber(data.amount)) then
            TriggerServerEvent('blackmarket:server:sellItem', data.item, data.amount, data.price)
            
            -- Update local config amounts if globalAmount is enabled
            for _, v in pairs(Config.Locations[data.blackmarket].buyItems) do
                if v.name == data.item then
                    if Config.Locations[data.blackmarket].globalAmount then
                        if v.amount then
                            v.amount = math.max(0, v.amount - data.amount)
                            break
                        end
                    end
                end
            end
            
            -- Send updated money to NUI
            Wait(100)
            SendNUIMessage({
                type = 'updateMoney',
                money = GetPlayerMoney()
            })
            
            RSGCore.Functions.Notify('Sale successful!', 'success')
        else
            RSGCore.Functions.Notify('You don\'t have enough items to sell!', 'error')
        end
        cb('ok')
    end)
end)

Citizen.CreateThread(function()
    for k, v in pairs(Config.Locations) do
        local model = v.ped
        local coords = v.coords
        RequestModel(model)
        while not HasModelLoaded(model) do
            Wait(0)
        end

        local blackmarket = CreatePed(model, coords.x, coords.y, coords.z - 1.0, coords.w, false, false)
        Citizen.InvokeNative(0x283978A15512B2FE, blackmarket, true)
        SetEntityInvincible(blackmarket, true)
        SetBlockingOfNonTemporaryEvents(blackmarket, true)
        FreezeEntityPosition(blackmarket, true)
        table.insert(spawnedPeds, blackmarket)

        -- Spawn pets/companions if defined
        if v.pets then
            for _, pet in ipairs(v.pets) do
                RequestModel(pet.model)
                while not HasModelLoaded(pet.model) do
                    Wait(0)
                end
                local petCoords = vec3(coords.x, coords.y, coords.z) + (pet.offset or vec3(1.0, 0.0, 0.0))
                local companion = CreatePed(pet.model, petCoords.x, petCoords.y, petCoords.z - 1.0, coords.w, false, false)
                Citizen.InvokeNative(0x283978A15512B2FE, companion, true)
                SetEntityInvincible(companion, true)
                SetBlockingOfNonTemporaryEvents(companion, true)
                FreezeEntityPosition(companion, false) -- Allow movement
                table.insert(spawnedPeds, companion)

                -- Randomize behavior: sit, idle, or wander
                local behavior = math.random(1, 3)
                
                if behavior == 2 then
                    -- Sit
                    TaskStartScenarioInPlace(companion, "WORLD_ANIMAL_DOG_SITTING", 0, true)
                elseif behavior == 2 then
                    -- Idle
                    TaskStartScenarioInPlace(companion, "WORLD_ANIMAL_DOG_IDLE", 0, true)
                else
                    -- Wander in a 5m radius around the market NPC
                    TaskWanderInArea(companion, coords.x, coords.y, coords.z, 5.0, 0.0, 0.0)
                end
            end
        end

        exports['ox_target']:addSphereZone({
            name = v.label,
            coords = coords,
            radius = 1.5,
            debug = false,
            options = {
                {
                    label = 'Talk to stranger',
                    icon = 'fas fa-comment',
                    onSelect = function()
                        local buys = false
                        local sells = false

                        if #v.buyItems > 0 then buys = true end
                        if #v.sellItems > 0 then sells = true end
                        
                        SetNuiFocus(true, true)
                        SendNUIMessage({
                            type = 'blackmarket',
                            id = k,
                            buys = buys,
                            sells = sells,
                            label = v.label,
                            playerMoney = GetPlayerMoney()
                        })
                    end
                }
            }
        })
    end
end)

-- Cleanup all spawned peds on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    for _, ped in ipairs(spawnedPeds) do
        if DoesEntityExist(ped) then
            DeleteEntity(ped)
        end
    end
end)