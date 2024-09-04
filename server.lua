local qbx = exports.qbx_core
local npcData = {}
local discordWebhookUrl = "HERE_YOUR_WEBHOOK"

-- Send a message to the Discord webhook
local function sendToDiscord(playerName, source, itemList, npcName, totalSellPrice)
    local ids = ExtractIdentifiers(source)
    local discordID = ids.discord and "<@" .. ids.discord:gsub("discord:", "") .. ">" or "N/A"
    local steamID = ids.steam or "N/A"
    local license = ids.license or "N/A"
    local ip = ids.ip and ids.ip:gsub("ip:", "") or "N/A"

    -- Format item details (both technical name and label)
    local itemDetails = ""
    for _, item in ipairs(itemList) do
        itemDetails = itemDetails .. string.format("**%d x %s** (`%s`) for **$%d**\n", item.amount, item.label, item.name, item.price)
    end

    local message = {
        embeds = {
            {
                ["title"] = "Items Sold",
                ["description"] = string.format("**%s** (ID: %d) sold items to **%s**:\n\n%s\n**Total:** **$%d**", playerName, source, npcName, itemDetails, totalSellPrice),
                ["color"] = 16711680,  -- Red
                ["fields"] = {
                    {["name"] = "Steam ID", ["value"] = steamID, ["inline"] = true},
                    {["name"] = "License", ["value"] = license, ["inline"] = true},
                    {["name"] = "Discord", ["value"] = discordID, ["inline"] = true},
                    {["name"] = "IP", ["value"] = ip, ["inline"] = true}
                },
                ["footer"] = {
                    ["text"] = "Made by @DerHobbs",
                    ["icon_url"] = "https://i.postimg.cc/VkQsgpX0/101003021-enhanced.png"
                },
                ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
            }
        }
    }

    PerformHttpRequest(discordWebhookUrl, function(err, text, headers)
        print("Webhook Response: ", err, text)
    end, 'POST', json.encode(message), { ['Content-Type'] = 'application/json' })
end

-- Initialize NPC data with prices and set up periodic price resets
local function InitializeNPCData()
    for npcName, npcConfig in pairs(Config.NPCs) do
        npcData[npcName] = { prices = {} }
        SetItemPrices(npcName, npcConfig)
        if npcConfig.priceResetInterval and npcConfig.priceResetInterval > 0 then
            ResetPricesPeriodically(npcName, npcConfig)
        end
    end
end

-- Set item prices for an NPC
function SetItemPrices(npcName, npcConfig)
    for _, itemConfig in pairs(npcConfig.sellItems) do
        npcData[npcName].prices[itemConfig.item] = math.random(itemConfig.minPrice, itemConfig.maxPrice)
    end
end

-- Reset prices periodically based on the configured interval
function ResetPricesPeriodically(npcName, npcConfig)
    Citizen.CreateThread(function()
        while true do
            Wait(npcConfig.priceResetInterval * 1000)
            SetItemPrices(npcName, npcConfig)
        end
    end)
end

-- Get the price of an item for a specific NPC
local function GetItemPrice(npcName, itemName)
    return npcData[npcName].prices[itemName]
end

-- Handle the request from the client to open the sell menu
RegisterServerEvent('npc:requestSellMenu')
AddEventHandler('npc:requestSellMenu', function(npcName)
    local src = source
    local npcConfig = Config.NPCs[npcName]
    
    if not npcConfig then
        print("Error: NPC config not found for", npcName)
        return
    end

    -- Gather the sell items for this NPC
    local sellItems = {}
    for _, itemConfig in pairs(npcConfig.sellItems) do
        table.insert(sellItems, {
            name = itemConfig.item,
            label = itemConfig.label,
            price = GetItemPrice(npcName, itemConfig.item)
        })
    end

    -- Send the data back to the client
    TriggerClientEvent('npc:openSellMenu', src, npcName, sellItems)
end)

-- Event to handle the item selling process
RegisterServerEvent('npc:sellItem')
AddEventHandler('npc:sellItem', function(itemName, amount, npcName)
    local src = source
    local Player = qbx:GetPlayer(src)
    local playerName = GetPlayerName(src)

    -- Find the NPC configuration
    local npcConfig = Config.NPCs[npcName]
    if not npcConfig then
        TriggerClientEvent('ox_lib:notify', src, {
            title = Config.Texts.SellErrorTitle,
            description = "Invalid NPC.",
            type = 'error'
        })
        return
    end

    -- Find the itemConfig to retrieve the label
    local itemConfig = nil
    for _, configItem in pairs(npcConfig.sellItems) do
        if configItem.item == itemName then
            itemConfig = configItem
            break
        end
    end

    -- Check if itemConfig is valid
    if not itemConfig then
        TriggerClientEvent('ox_lib:notify', src, {
            title = Config.Texts.SellErrorTitle,
            description = "Item not found in NPC configuration.",
            type = 'error'
        })
        return
    end

    -- Get the valid price for the item
    local pricePerItem = GetItemPrice(npcName, itemName)
    if not pricePerItem then
        TriggerClientEvent('ox_lib:notify', src, {
            title = Config.Texts.SellErrorTitle,
            description = "Item not allowed for sale.",
            type = 'error'
        })
        return
    end

    -- Check if the player has enough of the item
    local itemCount = exports.ox_inventory:GetItem(src, itemName, nil, true)
    if not itemCount or itemCount < amount then
        TriggerClientEvent('ox_lib:notify', src, {
            title = Config.Texts.SellErrorTitle,
            description = Config.Texts.NotEnoughItems,
            type = 'error'
        })
        return
    end

    -- Calculate total sell price
    local totalSellPrice = pricePerItem * amount

    -- Remove the item and give the player money
    if exports.ox_inventory:RemoveItem(src, itemName, amount) then
        Player.Functions.AddMoney('cash', totalSellPrice)

        TriggerClientEvent('ox_lib:notify', src, {
            title = Config.Texts.SellSuccessTitle,
            description = Config.Texts.SellSuccessMessage:format(amount, itemConfig.label, totalSellPrice),  -- Use itemConfig.label
            type = 'success'
        })

        -- Send details to Discord
        local itemList = {
            {name = itemName, label = itemConfig.label, amount = amount, price = totalSellPrice}
        }
        sendToDiscord(playerName, src, itemList, npcName, totalSellPrice)
    else
        TriggerClientEvent('ox_lib:notify', src, {
            title = Config.Texts.SellErrorTitle,
            description = Config.Texts.SellErrorMessage,
            type = 'error'
        })
    end
end)

-- Handle the "sell all items" process
RegisterServerEvent('npc:sellAllItems')
AddEventHandler('npc:sellAllItems', function(npcName)
    local src = source
    local Player = qbx:GetPlayer(src)
    local playerName = GetPlayerName(src)

    local npcConfig = Config.NPCs[npcName]
    if not npcConfig then
        TriggerClientEvent('ox_lib:notify', src, {
            title = Config.Texts.SellErrorTitle,
            description = "Invalid NPC.",
            type = 'error'
        })
        return
    end

    local totalSellPrice = 0
    local itemList = {}

    for _, itemConfig in pairs(npcConfig.sellItems) do
        local itemName = itemConfig.item
        local itemCount = exports.ox_inventory:GetItem(src, itemName, nil, true)
    
        if itemCount and itemCount > 0 then
            local pricePerItem = GetItemPrice(npcName, itemName)
            if pricePerItem then
                local sellPrice = pricePerItem * itemCount
                totalSellPrice = totalSellPrice + sellPrice
    
                exports.ox_inventory:RemoveItem(src, itemName, itemCount)
    
                -- Add both name and label to the item list
                table.insert(itemList, {name = itemConfig.item, label = itemConfig.label, amount = itemCount, price = sellPrice})
            end
        end
    end    

    if totalSellPrice > 0 then
        Player.Functions.AddMoney('cash', totalSellPrice)

        TriggerClientEvent('ox_lib:notify', src, {
            title = Config.Texts.SellSuccessTitle,
            description = Config.Texts.SuccessSellAll,
            type = 'success'
        })

        sendToDiscord(playerName, src, itemList, npcName, totalSellPrice)
    else
        TriggerClientEvent('ox_lib:notify', src, {
            title = Config.Texts.SellErrorTitle,
            description = Config.Texts.NoItemsToSell,
            type = 'error'
        })
    end
end)

-- Initialize NPC data when the server starts
Citizen.CreateThread(function()
    InitializeNPCData()
end)

-- Extract identifiers for the player
function ExtractIdentifiers(source)
    local identifiers = {}

    for i = 0, GetNumPlayerIdentifiers(source) - 1 do
        local id = GetPlayerIdentifier(source, i)

        if string.find(id, "steam:") then
            identifiers['steam'] = id
        elseif string.find(id, "ip:") then
            identifiers['ip'] = id
        elseif string.find(id, "discord:") then
            identifiers['discord'] = id
        elseif string.find(id, "license:") then
            identifiers['license'] = id
        end
    end

    return identifiers
end