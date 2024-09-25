local div = require 'config'

-- LOAD MASOK --
local framework = ''
if GetResourceState('es_extended') == 'started' then
    print('esx')
    framework = 'esx' 
elseif GetResourceState('qb-core') == 'started' then
    print('qb')
    framework = 'qb'
end

if framework == 'qb' then
    QBCore = exports["qb-core"]:GetCoreObject()
    RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
        local PlayerLoad = lib.callback.await('div:server:vipPlayerbaru', false)
        local loadTag = lib.callback.await('div:server:loadTags', false)
    end)
elseif framework == 'esx' then
    ESX = exports['es_extended']:getSharedObject()
    RegisterNetEvent('esx:playerLoaded', function(xPlayer)
        local PlayerLoad = lib.callback.await('div:server:vipPlayerbaru', false)
        local loadTag = lib.callback.await('div:server:loadTags', false)
    end)
end

CreateThread(function() 
    local PlayerLoad = lib.callback.await('div:server:vipPlayerbaru', false)
    local loadTag = lib.callback.await('div:server:loadTags', false)
end)

-- MENU -- 
RegisterCommand(div.commandmenu, function()
    local checkVip = lib.callback.await('div:server:checkVip', false)
    if checkVip then
        openVipMenu()
    else
        lib.notify({
            title = div.notify.novip.title,
            description = div.notify.novip.desc,
            type = 'warning'
        })
        TriggerServerEvent('div:server:changeTags', '')
    end
end)

function openVipMenu()
    local hari = lib.callback.await('div:server:checkTarikhvip', false)
    lib.registerContext({
        id = 'div_vip',
        title = hari..' '..div.menutext.hari,
        options = {
            {
                title = div.menutext.almari.title,
                description = div.menutext.almari.desc,
                icon = div.menutext.almari.icon,
                onSelect = function()
                    TriggerEvent('illenium-appearance:client:openClothingShopMenu') --? culik dari illenium-apperance.
                end,
            },
            {
                title = 'Rambut',
                description = 'Menu rambut',
                icon = 'user',
                onSelect = function()
                    TriggerEvent('illenium-appearance:client:OpenBarberShop')
                end,
            },
            {
                title = div.menutext.autopilot.title,
                description = div.menutext.autopilot.desc,
                icon = div.menutext.autopilot.icon,
                onSelect = function()
                    AutoPilotMenu()
                end,
            },
            {
                title = div.menutext.viptag.title,
                description = div.menutext.viptag.desc,
                icon = div.menutext.viptag.icon,
                onSelect = function()
                    local input = lib.inputDialog(div.menutext.viptag.tagtitle, {
                        {type = 'input', label = div.menutext.viptag.label, description = div.menutext.viptag.labeldesc, required = true, min = 1, max = 32}, -- jangan sentuh, {}
                    })
                    if input and input[1] then
                        TriggerServerEvent('div:server:changeTags', input[1])
                    end
                end,
            },
            {
                title = div.menutext.rockstar.title,
                description = div.menutext.rockstar.desc,
                icon = div.menutext.rockstar.icon,
                onSelect = function()
                    lib.registerContext({
                        id = 'div_rockstar',
                        title = div.rockstarbutton.tajuk,
                        options = {
                            {
                                title = div.rockstarbutton.start.title,
                                description = div.rockstarbutton.start.desc,
                                icon = div.rockstarbutton.start.icon,
                                onSelect = function()
                                    StartRecording(1)
                                end,
                            },
                            {
                                title = div.rockstarbutton.stop.title,
                                description = div.rockstarbutton.stop.desc,
                                icon = div.rockstarbutton.stop.icon,
                                onSelect = function()
                                    StopRecordingAndSaveClip()             
                                end,
                            },
                            {
                                title = div.rockstarbutton.discard.title,
                                description = div.rockstarbutton.discard.desc,
                                icon = div.rockstarbutton.discard.icon,
                                onSelect = function()
                                    StopRecordingAndDiscardClip()
                                end,
                            },
                            {
                                title = div.rockstarbutton.back.title,
                                description = div.rockstarbutton.back.desc,
                                icon = div.rockstarbutton.back.icon,
                                onSelect = function()
                                    lib.showContext('div_vip')
                                end,
                            },
                        }
                    })
                    lib.showContext('div_rockstar')
                end,
            },
        }
    })
    lib.showContext('div_vip')
end


-- AUTO PILOT --

function AutoPilotMenu()
    if not cache.vehicle then 
        lib.notify({
            title = div.notify.autopilotwarning.title,
            description = div.notify.autopilotwarning.desc,
            type = 'warning'
        })
        return
    end
    lib.registerContext({
        id = 'auto_pilot',
        title = div.autopilotbutton.tajuk,
        options = {
            {
                title = div.autopilotbutton.start.title,
                description = div.autopilotbutton.start.desc,
                icon = div.autopilotbutton.start.icon,
                onSelect = function()
                    if cache.vehicle then
                        if DoesBlipExist(GetFirstBlipInfoId(8)) then
                            local blip = GetFirstBlipInfoId(8)
                            local bCoords = GetBlipCoords(blip)
                            DriveToBlipCoord(cache.ped, bCoords, 25.0, 786603)
                        else
                            lib.notify({
                                title = div.notify.autopilotblip.title,
                                description = div.notify.autopilotblip.desc,
                                type = 'warning'
                            })
                        end
                    end
                end,
            },
            {
                title = div.autopilotbutton.stop.title,
                description = div.autopilotbutton.stop.desc,
                icon = div.autopilotbutton.stop.icon,
                onSelect = function()
                    if cache.vehicle then
                        ClearPedTasks(cache.ped)
                    end
                end,
            },
            {
                title = div.autopilotbutton.back.title,
                icon = div.autopilotbutton.back.icon,
                onSelect = function()
                    openVipMenu()
                end,
            },
        }
    })
    lib.showContext('auto_pilot')
end

function DriveToBlipCoord(player, blipCoords, speed, drivingStyle) 
    local veh = cache.vehicle
    if DoesBlipExist(GetFirstBlipInfoId(8)) then
        ClearPedTasks(player)
        TaskVehicleDriveToCoordLongrange(player, veh, blipCoords.x, blipCoords.y, blipCoords.z, tonumber(speed), drivingStyle, 2.0)
    end
end

-- VIP TAG --

local storedTag = {}
local NearbyPlayerTag = {}

CreateThread(function() 
    local loadTag = lib.callback.await('div:server:loadTags', false)
end)

RegisterNetEvent('div:server:tagLoaded', function(tag)
    storedTag = tag
end)

local function TagsText(x, y, z, font, text, speed)
    local px, py, pz = table.unpack(GetGameplayCamCoords())
    local dist = GetDistanceBetweenCoords(px,py,pz, x,y,z, 1)
    local scale = 200 / (GetGameplayCamFov() * dist)
    SetTextScale(0.0, 0.6 * scale)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextDropShadow(0, 0, 0, 0, 150)
    SetTextEdge(1, 0, 0, 0, 255)
    SetTextColour(255, 255, 255, 255)
    BeginTextCommandDisplayText("STRING")
    SetTextCentre(true)
    AddTextComponentSubstringPlayerName(text)
    SetDrawOrigin(x, y, z, 0)
    DrawText(0.0, 0.0)
    ClearDrawOrigin()
end

local keybind = lib.addKeybind({
    name = 'viptags',
    description = 'VIP TAGS',
    defaultKey = div.keybindtags,
    onPressed = function(self)
        if not bukaTags then
            bukaTags = not bukaTags
            NearbyPlayerTag = {}
            for _, id in pairs(GetActivePlayers()) do
                local myId = GetPlayerServerId(id)
                local otherPed = GetPlayerPed(id)
                local coords = GetEntityCoords(ped)
                local kordi = GetEntityCoords(ped)
                local div1 = GetEntityCoords(PlayerPedId())
                local div2 = GetEntityCoords(otherPed)
                if myId then
                    if DoesEntityExist(otherPed) then
                        local distance = #(div1 - div2)
                        if distance < 5.0 then
                            NearbyPlayerTag[#NearbyPlayerTag + 1] = id
                        end
                    end
                end
            end
            while bukaTags do
                for _, id in pairs(NearbyPlayerTag) do
                    local myId = GetPlayerServerId(id)
                    local ped = GetPlayerPed(id)
                    local coords = GetEntityCoords(ped)
                    local kordi = GetEntityCoords(ped)
                    if not cache.vehicle then
                        if DoesEntityExist(ped) then
                            if HasEntityClearLosToEntity(PlayerPedId(), ped, 17) and IsEntityVisible(ped) then
                                local distance = #(kordi - coords)
                                if distance < 4.0 then
                                    TagsText(coords.x, coords.y, coords.z + 1.15, 0, storedTag[myId], 300) -- tade tag
                                end
                            end
                        end
                    end
                end
                Wait(0)
            end
        else
            bukaTags = not bukaTags
        end
    end,
})