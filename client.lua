local npcs = {}
local cam = nil  -- Camera variable
local isCheckingDeath = false  -- To track if the death check loop is active

-- Closes the menu and disables the camera
function CloseMenuAndDisableCamera()
    -- Close the menu if it's open
    local openMenu = lib.getOpenContextMenu()
    if openMenu then
        lib.hideContext()
    end
    -- Disable the camera if active
    DisableCamera()
    -- Stop the death check loop
    isCheckingDeath = false
end

-- Starts the loop to check if the player is dead or dying
function StartDeathCheck()
    if not isCheckingDeath then
        isCheckingDeath = true
        Citizen.CreateThread(function()
            while isCheckingDeath do
                local playerPed = PlayerPedId()

                -- Check if the player is dead or dying
                if IsPedDeadOrDying(playerPed, true) then
                    CloseMenuAndDisableCamera()  -- Close the menu and disable the camera
                    break
                end
                Wait(1000)  -- Check every 1 second
            end
        end)
    end
end

-- Sets item prices for an NPC
function SetItemPrices(npcConfig)
    for _, itemConfig in pairs(npcConfig.sellItems) do
        if not itemConfig.price or itemConfig.price == 0 then
            itemConfig.price = math.random(itemConfig.minPrice, itemConfig.maxPrice)
        end
    end
end

-- Resets prices after a specified interval
function ResetPricesPeriodically(npcConfig)
    Citizen.CreateThread(function()
        while true do
            Wait(npcConfig.priceResetInterval * 1000)
            SetItemPrices(npcConfig)
        end
    end)
end

-- Sets the NPC animation based on the configuration
function SetNPCAnimation(npc, animation)
    if animation then
        TaskStartScenarioInPlace(npc, animation, 0, true)
    end
end

-- Creates an NPC
function CreateNPC(npcConfig)
    SetItemPrices(npcConfig)

    if npcConfig.priceResetInterval and npcConfig.priceResetInterval > 0 then
        ResetPricesPeriodically(npcConfig)
    end

    if npcConfig.blip.enabled then
        local blip = AddBlipForCoord(npcConfig.position.x, npcConfig.position.y, npcConfig.position.z)
        SetBlipSprite(blip, npcConfig.blip.blipId)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, npcConfig.blip.scale)
        SetBlipColour(blip, npcConfig.blip.color)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(npcConfig.blip.name)
        EndTextCommandSetBlipName(blip)
    end

    local pedModel = npcConfig.model
    RequestModel(GetHashKey(pedModel))
    while not HasModelLoaded(GetHashKey(pedModel)) do
        Wait(1)
    end

    local npc = CreatePed(4, GetHashKey(pedModel), npcConfig.position.x, npcConfig.position.y, npcConfig.position.z - 1.0, npcConfig.heading, false, true)
    FreezeEntityPosition(npc, true)
    SetEntityInvincible(npc, true)
    SetBlockingOfNonTemporaryEvents(npc, true)

    -- Perform the configured animation
    SetNPCAnimation(npc, npcConfig.animation)

    exports.ox_target:addLocalEntity(npc, {
        {
            name = 'npc_sell_items_' .. npcConfig.name,
            label = Config.Texts.TargetMenuTitle,
            icon = 'fa-solid fa-sack-dollar',
            onSelect = function()
                OpenSellMenu(npcConfig, npc)
            end
        }
    })

    npcs[npcConfig.name] = npc
end

-- Deletes an NPC
function DeleteNPC(npcConfig)
    if npcs[npcConfig.name] then
        DeleteEntity(npcs[npcConfig.name])
        npcs[npcConfig.name] = nil
    end
end

-- Monitors player distance to NPCs and spawns/despawns NPCs accordingly
Citizen.CreateThread(function()
    while true do
        local playerPed = PlayerPedId()
        local playerPos = GetEntityCoords(playerPed)

        for _, npcConfig in pairs(Config.NPCs) do
            local distance = #(playerPos - npcConfig.position)

            if distance < npcConfig.interactionDistance and not npcs[npcConfig.name] then
                CreateNPC(npcConfig)
            elseif distance >= npcConfig.interactionDistance and npcs[npcConfig.name] then
                DeleteNPC(npcConfig)
            end
        end

        Wait(2000)
    end
end)

-- Focuses the camera on the NPC with a smooth transition from the player
function FocusOnNPC(npc)
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local x, y, z = table.unpack(GetEntityCoords(npc))
    local heading = GetEntityHeading(npc)

    -- Calculate the position in front of the NPC
    local frontX = x - 1.0 * math.sin(math.rad(heading))
    local frontY = y + 1.0 * math.cos(math.rad(heading))
    local camZ = z + 0.7

    -- Create the camera
    cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)

    -- Initial camera position at the player's position
    SetCamCoord(cam, playerCoords.x, playerCoords.y, playerCoords.z + 0.7)
    PointCamAtCoord(cam, x, y, z + 0.65)

    -- Activate the camera
    SetCamActive(cam, true)
    RenderScriptCams(true, false, 0, true, false)

    -- Smooth transition to the NPC position
    local duration = 500 -- Duration of the transition in milliseconds
    local startTime = GetGameTimer()

    while GetGameTimer() - startTime < duration do
        local progress = (GetGameTimer() - startTime) / duration

        -- Calculate the new camera position based on progress
        local newX = playerCoords.x + (frontX - playerCoords.x) * progress
        local newY = playerCoords.y + (frontY - playerCoords.y) * progress
        local newZ = playerCoords.z + 0.7 + (camZ - (playerCoords.z + 0.7)) * progress

        -- Set the new camera position
        SetCamCoord(cam, newX, newY, newZ)
        Wait(0)
    end

    -- Set the final camera position and rotation
    SetCamCoord(cam, frontX, frontY, camZ)
    PointCamAtCoord(cam, x, y, z + 0.65)
end

-- Disables the camera
function DisableCamera()
    if cam then
        DestroyCam(cam, false)
        RenderScriptCams(false, false, 0, true, false)
        cam = nil
    end
end

-- NPC says a generic greeting
function NPCSpeak(npc)
    PlayAmbientSpeech1(npc, "GENERIC_HI", "SPEECH_PARAMS_FORCE")
end

-- Opens the sell menu and activates the camera on the NPC
function OpenSellMenu(npcConfig, npc)
    FocusOnNPC(npc)
    NPCSpeak(npc)
    StartDeathCheck()

    local options = {}
    local hasSellableItems = false

    table.insert(options, {
        title = Config.Texts.MenuHeader,
        description = "",
        icon = 'fa-solid fa-info-circle',
        disabled = true
    })

    for _, itemConfig in pairs(npcConfig.sellItems) do
        local itemLabel = itemConfig.label
        local price = itemConfig.price
        local playerItemCount = exports.ox_inventory:GetItemCount(itemConfig.item)

        if playerItemCount > 0 then
            hasSellableItems = true
        end

        table.insert(options, {
            title = itemLabel .. ' (' .. playerItemCount .. 'x)',
            description = Config.Texts.CurrentPrice .. price,
            icon = 'nui://ox_inventory/web/images/' .. itemConfig.item .. '.png',
            disabled = playerItemCount == 0,
            onSelect = function()
                if playerItemCount == 1 then
                    SellItem(itemConfig.item, price, 1, npcConfig, npc, false)
                else
                    SellItem(itemConfig.item, price, playerItemCount, npcConfig, npc, false)
                end
            end
        })
    end

    table.insert(options, 2, {
        title = Config.Texts.SellAllTitle,
        description = Config.Texts.SellAllDescription,
        icon = 'nui://ox_inventory/web/images/money.png',
        disabled = not hasSellableItems,
        onSelect = function()
            ConfirmSellAllItems(npcConfig, npc)
        end
    })

    lib.registerContext({
        id = 'sell_items_menu_' .. npcConfig.name,
        title = Config.Texts.ContextMenuTitle,
        options = options,
        onExit = function()
            CloseMenuAndDisableCamera()
        end
    })

    lib.showContext('sell_items_menu_' .. npcConfig.name)
end

-- Confirms selling all items in a dialog
function ConfirmSellAllItems(npcConfig)
    local options = {
        {
            title = Config.Texts.ConfirmSellYes,
            icon = 'fa-solid fa-check',
            onSelect = function()
                SellAllItems(npcConfig)
            end
        },
        {
            title = Config.Texts.ConfirmSellNo,
            icon = 'fa-solid fa-times',
            onSelect = function()
                lib.notify({
                    title = Config.Texts.SellCancelled,
                    type = 'error',
                })
            end
        }
    }

    lib.registerContext({
        id = 'confirm_sell_all',
        title = Config.Texts.ConfirmSellTitle,
        options = options
    })

    lib.showContext('confirm_sell_all')
end

-- Sells a specific item
function SellItem(item, price, playerItemCount, npcConfig, npc, closeMenu)
    if playerItemCount == 1 then
        TriggerServerEvent('npc:sellItem', item, 1, price)
        lib.notify({
            title = Config.Texts.SuccessSellSingle,
            type = 'success',
        })
    else
        local input = lib.inputDialog(Config.Texts.QuantityPrompt, {
            {
                type = 'slider',
                label = Config.Texts.QuantityPrompt,
                min = 1,
                max = playerItemCount,
                default = playerItemCount
            }
        })

        if input then
            local amountToSell = tonumber(input[1])
            if amountToSell and amountToSell > 0 and amountToSell <= playerItemCount then
                TriggerServerEvent('npc:sellItem', item, amountToSell, price)
                lib.notify({
                    title = Config.Texts.SuccessSellMultiple,
                    type = 'success',
                })
            else
                lib.notify({
                    title = Config.Texts.InvalidAmount,
                    type = 'error',
                })
            end
        end
    end

    if closeMenu then
        lib.hideContext()
    else
        SetTimeout(100, function()
            OpenSellMenu(npcConfig, npc)
        end)
    end
end

-- Sells all available items
function SellAllItems(npcConfig)
    for _, itemConfig in pairs(npcConfig.sellItems) do
        local playerItemCount = exports.ox_inventory:GetItemCount(itemConfig.item)
        if playerItemCount > 0 then
            TriggerServerEvent('npc:sellItem', itemConfig.item, playerItemCount, itemConfig.price)
        end
    end

    lib.notify({
        title = Config.Texts.SuccessSellAll,
        type = 'success',
    })

    lib.hideContext()
    CloseMenuAndDisableCamera()
end