local RSGCore = exports['rsg-core']:GetCoreObject()

RegisterNetEvent('blackmarket:server:buyItem', function(item, amount, price)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local totalPrice = price * amount
    
    -- Check if player has enough blood money
    if Player.PlayerData.money['bloodmoney'] >= totalPrice then
        Player.Functions.AddItem(item, amount)
        Player.Functions.RemoveMoney('bloodmoney', totalPrice)
        
        TriggerClientEvent('RSGCore:Notify', src, 'Purchase successful!', 'success')
    else
        TriggerClientEvent('RSGCore:Notify', src, 'Not enough blood money!', 'error')
    end
end)

RegisterNetEvent('blackmarket:server:sellItem', function(item, amount, price)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local playerItem = Player.Functions.GetItemByName(item)
    
    if playerItem and playerItem.amount >= amount then
        local totalPrice = price * amount
        
        Player.Functions.RemoveItem(item, amount)
        Player.Functions.AddMoney('cash', totalPrice)
        
        TriggerClientEvent('RSGCore:Notify', src, 'Sale successful!', 'success')
    else
        TriggerClientEvent('RSGCore:Notify', src, 'Not enough items to sell!', 'error')
    end
end)