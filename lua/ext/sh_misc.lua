local player = player
local _G = _G
local PLAYER = FindMetaTable("Player")
local SWEP = FindMetaTable("Weapon")

PLAYER.GetAimVector = PLAYER.GetCursorAimVector
SWEP.SetHoldType = SWEP.SetWeaponHoldType

function sql.IndexExists( name )
    local r = sql.Query( "SELECT name FROM sqlite_master WHERE name=" .. SQLStr( name ) .. " AND type='index'" )
    return r and true or false
end

game.GetWorld = GetWorldEntity or Entity(0)
game.MaxPlayers = MaxPlayers
game.IsDedicated = isDedicatedServer
game.SinglePlayer = SinglePlayer

-- Gets the player with the specified SteamID.
function player.GetBySteamID( ID )
    ID = string.upper( ID )

    for _, pl in pairs( player.GetAll() ) do
        if ( pl:IsValid() && pl:IsPlayer() && pl:SteamID() == ID )	then
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

-- Some type checking
isentity = IsEntity
function isnumber(num)     return type(num) == "number"    end
function isbool(bool)      return type(bool) == "boolean"  end
function isstring(str)     return type(str) == "string"    end
function istable(tbl)      return type(tbl) == "table"     end
function isvector(vec)     return type(vec) == "Vector"    end
function isangle(ang)      return type(ang) == "Angle"     end
function isfunction(func)  return type(func) == "function" end
function ispanel(pnl)      return type(pnl) == "Panel"     end
function isphysobj(obj)    return IsPhysicsObject(obj)     end
function ismatrix(pill)
    local neo, vec = pcall(function()
        return pill:GetTranslation()
    end)

    return neo and type(vec) == "Vector"
end

function issound( snd )
    local ok, result = pcall(function()
        return type(snd.IsPlaying)    == "function"
           and type(snd.ChangePitch)  == "function"
           and type(snd.ChangeVolume) == "function"
    end)
    return ok and result == true
end

function IsValidMaterial( strName )
    local mat, basetex

    mat = Material( strName )
    basetex = mat:GetMaterialTexture( "$basetexture" )

    return !basetex:IsError()
end



-- gotta catch em all!
--  most of https://wiki.facepunch.com/gmod/Enums/TYPE is unimplemented!
rawset(_G, "TYPE_NONE",             -1)
rawset(_G, "TYPE_INVALID",          -1)
rawset(_G, "TYPE_NIL",               0)
rawset(_G, "TYPE_BOOL",              1)
rawset(_G, "TYPE_LIGHTUSERDATA",     2)
rawset(_G, "TYPE_NUMBER",            3)
rawset(_G, "TYPE_STRING",            4)
rawset(_G, "TYPE_TABLE",             5)
rawset(_G, "TYPE_FUNCTION",          6)
rawset(_G, "TYPE_USERDATA",          7)
rawset(_G, "TYPE_THREAD",            8)
rawset(_G, "TYPE_ENTITY",            9)
rawset(_G, "TYPE_VECTOR",           10)
rawset(_G, "TYPE_ANGLE",            11)
rawset(_G, "TYPE_PHYSOBJ",          12)
rawset(_G, "TYPE_SAVE",             13)
rawset(_G, "TYPE_RESTORE",          14)
rawset(_G, "TYPE_DAMAGEINFO",       15)
rawset(_G, "TYPE_EFFECTDATA",       16)
rawset(_G, "TYPE_MOVEDATA",         17)
rawset(_G, "TYPE_RECIPIENTFILTER",  18)
rawset(_G, "TYPE_USERCMD",          19)
rawset(_G, "TYPE_SCRIPTEDVEHICLE",  20)
rawset(_G, "TYPE_MATERIAL",         21)
rawset(_G, "TYPE_PANEL",            22)
rawset(_G, "TYPE_PARTICLE",         23)
rawset(_G, "TYPE_PARTICLEEMITTER",  24)
rawset(_G, "TYPE_TEXTURE",          25)
rawset(_G, "TYPE_USERMSG",          26)
rawset(_G, "TYPE_CONVAR",           27)
rawset(_G, "TYPE_IMESH",            28)
rawset(_G, "TYPE_MATRIX",           29)
rawset(_G, "TYPE_SOUND",            30)
rawset(_G, "TYPE_PIXELVISHANDLE",   31)
rawset(_G, "TYPE_DLIGHT",           32)
rawset(_G, "TYPE_VIDEO",            33)
rawset(_G, "TYPE_FILE",             34)
rawset(_G, "TYPE_LOCOMOTION",       35)
rawset(_G, "TYPE_PATH",             36)
rawset(_G, "TYPE_NAVAREA",          37)
rawset(_G, "TYPE_SOUNDHANDLE",      38)
rawset(_G, "TYPE_NAVLADDER",        39)
rawset(_G, "TYPE_PARTICLESYSTEM",   40)
rawset(_G, "TYPE_PROJECTEDTEXTURE", 41)
rawset(_G, "TYPE_PHYSCOLLIDE",      42)
rawset(_G, "TYPE_SURFACEINFO",      43)
rawset(_G, "TYPE_COUNT",            44)
rawset(_G, "TYPE_COLOR",           255)

local typeMap = {
    ["nil"]      = TYPE_NIL,
    ["string"]   = TYPE_STRING,
    ["number"]   = TYPE_NUMBER,
    ["table"]    = TYPE_TABLE,
    ["boolean"]  = TYPE_BOOL,
    ["function"] = TYPE_FUNCTION,
    ["Entity"]   = TYPE_ENTITY,
    ["Player"]   = TYPE_ENTITY,
    ["NPC"]      = TYPE_ENTITY,
    ["Vector"]   = TYPE_VECTOR,
    ["Angle"]    = TYPE_ANGLE,
    ["Color"]    = TYPE_COLOR,
}

function TypeID( v )
    -- special exemptions from doing type when type(v) doesnt return anything we want
    if IsPhysicsObject(v) then return TYPE_PHYSOBJ end
    if IsValidMaterial(v) then return TYPE_MATERIAL end
    if ConVarExists(v) then return TYPE_CONVAR end
    if ismatrix(v) then return TYPE_MATRIX end
    if issound(v) then return TYPE_SOUND end

    return typeMap[type(v)] or TYPE_NIL
end
