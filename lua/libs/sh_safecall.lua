--[[
  Safely executes a function and captures + saves errors.

  Basic usage:
    SafeCall(function()
        print("Hello world")
    end)

  With arguments:
    SafeCall(function(a, b)
        print(a + b)
    end, 5, 10)

  Returns whatever the function returns, or nil on error.
]]

local xpcall = xpcall
local unpack = unpack
local debug = debug
local ErrorNoHalt = ErrorNoHalt
local print = print
local _G = _G
local SERVER = SERVER
local LocalPlayer = LocalPlayer
local table = table
local file = file

local HandleError
local ErrorMemory = {}

local function ShouldDoLog(str)
    if !str then return false end
    str = tostring(str)

    return str ~= "" and str ~= "#EMPTY_ERROR" and str ~= "#EMPTY_TRACEBACK"
end

local function HandleError( err )
    --if err == nil then err = "#EMPTY_ERROR" end
    err = tostring(err or "#EMPTY_ERROR")
    local traceback = debug.traceback("", 2) or "#EMPTY_TRACEBACK"

    local ErrorMsg = err .. "\n" .. traceback
    --if table.HasValue( ErrorMemory, err ) then return end
    --table.insert( ErrorMemory, err )
    -- key lookups are faster than array lookups
    if ErrorMemory[err] then return end
    ErrorMemory[err] = true

    if SERVER then
        if !( ShouldDoLog(err) or ShouldDoLog(traceback) ) then return end
        local path = "errors.txt"

        if !file.Exists( path ) then
            file.Write( path, "" )
        end

        file.Append( path, ("\n\n[%s]\n%s"):format(os.date(), ErrorMsg) )
        ErrorNoHalt( "\n\n" .. ErrorMsg .. "\n\n" )

        return ErrorMsg
    else
        if !ShouldDoLog(err) then return end
        if IsValid( LocalPlayer() ) and LocalPlayer():IsAdmin() then
            ErrorNoHalt( err )
        else print( err ) end

        print( debug.traceback() .. "\n" )

        return err
    end
end

function _G.SafeCall( func, ... )

    local argcache = {...}

    if #argcache == 0 then
        return xpcall( func, HandleError )
    end

    return xpcall( function()
        return func( unpack(argcache) )
    end, HandleError )

end