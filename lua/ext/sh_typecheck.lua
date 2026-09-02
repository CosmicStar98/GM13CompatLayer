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

function isthread( cor )
    local ok = pcall(coroutine.status, cor)
    return ok
end

function IsValidMaterial( strName )
    local mat, basetex

    mat = Material( strName )
    basetex = mat:GetMaterialTexture( "$basetexture" )

    return !basetex:IsError()
end



-- gotta catch em all!
--  not all of https://wiki.facepunch.com/gmod/Enums/TYPE is implemented!
rawset(_G, "TYPE_NONE",             -1) -- unimplemented
rawset(_G, "TYPE_INVALID",          -1)
rawset(_G, "TYPE_NIL",               0)
rawset(_G, "TYPE_BOOL",              1)
rawset(_G, "TYPE_LIGHTUSERDATA",     2) -- unimplemented
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
rawset(_G, "TYPE_VIDEO",            33) -- unimplemented
rawset(_G, "TYPE_FILE",             34) -- unimplemented
rawset(_G, "TYPE_LOCOMOTION",       35) -- unimplemented
rawset(_G, "TYPE_PATH",             36) -- unimplemented
rawset(_G, "TYPE_NAVAREA",          37) -- unimplemented
rawset(_G, "TYPE_SOUNDHANDLE",      38) -- unimplemented
rawset(_G, "TYPE_NAVLADDER",        39) -- unimplemented
rawset(_G, "TYPE_PARTICLESYSTEM",   40) -- unimplemented
rawset(_G, "TYPE_PROJECTEDTEXTURE", 41) -- unimplemented
rawset(_G, "TYPE_PHYSCOLLIDE",      42) -- unimplemented
rawset(_G, "TYPE_SURFACEINFO",      43) -- unimplemented
rawset(_G, "TYPE_COUNT",            44)
rawset(_G, "TYPE_COLOR",           255)


local typeMap = {
    ["nil"]        = TYPE_NIL,
    ["Angle"]      = TYPE_ANGLE,
    ["boolean"]    = TYPE_BOOL,
    ["number"]     = TYPE_NUMBER,
    ["string"]     = TYPE_STRING,
    ["table"]      = TYPE_TABLE,
    ["function"]   = TYPE_FUNCTION,
    ["Panel"]      = TYPE_PANEL,
    ["Vector"]     = TYPE_VECTOR,

    ["CompBuffer"]   = TYPE_USERDATA,

    ["Entity"]         = TYPE_ENTITY,
    ["Player"]         = TYPE_ENTITY,
    ["NPC"]            = TYPE_ENTITY,
    ["Vehicle"]        = TYPE_ENTITY,
    ["Weapon"]         = TYPE_ENTITY,
    ["CSEnt"]          = TYPE_ENTITY,
    ["CSENT_vehicle"]  = TYPE_SCRIPTEDVEHICLE,

    ["PhysObj"]            = TYPE_PHYSOBJ,
    ["CTakeDamageInfo"]    = TYPE_DAMAGEINFO,
    ["CEffectData"]        = TYPE_EFFECTDATA,
    ["CMoveData"]          = TYPE_MOVEDATA,
    ["CUserCmd"]           = TYPE_USERCMD,
    ["ConVar"]             = TYPE_CONVAR,
    ["CLuaParticle"]       = TYPE_PARTICLE,
    ["CLuaEmitter"]        = TYPE_PARTICLEEMITTER,
    ["ITexture"]           = TYPE_TEXTURE,
    ["IMaterial"]          = TYPE_MATERIAL,
    ["CRecipientFilter"]   = TYPE_RECIPIENTFILTER,
    ["bf_read"]            = TYPE_USERMSG,
    ["IMesh"]              = TYPE_IMESH,
    ["ISave"]              = TYPE_SAVE,
    ["IRestore"]           = TYPE_RESTORE,
    ["VMatrix"]            = TYPE_MATRIX,
    ["CSoundPatch"]        = TYPE_SOUND,
    ["pixelvis_handle_t"]  = TYPE_PIXELVISHANDLE,
    ["dlight_t"]           = TYPE_DLIGHT
}

-- type override so we can return the correct type for our custom types
local oldtype = type
local getmetatable = getmetatable
function type( value )  -- returns a type name
    local native = oldtype(value)

    -- if the type doesn't map into what is done natively by the original type
    -- then begin to probe the metatables and provide a name.
    local meta = getmetatable(value)
    local name = meta and meta.MetaName

    if typeMap[name] then
        return name
    end

    return native
end

function TypeID( value ) -- returns a numerical ID mapped to a particular type
    return typeMap[type(value)] or TYPE_INVALID
end
