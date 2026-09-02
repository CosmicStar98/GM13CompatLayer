local player = player
local util = util
local _G = _G
local PLAYER = FindMetaTable("Player")
local SWEP = FindMetaTable("Weapon")
local CVAR = FindMetaTable("ConVar")

_G.IsPlayerSpeaking = function(ply)
    if !ply then return false end
    return ply:IsSpeaking()
end
PLAYER.GetAimVector = PLAYER.GetCursorAimVector
SWEP.SetHoldType = SWEP.SetWeaponHoldType
isValid = IsValid

function SafeRemoveEntity( ent )
    if ( !IsValid(ent) or ent:IsPlayer() ) then return end
    ent:Remove()
end

function SafeRemoveEntityDelayed( ent, timedelay )
    if ( !IsValid(ent) or ent:IsPlayer() ) then return end
    timer.Simple( timedelay, function() SafeRemoveEntity(ent) end )
end

function sql.IndexExists( name )
    local r = sql.Query( "SELECT name FROM sqlite_master WHERE name=" .. SQLStr(name) .. " AND type='index'" )
    return r and true or false
end

function IsValid( object )
    if ( !object ) then return false end

    local isvalid = object.IsValid
    if ( !isvalid ) then return false end

    return isvalid( object )
end

-- Setter functions for the console variables
--  note: these appear to lag behind and cause a situation where getting the value is unsynced from the set value
--  nothing I can really do about that since these aren't coded on an engine level. I suggest wrapping them inside a timer
--  whenever you need to use any of these.
function CVAR:SetBool( value )
    RunConsoleCommand( self:GetName(), value and "1" or "0" )
end

function CVAR:SetFloat( value )
    RunConsoleCommand( self:GetName(), tostring(value) )
end

function CVAR:SetInt( value )
    value = tonumber(value)

    if value < 0 then
        value = math.ceil(value)
    else
        value = math.floor(value)
    end

    RunConsoleCommand( self:GetName(), tostring(value) )
end

function CVAR:SetString( value )
    RunConsoleCommand( self:GetName(), tostring(value) )
end

function CVAR:Revert()
    RunConsoleCommand( self:GetName(), self:GetDefault() )
end


-- gmod 12 has FindMetaTable but not RegisterMetaTable
-- FindMetaTable returns the metatable stored in _R with that name.
-- therefor something like this works:
--[[
    local meta = {
        MetaName = "__TEST__",
        MetaID = 9999
    }

    r["__TEST__"] = meta

    local found = FindMetaTable("__TEST__")

    print("found:", found)
    print("same:", found == meta)
]]
local _R = debug.getregistry()
local _maxMetaID = 0

-- MetaID seems irrelevant and we can't have an engine level assignment in lua alone
-- so just make a random one and try our best to ensure it isn't taken
for _, meta in pairs(_R) do
    if type(meta) == "table" and type(meta.MetaID) == "number" then
        _maxMetaID = math.max( _maxMetaID, meta.MetaID )
    end
end

function RegisterMetaTable( name, tbl )
    assert(type(name) == "string",
        "bad argument #1 to RegisterMetaTable (string expected)")

    assert(type(tbl) == "table",
        "bad argument #2 to RegisterMetaTable (table expected)")

    if _R[name] ~= nil then
        error("MetaTable " .. name .. " already exists in the registry!")
    end

    tbl.MetaName = name
    tbl.MetaID = math.random(_maxMetaID + 1, _maxMetaID + 1000)

    _R[name] = tbl
end

game.GetWorld = GetWorldEntity or Entity(0)
game.MaxPlayers = MaxPlayers
game.IsDedicated = isDedicatedServer
game.SinglePlayer = SinglePlayer

function game.AddParticles( path )
-- Stub
end

http.Fetch = http.Get

function http.Post( ... )
-- Stub
end

function resource.AddWorkshop( ... )
-- Stub
end

function PLAYER:SteamID64()
    local steamid = self:SteamID()

    -- Bots / invalid SteamIDs
    if steamid == "BOT" then
        return "90071996842377216"
    end

    local parts = string.Explode( ":", steamid )

    if #parts ~= 3 then
        return "0"
    end

    local y = tonumber( parts[2] )
    local z = tonumber( parts[3] )

    if not y or not z then
        return "0"
    end

    local base = "76561197960265728"
    local add = z * 2 + y

    -- add is normally small enough to be represented safely.
    local result = tonumber( base:sub(-6) ) + add

    local high = base:sub(1, -7)

    if result >= 1000000 then
        result = result - 1000000

        local highNum = tonumber( high ) + 1
        return tostring( highNum ) .. string.format( "%06d", result )
    end

    return high .. string.format( "%06d", result )
end

-- Gets the player with the specified SteamID.
function player.GetBySteamID( ID )
    ID = string.upper( ID )

    for _, pl in pairs( player.GetAll() ) do
        if ( pl:IsValid() and pl:IsPlayer() and pl:SteamID() == ID ) then
            return pl
        end
    end

    return false
end

function player.GetBySteamID64( ID )
    for _, pl in pairs( player.GetAll() ) do
        if ( pl:IsValid() and pl:IsPlayer() and pl:SteamID64() == ID ) then
            return pl
        end
    end

    return false
end

if CLIENT then
    -- Unsupported:
    --  scanlines
    --  italic
    --  strikeout
    --  symbol
    --  rotary
    local makeFont = surface.CreateFont
    function surface.CreateFont(fontName, dataORsize, ...)
        if type(dataORsize) == "table" then
            local data = dataORsize

            local baseFont   = data.font or "Arial"
            local size       = data.size or 13
            local weight     = data.weight or 500
            local antialias  = (data.antialias ~= false)  -- default true
            local additive   = data.additive or false
            local shadow     = data.shadow or false
            local outline    = data.outline or false
            local blur       = data.blursize or 0

            if data.outline then antialias = false end

            return makeFont(
                baseFont, size, weight, antialias, additive,
                fontName,  -- new font name
                shadow, outline, blur
            )
        else return makeFont(fontName, dataORsize, ...) end
    end
end