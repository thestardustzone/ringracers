// Ring Records by Yellow/@GlowingTail [3rd Revision]
-- Keeps track of play count, cosmetics usage, map stats, etc. and saves them to files.

local stats = {
    players = {},
    skins = {},
    colors = {},
    followers = {},
    maps = {},

    lastMap = 0,
    lastMode = -1,
    exitMap = false,
    exitNodes = {}
}

local recordFiles = {
    players =   'PlayerRecords.txt',
    skins =     'SkinUsage.txt',
    colors =    'ColorUsage.txt',
    followers = 'FollowerUsage.txt',
    maps =      'MapRecords.txt'
}

local function syncData(n)
    stats.players = n($)
    stats.skins = n($)
    stats.colors = n($)
    stats.followers = n($)
    stats.maps = n($)
    
    stats.lastMap = n($)
    stats.lastMode = n($)
    stats.exitMap = n($)
    stats.exitNodes = n($)
end

local function resetVars(map, mode)
    if type(map) == 'number'
        stats.lastMap = map
    else
        stats.lastMap = 0
    end

    if type(mode) == 'number'
        stats.lastMode = mode
    else
        stats.lastMode = -1
    end

    stats.exitMap = false
    stats.exitNodes = {}
end

local function splitString(string, separator)
	local strTable = {}
    separator = ('[^%s]+'):format(separator)

    for split in string:gmatch(separator) do
        table.insert(strTable, tonumber(split) or split)
    end

	return strTable
end

local function totable(str)
    if (type(str) ~= 'string') or (str == 'none') return {} end

    local table = {}
    local splits = splitString(str, '\|:')

    for i = 1, #splits, 2 do
        table[splits[i]] = tonumber(splits[i + 1])
    end

    return table
end

local function loadRecordFiles()
    if (isdedicatedserver and players[0] or consoleplayer) ~= server return end
	
    for infoType, fileName in pairs(recordFiles) do
        local currentFile = io.openlocal('RingRecords/' + fileName, 'r')
        if not currentFile continue end

        currentFile:read('*line')

        local statsType = stats[infoType]
        if infoType == 'players'
            for row in currentFile:lines() do
                local columns = splitString(row, '\t')
                statsType[columns[1]] = {
                    name =          tostring(columns[2]),
                    played =        tonumber(columns[3]),
                    placements =    totable(columns[4]),
                    skinusage =     totable(columns[7]),
                    colorusage =    totable(columns[8]),
                    followerusage = totable(columns[9]),
                    eliminated =    tonumber(columns[5]),
                    disconnects =   tonumber(columns[6])
                }
            end
        elseif infoType == 'skins'
            for row in currentFile:lines() do
                local columns = splitString(row, '\t')
                statsType[columns[1]] = {
                    name =          tostring(columns[2]),
                    played =        tonumber(columns[3]),
                    usage =         tonumber(columns[4]),
                    colorusage =    totable(columns[5])
                }
            end
        elseif infoType == 'colors'
            for row in currentFile:lines() do
                local columns = splitString(row, '\t')
                statsType[columns[1]] = {
                    name =          tostring(columns[1]),
                    played =        tonumber(columns[2]),
                    usage =         tonumber(columns[3]),
                    skinusage =     totable(columns[4]),
                    followerusage = totable(columns[5])
                }
            end
        elseif infoType == 'followers'
            for row in currentFile:lines() do
                local columns = splitString(row, '\t')
                statsType[columns[1]] = {
                    name =          tostring(columns[1]),
                    played =        tonumber(columns[2]),
                    usage =         tonumber(columns[3]),
                    colorusage =    totable(columns[4])
                }
            end
        elseif infoType == 'maps'
            for row in currentFile:lines() do
                local columns = splitString(row, '\t')
                statsType[columns[1]] = {
                    name =          tostring(columns[2]),
                    played =        tonumber(columns[3]),
                    skipped =       tonumber(columns[4]),
                    reran =         tonumber(columns[5])
                }
            end
        end

        currentFile:close()
    end
end

local function saveRecordFiles()
    if (isdedicatedserver and players[0] or consoleplayer) ~= server return end
	
    for infoType, fileName in pairs(recordFiles) do
        local currentFile = io.openlocal('RingRecords/' + fileName, 'w')
        currentFile:setvbuf('line')

        local statsType, headers, data = stats[infoType]
        if infoType == 'players'
            headers = {'Public Key', 'Player Name', 'Play Count', 'Finish Placements', 'Times Eliminated', 'Disconnects', 'Skin Usage', 'Color Usage', 'Follower Usage'}
            currentFile:write(table.concat(headers, '\t'))

            data = '\n' + ('%s\t'):rep(#headers)
            for pID, pEntry in pairs(statsType) do
                local placements, skinUsage, colorUsage, followerUsage
                for i = 1, 16 do
                    placements = ($ and $ + '|' or '') + i + ':' + (pEntry.placements[i] or 0)
                end

                for sName, sUsage in pairs(pEntry.skinusage) do
                    skinUsage = ($ and $ + '|' or '') + sName + ':' + sUsage
                end

                for cName, cUsage in pairs(pEntry.colorusage) do
                    colorUsage = ($ and $ + '|' or '') + cName + ':' + cUsage
                end

                for fName, fUsage in pairs(pEntry.followerusage) do
                    followerUsage = ($ and $ + '|' or '') + fName + ':' + fUsage
                end

                currentFile:write(data:format(
                    pID,
                    pEntry.name,
                    pEntry.played,
                    placements,
                    pEntry.eliminated,
                    pEntry.disconnects,
                    skinUsage or 'None',
                    colorUsage or 'None',
                    followerUsage or 'None'
                ))
            end
        elseif infoType == 'skins'
            headers = {'ID', 'Name', 'Play Count', 'Usage', 'Color Usage'}
            currentFile:write(table.concat(headers, '\t'))

            data = '\n' + ('%s\t'):rep(#headers)
            for sID, sEntry in pairs(statsType) do
                local colorUsage
                for cName, cUsage in pairs(sEntry.colorusage) do
                    colorUsage = ($ and $ + '|' or '') + cName + ':' + cUsage
                end

                currentFile:write(data:format(
                    sID,
                    sEntry.name,
                    sEntry.played,
                    sEntry.usage,
                    colorUsage or 'None'
                ))
            end
        elseif infoType == 'colors'
            headers = {'Name', 'Play Count', 'Usage', 'Skin Usage', 'Follower Usage'}
            currentFile:write(table.concat(headers, '\t'))

            data = '\n' + ('%s\t'):rep(#headers)
            for cID, cEntry in pairs(statsType) do
                local skinUsage, followerUsage
                for sName, sUsage in pairs(cEntry.skinusage) do
                    skinUsage = ($ and $ + '|' or '') + sName + ':' + sUsage
                end

                for fName, fUsage in pairs(cEntry.followerusage) do
                    followerUsage = ($ and $ + '|' or '') + fName + ':' + fUsage
                end

                currentFile:write(data:format(
                    cID,
                    cEntry.played,
                    cEntry.usage,
                    skinUsage or 'None',
                    followerUsage or 'None'
                ))
            end
        elseif infoType == 'followers'
            headers = {'Name', 'Play Count', 'Usage', 'Color Usage'}
            currentFile:write(table.concat(headers, '\t'))

            data = '\n' + ('%s\t'):rep(#headers)
            for fID, fEntry in pairs(statsType) do
                local colorUsage
                for cName, cUsage in pairs(fEntry.colorusage) do
                    colorUsage = ($ and $ + '|' or '') + cName + ':' + cUsage
                end

                currentFile:write(data:format(
                    fID,
                    fEntry.played,
                    fEntry.usage,
                    colorUsage or 'None'
                ))
            end
        elseif infoType == 'maps'
            headers = {'Internal Name', 'Map Name', 'Play Count', 'Times Skipped', 'Times Reran'}
            currentFile:write(table.concat(headers, '\t'))

            data = '\n' + ('%s\t'):rep(#headers)
            for mID, mEntry in pairs(statsType) do
                currentFile:write(data:format(
                    mID,
                    mEntry.name,
                    mEntry.played,
                    mEntry.skipped,
                    mEntry.reran
                ))
            end
        end

        currentFile:flush()
        currentFile:close()
    end
end

function stats:newEntry(userdata, id)
    local type = userdataType(userdata)
    local nEntry

    if type == 'player_t'
        self.players[userdata.publickey] = {
            name = userdata.name,
            played =        0,
            placements =    {},
            skinusage =     {},
            colorusage =    {},
            followerusage = {},
            eliminated =    0,
            disconnects =   0}

        nEntry = self.players[userdata.publickey]
    elseif type == 'skin_t'
        self.skins[userdata.name] = {
            name = userdata.realname,
            played =        0,
            usage =         0,
            colorusage =    {}}

        nEntry = self.skins[userdata.name]
    elseif type == 'skincolor_t'
        self.colors[userdata.name] = {
            name = userdata.name,
            played =        0,
            usage =         0,
            skinusage =     {},
            followerusage = {}}

        nEntry = self.colors[userdata.name]
    elseif type == 'follower_t'
        self.followers[userdata.name] = {
            name = userdata.name,
            played =        0,
            usage =         0,
            colorusage =    {}}

        nEntry = self.followers[userdata.name]
    elseif type == 'mapheader_t' and id
        local mapInternalName = G_BuildMapName(id)
        local mapDisplayName = G_BuildMapTitle(id)

        self.maps[mapInternalName] = {
            name = mapDisplayName,
            played =        0,
            skipped =       0,
            reran =         0}

        nEntry = self.maps[mapInternalName]
    end

    return nEntry
end

local function playerJoin(node)
    if not netgame return end
    local player = players[node]
    local pID = player.publickey
    
    if tonumber(pID) == 0 return end
    local pEntry = stats.players[pID]

    if not pEntry
        pEntry = stats:newEntry(player)
    end
end

local function playerQuit(player, reason)
    if not netgame return end
    local pID = player.publickey
    
    if tonumber(pID) == 0 return end
    local pEntry = stats.players[pID]

    pEntry.name = player.name

    if (reason < KR_PINGLIMIT or reason > KR_TIMEOUT) return end
    pEntry.disconnects = $ + 1
end

local function trackGame()
    if not netgame return end
    stats.exitMap = exitcountdown > 0

    for player in players.iterate do
        if player.spectator continue end
        local pID = player.publickey
        
        if tonumber(pID) == 0 continue end
        local pEntry = stats.players[pID]

        if not stats.exitNodes[#player]
            if player.pflags & (PF_ELIMINATED | PF_NOCONTEST | PF_LOSTLIFE)
                pEntry.eliminated = $ + 1
            elseif not player.exiting
                continue end

            pEntry.played = $ + 1
            pEntry.name = player.name
            pEntry.placements[player.position] = ($ or 0) + 1

            local color = skincolors[player.skincolor]
            local skin = skins[player.skin]
            
            if color
                local cEntry = stats.colors[color.name]
                if not cEntry
                    cEntry = stats:newEntry(color)
                end

                cEntry.played = $ + 1
                cEntry.skinusage[skin.name] = ($ or 0) + 1
                pEntry.colorusage[color.name] = ($ or 0) + 1
            end

            if skin
                local sEntry = stats.skins[skin.name]
                local skinColorUse = (skin.prefcolor == #color) and 'Default' or color.name
                if not sEntry
                    sEntry = stats:newEntry(skin)
                end

                sEntry.played = $ + 1
                sEntry.colorusage[skinColorUse] = ($ or 0) + 1
                pEntry.skinusage[skin.name] = ($ or 0) + 1
            end

            if followers and player.followerskin > 0
                local follower = followers[player.followerskin]                
                local fEntry = stats.followers[follower.name]
                if not fEntry and follower
                    fEntry = stats:newEntry(follower)
                end

                fEntry.played = $ + 1
                pEntry.followerusage[follower.name] = ($ or 0) + 1
                
                local followerColor, followerColorUse = player.followercolor
                local colMatch = {
                    [0xFFFF] = {'Match', #color},
                    [0xFFFE] = {'Opposite', ColorOpposite(#color)},
                    [follower.defaultcolor] = {'Default', follower.defaultcolor}
                }

                if colMatch[followerColor] or (followerColor <= #skincolors)
                    followerColorUse, followerColor = unpack(colMatch[$2] or {skincolors[$2].name, $2})
                    followerColor = skincolors[$]

                    local fcEntry = stats.colors[followerColor.name]
                    if not fcEntry and followerColor
                        fcEntry = stats:newEntry(followerColor)
                    end

                    fcEntry.played = $ + 1
                    fcEntry.followerusage[follower.name] = ($ or 0) + 1
                    fEntry.colorusage[followerColorUse] = ($ or 0) + 1
                end
            end

            stats.exitNodes[#player] = true
        end
    end
end

local function refreshUniqueUsage()
    for sID, sEntry in pairs(stats.skins) do
        sEntry.usage = 0

        for pID, pEntry in pairs(stats.players) do
            if pEntry.skinusage[sID]
                sEntry.usage = $ + 1
            end
        end
    end

    for cID, cEntry in pairs(stats.colors) do
        cEntry.usage = 0

        for pID, pEntry in pairs(stats.players) do
            if pEntry.colorusage[cID]
                cEntry.usage = $ + 1
            end
        end
    end

    for fID, fEntry in pairs(stats.followers) do
        fEntry.usage = 0

        for pID, pEntry in pairs(stats.players) do
            if pEntry.followerusage[fID]
                fEntry.usage = $ + 1
            end
        end
    end
end

local function progressMap(currentMap)
    if not netgame return end
    local mID = G_BuildMapName(currentMap)

    if not stats.maps[mID]
        stats:newEntry(mapheaderinfo[currentMap], currentMap)
    end

    if stats.lastMap
        mID = G_BuildMapName(stats.lastMap)
        local mEntry = stats.maps[mID]
        local finishCheck = stats.exitMap or next(stats.exitNodes) ~= nil
        local repeatRound = (stats.lastMap == currentMap) and (stats.lastMode == gametype)
		
        if finishCheck and not repeatRound
            mEntry.played = $ + 1

        elseif finishCheck and repeatRound
            mEntry.reran = $ + 1

        elseif not (finishCheck or repeatRound)
            mEntry.skipped = $ + 1
        end

        refreshUniqueUsage()
        saveRecordFiles()
    end

    resetVars(currentMap, gametype)
end

loadRecordFiles()
addHook('PlayerJoin', playerJoin)
addHook('PlayerQuit', playerQuit)
addHook('ThinkFrame', trackGame)
addHook('MapLoad', progressMap)
addHook('NetVars', syncData)
addHook('GameQuit', resetVars)