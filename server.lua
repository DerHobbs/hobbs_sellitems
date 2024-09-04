local qbx = exports.qbx_core -- Import qbx_core functions

RegisterServerEvent('npc:sellItem', function(itemName, amount, pricePerItem)
    local src = source
    local Player = qbx:GetPlayer(src)
    local totalSellPrice = pricePerItem * amount

    -- Get the item count from the player's inventory
    local itemCount = exports.ox_inventory:GetItem(src, itemName, nil, true)

    -- Check if the player has enough of the item
    if not itemCount or itemCount < amount then
        -- Notify the player if they don't have enough items
        TriggerClientEvent('ox_lib:notify', src, {
            title = Config.Texts.SellErrorTitle,
            description = Config.Texts.NotEnoughItems,
            type = 'error'
        })
        return -- Abort the operation if the player doesn't have enough items
    end

    -- Remove the item and add money to the player
    if exports.ox_inventory:RemoveItem(src, itemName, amount) then
        Player.Functions.AddMoney('cash', totalSellPrice)

        -- Notify the player of a successful sale
        TriggerClientEvent('ox_lib:notify', src, {
            title = Config.Texts.SellSuccessTitle,
            description = Config.Texts.SellSuccessMessage:format(amount, itemName, totalSellPrice),
            type = 'success'
        })
    else
        -- Notify the player if there was an error removing the item
        TriggerClientEvent('ox_lib:notify', src, {
            title = Config.Texts.SellErrorTitle,
            description = Config.Texts.SellErrorMessage,
            type = 'error'
        })
    end
end)