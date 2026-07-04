local util = util

util.KeyValuesToTablePreserveOrder = KeyValuesToTablePreserveOrder
util.KeyValuesToTable = KeyValuesToTable
util.TableToKeyValues = TableToKeyValues

local function isArray( t )
    local max = 0

    for k in pairs(t) do
        if type(k) ~= "number" or k < 1 or k % 1 ~= 0 then
            return false
        end

        if k > max then
            max = k
        end
    end

    return true, max
end

local function countKeys( tbl, visited )
    if type(tbl) ~= "table" then
        return 0
    end

    visited = visited or {}

    if visited[tbl] then
        return 0
    end

    visited[tbl] = true

    local total = 0

    for _, v in pairs(tbl) do
        total = total + 1

        if type(v) == "table" then
            total = total + countKeys(v, visited)
        end
    end

    return total
end

local function convertKeys( tbl )
    local out = {}

    for k, v in pairs(tbl) do
        if type(v) == "table" then
            v = convertKeys(v)
        end

        if type(k) == "string" then
            local n = tonumber(k)
            if n ~= nil then
                k = n
            end
        end

        out[k] = v
    end

    return out
end

local function encodePretty( value, indent )
    indent = indent or 0

    if type(value) ~= "table" then
        return json.Encode(value)
    end

    local array, n = isArray(value)

    local pad = string.rep("    ", indent)
    local nextPad = string.rep("    ", indent + 1)

    local out = {}

    if array then
        out[#out + 1] = "[\n"

        for i = 1, n do
            out[#out + 1] = nextPad
            out[#out + 1] = encodePretty(value[i], indent + 1)

            if i < n then
                out[#out + 1] = ","
            end

            out[#out + 1] = "\n"
        end

        out[#out + 1] = pad
        out[#out + 1] = "]"
    else
        out[#out + 1] = "{\n"

        local first = true

        for k, v in pairs(value) do
            if not first then
                out[#out + 1] = ",\n"
            end

            first = false

            out[#out + 1] = nextPad
            out[#out + 1] = json.Encode(k)
            out[#out + 1] = ": "
            out[#out + 1] = encodePretty(v, indent + 1)
        end

        out[#out + 1] = "\n"
        out[#out + 1] = pad
        out[#out + 1] = "}"
    end

    return table.concat(out)
end

function util.TableToJSON( tbl, prettyPrint )
    if prettyPrint then
        return encodePretty(tbl)
    end

    return json.Encode(tbl)
end

function util.JSONToTable( json, ignoreLimits, ignoreConversions )
    local result = SafeCall(json.Decode, json)
    if !result then return nil end

    if !ignoreLimits then
        if countKeys(result) > 15000 then
            return nil
        end
    end

    if !ignoreConversions then
        result = convertKeys(result)
    end

    return result
end

-- Base64
local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
function util.Base64Encode( data )
    return ((data:gsub('.', function(x) 
        local r,b='',x:byte()
        for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
        return r;
    end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if (#x < 6) then return '' end
        local c=0
        for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
        return b:sub(c+1,c+1)
    end)..({ '', '==', '=' })[#data%3+1])
end

function util.Base64Decode( data )
    data = string.gsub(data, '[^'..b..'=]', '')
    return (data:gsub('.', function(x)
        if (x == '=') then return '' end
        local r,f='',(b:find(x)-1)
        for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
        return r;
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if (#x ~= 8) then return '' end
        local c=0
        for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
        return string.char(c)
    end))
end

local STEAM_BASE = 76561197960265728
function util.SteamIDFrom64( id64 )
    id64 = tonumber(id64)
    if !id64 then return nil end

    local accountID = id64 - STEAM_BASE
    if accountID < 0 then return nil end

    local y = accountID % 2
    local z = math.floor(accountID / 2)

    return string.format("STEAM_%d:%d:%d", 1, y, z)
end

function util.SteamIDTo64( steamid )
    if type(steamid) ~= "string" then return nil end

    local x, y, z = steamid:match("^STEAM_(%d+):(%d+):(%d+)$")
    if !x then return nil end

    x, y, z = tonumber(x), tonumber(y), tonumber(z)

    local accountID = (z * 2) + y

    return tostring(STEAM_BASE + accountID)
end

-- Returns year, month, day and hour, minute, second in a formatted string.
function util.DateStamp()
    local t = os.date( "*t" )
    return t.year .. "-" .. t.month .. "-" .. t.day .. " " .. Format( "%02i-%02i-%02i", t.hour, t.min, t.sec )
end

-- Formats a float by stripping off extra 0's and .'s
--  0.00 -> 0
--  0.10 -> 0.1
--  1.00 -> 1
--  1.49 -> 1.49
--  5.90 -> 5.9
function util.NiceFloat( f )
    local str = string.format( "%f", f )

    str = str:TrimRight( "0" )
    str = str:TrimRight( "." )

    return str
end

-- Convert a string to a certain type
function util.StringToType( str, typename )

    typename = typename:lower()

    if ( typename == "vector" ) then return Vector( str ) end
    if ( typename == "angle" ) then return Angle( str ) end
    if ( typename == "float" || typename == "number" ) then return tonumber( str ) end
    if ( typename == "int" ) then local v = tonumber( str ) return v and math.Round( v ) or nil end
    if ( typename == "bool" || typename == "boolean" ) then return tobool( str ) end
    if ( typename == "string" ) then return tostring( str ) end
    if ( typename == "entity" ) then return Entity( str ) end

    MsgN( "util.StringToType: unknown type \"", typename, "\"!" )

end

-- Convert a type to a (nice, but still parsable) string
function util.TypeToString( v )

    local iD = TypeID( v )

    if ( iD == TYPE_VECTOR or iD == TYPE_ANGLE ) then
        return string.format( "%.2f %.2f %.2f", v:Unpack() )
    end

    if ( iD == TYPE_NUMBER ) then
        return util.NiceFloat( v )
    end

    return tostring( v )

end

-- Helper for the following functions. This is not ideal but we cannot change this because it will break existing addons.
local function GetUniqueID( sid )
    return util.CRC( "gm_" .. sid .. "_gm" )
end

-- Gets persistent data of an offline player using their SteamID.
function util.GetPData( steamid, name, default )
    -- First try looking up using the new key
    local key = Format( "%s[%s]", util.SteamIDTo64( steamid ), name )
    local val = sql.QueryValue( "SELECT value FROM playerpdata WHERE infoid = " .. SQLStr( key ) .. " LIMIT 1" )
    if ( val == nil ) then

        -- Not found? Look using the old key
        local oldkey = Format( "%s[%s]", GetUniqueID( steamid ), name )
        val = sql.QueryValue( "SELECT value FROM playerpdata WHERE infoid = " .. SQLStr( oldkey ) .. " LIMIT 1" )
        if ( val == nil ) then return default end

    end

    return val
end

-- Sets persistent data for offline player using their SteamID.
function util.SetPData( steamid, name, value )
    local key = Format( "%s[%s]", util.SteamIDTo64( steamid ), name )
    sql.Query( "REPLACE INTO playerpdata ( infoid, value ) VALUES ( " .. SQLStr( key ) .. ", " .. SQLStr( value ) .. " )" )
end

-- Removes persistent data of an offline player using their SteamID.
function util.RemovePData( steamid, name )
    -- First the old key
    local oldkey = Format( "%s[%s]", GetUniqueID( steamid ), name )
    sql.Query( "DELETE FROM playerpdata WHERE infoid = " .. SQLStr( oldkey ) )

    -- Then the new key. util.SteamIDTo64 is not ideal, but nothing we can do about it now
    local key = Format( "%s[%s]", util.SteamIDTo64( steamid ), name )
    sql.Query( "DELETE FROM playerpdata WHERE infoid = " .. SQLStr( key ) )
end

-- Creates a timer object. The returned timer will be already started with given duration.
--  https://wiki.facepunch.com/gmod/util.Timer
local T = {
    -- Resets the timer to nothing.
    Reset = function( self )
        self.starttime = CurTime() - self.starttime
        self.endtime = nil
    end,

    -- Starts the timer, call with end time.
    Start = function( self, time )
        self.starttime = CurTime()
        self.endtime = CurTime() + ( time or 0 )
    end,

    -- Returns true if the timer has been started.
    Started = function( self )
        return self.endtime != nil
    end,

    -- Returns true if the time has elapsed.
    Elapsed = function( self )
        return self.endtime == nil or self.endtime <= CurTime()
    end,

    -- Returns the amount of time that has passed since the Timer was started.
    GetElaspedTime = function( self )
        return self:Started() and CurTime() - self.starttime or self.starttime
    end
}

T.__index = T

-- Create a new timer object.
function util.Timer( startdelay )
    local t = {}
    setmetatable( t, T )
    t:Start( startdelay or 0 )

    return t
end

-- An object returned by util.Stack.
--  Like a Lua table, a Stack is a container. It follows the principle of LIFO (last in, first out).
--  The Stack works like a stack of papers: the first page you put down (push) will be the last one you remove (pop). That also means that the last page you put down, will be the first to be removed.
--  https://wiki.facepunch.com/gmod/Stack
local STACK = {
    -- Push an item onto the stack.
    Push = function( self, obj )
        local len = self[ 0 ] + 1
        self[ len ] = obj
        self[ 0 ] = len
    end,

    -- Pop an item from the stack.
    Pop = function( self, num )
        local len
        num, len = PopStack( self, num )

        if ( num == 0 ) then return nil end

        local newlen = len - num
        self[ 0 ] = newlen

        newlen = newlen + 1
        local ret = self[ newlen ]

        -- Pop up to the last element
        for i = len, newlen, -1 do
            self[ i ] = nil
        end

        return ret
    end,

    -- Pop an item from the stack.
    PopMulti = function( self, num )
        local len
        num, len = PopStack( self, num )

        if ( num == 0 ) then return {} end

        local newlen = len - num
        self[ 0 ] = newlen

        local ret = {}
        local retpos = 0

        -- Pop each element and add it to the table
        -- Iterate in reverse since the stack is internally stored
        -- with 1 being the bottom element and len being the top
        -- But the return will have 1 as the top element
        for i = len, newlen + 1, -1 do
            retpos = retpos + 1
            ret[ retpos ] = self[ i ]

            self[ i ] = nil
        end

        return ret
    end,

    -- Get the item at the top of the stack.
    Top = function( self )
        local len = self[ 0 ]

        if ( len == 0 ) then return nil end

        return self[ len ]
    end,

    -- Returns the size of the stack.
    Size = function( self )
        return self[ 0 ]
    end
}

STACK.__index = STACK

-- Returns a new Stack object.
function util.Stack()
    return setmetatable( { [ 0 ] = 0 }, STACK )
end