local div = require 'config'
local framework = ''
local ESX = exports['es_extended']:getSharedObject()

-- THREAD

CreateThread(function() 
    local success, result = pcall(MySQL.scalar.await, 'SELECT 1 FROM div_vip')
	if not success then
		MySQL.query.await([[CREATE TABLE `div_vip` (
			`license` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
			`registered` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'not',
            `date_expiried` date NULL DEFAULT NULL
		)]])
		print("^1div_vip^0 SQL INSTALL SUCCESSFULLY")
	end

    local berjaya, hasil = pcall(MySQL.scalar.await, 'SELECT 1 FROM div_tags')
    if not berjaya then
        MySQL.query.await([[CREATE TABLE `div_tags` (
            `license` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
            `tags` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL,
            PRIMARY KEY (`license`) USING BTREE
	    )]])
	    print("^5div_tags^0 SQL INSTALL SUCCESSFULLY")
    end
end)

CreateThread(function()
    while true do
        exports.oxmysql:updateSync('UPDATE div_vip SET registered = ?, date_expiried = ? WHERE registered != ? AND date_expiried IS NOT NULL AND date_expiried <= CURDATE()', {'not', nil, 'not'})
        Wait(10 * 60000)
    end
end)

-- PANGGILBALIK

lib.callback.register('div:server:vipPlayerbaru', function(source)
    local src = source
    local  Player = ESX.GetPlayerFromId(src)
    local citizenid = ESX.GetIdentifier(src)
    MySQL.query('SELECT * FROM div_vip WHERE license = ?', {citizenid}, function(result)
        if #result == 0 then
            MySQL.insert('INSERT INTO div_vip (license) VALUES (?)', {citizenid})
        end
    end)
    MySQL.query('SELECT * FROM div_tags WHERE license = ?', {citizenid}, function(result)
        if #result == 0 then
            MySQL.insert('INSERT INTO div_tags (license) VALUES (?)', {citizenid})
        end
    end)
    return
end)

lib.callback.register('div:server:checkVip', function(source)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(source)
    local cid = ESX.GetIdentifier(src)
    local p = promise.new()
    exports.oxmysql:scalar('SELECT * FROM div_vip WHERE license = @cid AND registered = "yes"', {
        ['@cid'] = cid
    }, function(vip)
        if vip then
            p:resolve(true)
        else
            p:resolve(false)
        end
    end)
    return Citizen.Await(p)
end)

lib.callback.register('div:server:checkTarikhvip', function(source)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local cid = ESX.GetIdentifier(src)
    local p = promise.new()

    exports.oxmysql:execute('SELECT * FROM div_vip WHERE license = @cid AND registered = "yes"', {
        ['@cid'] = cid
    }, function(result)
        if result and #result > 0 then
            local dateExpiried = tonumber(result[1].date_expiried) / 1000
            local currentTime = os.time()
            local daysLeft = math.ceil((dateExpiried - currentTime) / (24 * 60 * 60))
            p:resolve(daysLeft)
        else
            p:resolve(nil)
        end
    end)

    return Citizen.Await(p)
end)

-- COMMAND --

lib.addCommand(div.admin.commandbagi, {
    help = 'Add VIP to a player',
    params = {
        {
            name = 'target',
            type = 'playerId',
            help = div.admin.commandhelpbagi,
        },
    },
    restricted = div.admin.groupadmin
}, function(source, args, raw)
    xPlayer = ESX.GetPlayerFromId(args.target)
    cid = ESX.GetIdentifier(args.target)
    local qry = 'UPDATE div_vip SET date_expiried = ?, registered = ? WHERE license = ?'
    local updateVIP = exports.oxmysql:updateSync(qry,
    {
        os.date('%Y-%m-%d', os.time() + (30 * 24 * 60 * 60)), 
        'yes',
        cid
    })
end)

lib.addCommand(div.admin.commandremove, {
    help = 'Add VIP to a player',
    params = {
        {
            name = 'target',
            type = 'playerId',
            help = div.admin.commandhelpremove,
        },
    },
    restricted = div.admin.groupadmin
}, function(source, args, raw)
    local xPlayer = ESX.GetPlayerFromId(args.target)
    local cid = ESX.GetIdentifier(args.target)
    local qry = 'UPDATE div_vip SET date_expiried = ?, registered = ? WHERE license = ?'
    local updateVIP = exports.oxmysql:updateSync(qry,
    {
        nil, 
        'not',
        cid
    })
end)

-- VIP TAG --

local TagSaya = {}

lib.callback.register('div:server:loadTags', function(source)
    local src = source
    local tagsJson = nil
    local xPlayer = ESX.GetPlayerFromId(src)
    local cid = ESX.GetIdentifier(src)
    MySQL.scalar('SELECT tags FROM div_tags WHERE license = @license', {
        ['@license'] = cid
    }, function(tagsJson)
        TagSaya[src] = json.decode(tagsJson)
        TriggerClientEvent("div:server:tagLoaded", -1, TagSaya)
    end)    
    return true
end)

RegisterNetEvent('div:server:changeTags', function(args)
    local src = source
        local xPlayer = ESX.GetPlayerFromId(src)
        local cid = ESX.GetIdentifier(src)
        local tag = args
        if string.len(tag) < 32 then
            exports.oxmysql:update("INSERT INTO div_tags (license, tags) VALUES (@license, @tags) ON DUPLICATE KEY UPDATE tags = VALUES(tags)", {
                ['@license'] = cid,
                ['@tags'] = json.encode(tag)
            })
            TagSaya[src] = tag
            TriggerClientEvent("div:server:tagLoaded", -1, TagSaya)
        end
    return true
end)