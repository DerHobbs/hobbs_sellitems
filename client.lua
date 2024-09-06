local npcs = {}
local npcBlips = {}
local cam = nil
local isCheckingDeath = false
local isCameraFocused = false
local hasNpcSpoken = {}

-- Close the menu and disable the camera
function CloseMenuAndDisableCamera()
    local openMenu = lib.getOpenContextMenu()
    if openMenu then
        lib.hideContext()
    end
    DisableCamera()
    isCheckingDeath = false
    isCameraFocused = false
    hasNpcSpoken = {}
end

-- Start checking if the player is dead or dying
function StartDeathCheck()
    if not isCheckingDeath then
        isCheckingDeath = true
        Citizen.CreateThread(function()
            while isCheckingDeath do
                local playerPed = PlayerPedId()
                if IsPedDeadOrDying(playerPed, true) then
                    CloseMenuAndDisableCamera()
                    break
                end
                Wait(1000)
            end
        end)
    end
end

-- Set NPC animation based on configuration
function SetNPCAnimation(npc, animation)
    if animation then
        TaskStartScenarioInPlace(npc, animation, 0, true)
    end
end

-- Create an NPC with a blip and interaction options
function CreateNPC(npcConfig)
    local pedModel = npcConfig.model
    RequestModel(GetHashKey(pedModel))
    while not HasModelLoaded(GetHashKey(pedModel)) do
        Wait(0)
    end

    local npc = CreatePed(4, GetHashKey(pedModel), npcConfig.position.x, npcConfig.position.y, npcConfig.position.z - 1.0, npcConfig.heading, false, true)
    FreezeEntityPosition(npc, true)
    SetEntityInvincible(npc, true)
    SetBlockingOfNonTemporaryEvents(npc, true)

    SetNPCAnimation(npc, npcConfig.animation)

    exports.ox_target:addLocalEntity(npc, {
        {
            name = 'npc_sell_items_' .. npcConfig.name,
            label = locale('sell_items'),
            icon = 'fa-solid fa-sack-dollar',
            onSelect = function()
                OpenSellMenu(npcConfig, npc)
            end
        }
    })

    npcs[npcConfig.name] = npc
end

-- Create blip outside NPC spawn logic to ensure it's always visible
function CreateNPCBlip(npcConfig)
    if npcConfig.blip.enabled and not npcBlips[npcConfig.name] then
        local blip = AddBlipForCoord(npcConfig.position.x, npcConfig.position.y, npcConfig.position.z)
        SetBlipSprite(blip, npcConfig.blip.blipId)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, npcConfig.blip.scale)
        SetBlipColour(blip, npcConfig.blip.color)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(npcConfig.blip.name)
        EndTextCommandSetBlipName(blip)
        
        npcBlips[npcConfig.name] = blip
    end
end

-- Delete an NPC but not the blip
function DeleteNPC(npcConfig)
    if npcs[npcConfig.name] then
        DeleteEntity(npcs[npcConfig.name])
        npcs[npcConfig.name] = nil
    end
end

-- Monitor player distance to NPCs and manage NPC spawn/despawn
Citizen.CreateThread(function()
    for _, npcConfig in pairs(Config.NPCs) do
        -- Create blip at the start
        CreateNPCBlip(npcConfig)
    end

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

-- Open the sell menu and focus the camera on the NPC
function OpenSellMenu(npcConfig, npc)
    -- Ask the server if the player can interact based on job and rank
    TriggerServerEvent('npc:checkPlayerJob', npcConfig.name)
end

-- Event to allow the player to open the sell menu if the job check passes
RegisterNetEvent('npc:allowOpenSellMenu')
AddEventHandler('npc:allowOpenSellMenu', function(npcConfigName)
    local npcConfig = Config.NPCs[npcConfigName]
    local npc = npcs[npcConfig.name]

    if not isCameraFocused then
        FocusOnNPC(npc)
        isCameraFocused = true
    end

    -- Check if NPC has already spoken
    if not hasNpcSpoken[npcConfig.name] then
        NPCSpeak(npc)
        hasNpcSpoken[npcConfig.name] = true
    end

    StartDeathCheck()
    TriggerServerEvent('npc:requestSellMenu', npcConfig.name)
end)

RegisterNetEvent('npc:openSellMenu')
AddEventHandler('npc:openSellMenu', function(npcName, sellItems)
    local options = {}
    local hasSellableItems = false

    table.insert(options, {
        title = locale('menu_header'),
        description = "",
        icon = 'fa-solid fa-info-circle',
        disabled = true
    })

    for _, item in pairs(sellItems) do
        local itemLabel = item.label
        local price = item.price
        local playerItemCount = exports.ox_inventory:GetItemCount(item.name)

        if playerItemCount > 0 then
            hasSellableItems = true
        end

        table.insert(options, {
            title = itemLabel .. ' (' .. playerItemCount .. 'x)',
            description = locale('current_price') .. price,
            icon = 'nui://ox_inventory/web/images/' .. item.name .. '.png',
            disabled = playerItemCount == 0,
            onSelect = function()
                if playerItemCount == 1 then
                    TriggerServerEvent('npc:sellItem', item.name, 1, npcName)
                    SetTimeout(100, function()
                        TriggerServerEvent('npc:requestSellMenu', npcName)
                    end)
                else
                    local input = lib.inputDialog(locale('quantity_prompt'), {
                        {
                            type = 'slider',
                            label = locale('quantity_prompt'),
                            min = 1,
                            max = playerItemCount,
                            default = playerItemCount
                        }
                    })

                    if input then
                        local amountToSell = tonumber(input[1])
                        if amountToSell and amountToSell > 0 and amountToSell <= playerItemCount then
                            TriggerServerEvent('npc:sellItem', item.name, amountToSell, npcName)
                            SetTimeout(100, function()
                                TriggerServerEvent('npc:requestSellMenu', npcName)
                            end)
                        else
                            lib.notify({
                                title = locale('invalid_amount'),
                                type = 'error',
                            })
                        end
                    else
                        TriggerServerEvent('npc:requestSellMenu', npcName)
                    end
                end
            end
        })
    end

    table.insert(options, 2, {
        title = locale('sell_all_items'),
        description = locale('sell_all_description'),
        icon = 'nui://ox_inventory/web/images/money.png',
        disabled = not hasSellableItems,
        onSelect = function()
            local confirmOptions = {
                {
                    title = locale('confirm_sell_yes'),
                    icon = 'fa-solid fa-check',
                    onSelect = function()
                        TriggerServerEvent('npc:sellAllItems', npcName)
                        CloseMenuAndDisableCamera()
                    end
                },
                {
                    title = locale('confirm_sell_no'),
                    icon = 'fa-solid fa-times',
                    onSelect = function()
                        lib.notify({
                            title = locale('sell_cancelled'),
                            type = 'error',
                        })
                        CloseMenuAndDisableCamera()
                    end
                }
            }

            lib.registerContext({
                id = 'confirm_sell_all',
                title = locale('confirm_sell'),
                options = confirmOptions,
                onExit = function()
                    CloseMenuAndDisableCamera()
                end
            })

            lib.showContext('confirm_sell_all')
        end
    })

    lib.registerContext({
        id = 'sell_items_menu_' .. npcName,
        title = locale('sell_menu'),
        options = options,
        onExit = function()
            CloseMenuAndDisableCamera()
        end
    })

    lib.showContext('sell_items_menu_' .. npcName)
end)

function DisableCamera()
    if cam then
        DestroyCam(cam, false)
        RenderScriptCams(false, false, 0, true, false)
        cam = nil
    end
end

function FocusOnNPC(npc)
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local x, y, z = table.unpack(GetEntityCoords(npc))
    local heading = GetEntityHeading(npc)

    local frontX = x - 1.0 * math.sin(math.rad(heading))
    local frontY = y + 1.0 * math.cos(math.rad(heading))
    local camZ = z + 0.7

    cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)

    SetCamCoord(cam, playerCoords.x, playerCoords.y, playerCoords.z + 0.7)
    PointCamAtCoord(cam, x, y, z + 0.65)

    SetCamActive(cam, true)
    RenderScriptCams(true, false, 0, true, false)

    local duration = 500
    local startTime = GetGameTimer()

    while GetGameTimer() - startTime < duration do
        local progress = (GetGameTimer() - startTime) / duration

        local newX = playerCoords.x + (frontX - playerCoords.x) * progress
        local newY = playerCoords.y + (frontY - playerCoords.y) * progress
        local newZ = playerCoords.z + 0.7 + (camZ - (playerCoords.z + 0.7)) * progress

        SetCamCoord(cam, newX, newY, newZ)
        Wait(0)
    end

    SetCamCoord(cam, frontX, frontY, camZ)
    PointCamAtCoord(cam, x, y, z + 0.65)
end

function NPCSpeak(npc)
    PlayAmbientSpeech1(npc, "GENERIC_HI", "SPEECH_PARAMS_FORCE")
end