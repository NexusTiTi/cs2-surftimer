function UserIdToSlot(id)
    return bit.band(id, 0xFF)
end

function EntityIndex(id)
    return bit.band(id, 0x3FFF)
end
    

function EHandleToHScript(iPawnId)
    return EntIndexToHScript(EntityIndex(iPawnId))
end

function SplitVectorString(str)
    -- split on comma
    -- x y z
    local split = {}
    for s in string.gmatch(str, "([^,]+)") do
        table.insert(split, s)
    end
    -- Convert to numbers
    for i, s in ipairs(split) do
        split[i] = tonumber(s)
    end
    -- Convert to vector
    return Vector(split[1], split[2], split[3])
end

function CalculateBoxFromVectors(v1, v2)
    local mins = Vector(math.min(v1.x, v2.x), math.min(v1.y, v2.y), math.min(v1.z, v2.z))
    local maxs = Vector(math.max(v1.x, v2.x), math.max(v1.y, v2.y), math.max(v1.z, v2.z))

    local center = Vector((mins.x + maxs.x) / 2, (mins.y + maxs.y) / 2, (mins.z + maxs.z) / 2)

    -- Adjust mins and maxs relative to center
    mins = mins - center
    maxs = maxs - center

    return center, mins, maxs
end

function CalculateVectorsFromBox(center, mins, maxs)
    -- Re-adjust mins and maxs to be absolute rather than relative to the center
    local absoluteMins = center + mins
    local absoluteMaxs = center + maxs

    -- Determine the original vectors v1 and v2
    local v1 = Vector(math.min(absoluteMins.x, absoluteMaxs.x), math.min(absoluteMins.y, absoluteMaxs.y), math.min(absoluteMins.z, absoluteMaxs.z))
    local v2 = Vector(math.max(absoluteMins.x, absoluteMaxs.x), math.max(absoluteMins.y, absoluteMaxs.y), math.max(absoluteMins.z, absoluteMaxs.z))

    return v1, v2
end

function CalculateBoxCorners(v1, v2)
    -- Find the min and max for each dimension
    local minX = math.min(v1.x, v2.x)
    local maxX = math.max(v1.x, v2.x)
    local minY = math.min(v1.y, v2.y)
    local maxY = math.max(v1.y, v2.y)
    local minZ = math.min(v1.z, v2.z)
    local maxZ = math.max(v1.z, v2.z)

    -- Create the eight corners
    local corners = {
        Vector(minX, minY, minZ), -- Corner 1
        Vector(maxX, minY, minZ), -- Corner 2
        Vector(minX, maxY, minZ), -- Corner 3
        Vector(maxX, maxY, minZ), -- Corner 4
        Vector(minX, minY, maxZ), -- Corner 5
        Vector(maxX, minY, maxZ), -- Corner 6
        Vector(minX, maxY, maxZ), -- Corner 7
        Vector(maxX, maxY, maxZ)  -- Corner 8
    }

    return corners
end

function IsPointInBox(point, minVec, maxVec)
    return (point.x >= minVec.x and point.x <= maxVec.x) and
        (point.y >= minVec.y and point.y <= maxVec.y) and
        (point.z >= minVec.z and point.z <= maxVec.z)
end

function CalculateExtentsFromMinsMaxs(mins, maxs)
    return Vector(math.max(math.abs(mins.x), math.abs(maxs.x)),
        math.max(math.abs(mins.y), math.abs(maxs.y)),
        math.max(math.abs(mins.z), math.abs(maxs.z)))
end

function FormatTime(time)
    local abs = math.abs(time)
    local minutes = math.floor(abs / 60)
    local seconds = abs - minutes * 60
    local milliseconds = (abs - math.floor(abs)) * 1000
    return string.format("%02d:%02d:%03d", minutes, seconds, milliseconds)
end

function TimerOnce(delay, callback, id)
    local ent = Entities:FindByName(nil, "wst_timer_once_" .. id)
    if ent == nil then
        ent = SpawnEntityFromTableSynchronous("info_target", {targetname = "wst_timer_once_" .. id})
    end
    ent:SetThink(
        function()
            callback()
            return nil
        end,
        "timer_once",
        delay
    )
end

function GetPlayerByUserId(userId)
    local playerSlot = UserIdToSlot(userId)

    local chatPlayer = nil
    local players = Entities:FindAllByClassname("player")
    for i, player in ipairs(players)
    do
        if UserIdToSlot(player.user_id) == playerSlot then
            chatPlayer = players[i]
            break
        end
    end
    if (chatPlayer == nil) then
        return nil
    end
    return chatPlayer
end