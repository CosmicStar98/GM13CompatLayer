--
-- The baseclass module uses upvalues to give the impression of inheritance.
--
-- At the top of your class file add:
--
--   local BaseClass = DEFINE_BASECLASS( "base_class_name" )
--
-- ( In GMod 13, DEFINE_BASECLASS is a preprocessor keyword replaced with
--   "local BaseClass = baseclass.Get" before the Lua parser sees the file.
--   In GMod 12 there is no preprocessor, so store the return value yourself. )
--
-- Baseclasses are added using baseclass.Set - this is done automatically
-- by hooking scripted_ents.Register, weapons.Register, and gamemode.Register
-- below, mirroring what the GMod 13 engine does natively.
--
-- How order-independence works:
--   Get always returns the SAME placeholder table for a given name, creating
--   it empty if needed. Set later merges the real class data into that
--   placeholder in-place. Because BaseClass in the child file is a reference
--   to the placeholder, the merge is visible through it automatically,
--   regardless of which file loaded first.
--
-- The only caveat is that classnames must be unique.
--

module( "baseclass", package.seeall )

-- TODO: fix gamemode support
-- TODO: implement vgui support
-- TODO: do more testing with this

local BaseClassTable = {}

function Get( name )
    if ( ENT )  then ENT.Base  = name end
    if ( SWEP ) then SWEP.Base = name end

    BaseClassTable[name] = BaseClassTable[name] or {}

    return BaseClassTable[name]
end

function Set( name, tab )
    if ( !BaseClassTable[name] ) then
        BaseClassTable[name] = tab
    else
        table.Merge( BaseClassTable[name], tab )
        setmetatable( BaseClassTable[name], getmetatable( tab ) )
    end
    BaseClassTable[name].ThisClass = name
end

_G.DEFINE_BASECLASS = baseclass.Get

--[[
-- Patch scripted_ents.Register so every entity class is automatically
-- registered as a base class when it is registered as an entity.
local oldSENTRegister = scripted_ents.Register
function scripted_ents.Register( tab, name, reload )
    oldSENTRegister( tab, name, reload )
    baseclass.Set( name, tab )
end

-- Patch weapons.Register for the same reason.
local oldSWEPRegister = weapons.Register
function weapons.Register( tab, name )
    oldSWEPRegister( tab, name )
    baseclass.Set( name, tab )
end

if CLIENT then
    local oldVGUIRegister = vgui.Register
    vgui.Register = function( classname, tab, base )
        oldVGUIRegister( classname, tab, base )
        baseclass.Set( classname, tab )
    end
end ]]