local string = string


-- Converts a cardinal (111) number to its ordinal/sequential variation (111th).
--  https://en.wikipedia.org/wiki/Ordinal_numeral
function string.CardinalToOrdinal( cardinal )

    local basedigit = cardinal % 10

    if ( basedigit == 1 ) then
        if ( cardinal % 100 == 11 ) then
            return cardinal .. "th"
        end

        return cardinal .. "st"
    elseif ( basedigit == 2 ) then
        if ( cardinal % 100 == 12 ) then
            return cardinal .. "th"
        end

        return cardinal .. "nd"
    elseif ( basedigit == 3 ) then
        if ( cardinal % 100 == 13 ) then
            return cardinal .. "th"
        end

        return cardinal .. "rd"
    end

    return cardinal .. "th"

end

-- Inserts commas for every third digit of a given number.
function string.Comma( number, str )

    if ( str ~= nil and not isstring( str ) ) then
        error( "bad argument #2 to 'string.Comma' (string expected, got " .. type( str ) .. ")", 2 )
    elseif ( str ~= nil and string.match( str, "%d" ) ~= nil ) then
        error( "bad argument #2 to 'string.Comma' (non-numerical values expected, got " .. str .. ")", 2 )
    end

    local replace = str == nil and "%1,%2" or "%1" .. str .. "%2"

    if ( isnumber( number ) ) then
        number = string.format( "%f", number )
        number = string.match( number, "^(.-)%.?0*$" ) -- Remove trailing zeros
    end

    local index = -1
    while index ~= 0 do number, index = string.gsub( number, "^(-?%d+)(%d%d%d)", replace ) end

    return number

end

-- Interpolates a given string with the given table. This is useful for formatting localized strings.
function string.Interpolate( str, lookuptable )
    return ( string.gsub( str, "{([_%a][_%w]*)}", lookuptable ) )
end

-- Creates a string from a Color variable.
function string.FromColor( color )
    return Format( "%i %i %i %i", color.r, color.g, color.b, color.a )
end

-- Fetches a Color type from a string.
function string.ToColor( str )
    local r, g, b, a = string.match( str, "(%d+) (%d+) (%d+) (%d+)" )

    return Color( tonumber( r ) or 255, tonumber( g ) or 255, tonumber( b ) or 255, tonumber( a ) or 255 )
end

-- Note: These use Lua index numbering, not what you'd expect
-- ie they start from 1, not 0.
function string.SetChar( s, k, v )
    return string.sub( s, 0, k - 1 ) .. v .. string.sub( s, k + 1 )
end

function string.GetChar( s, k )
    return string.sub( s, k, k )
end

-- Takes a string and escapes it for insertion in to a JavaScript string
local javascript_escape_replacements = {
    ["\\"] = "\\\\",
    ["\0"] = "\\x00" ,
    ["\b"] = "\\b" ,
    ["\t"] = "\\t" ,
    ["\n"] = "\\n" ,
    ["\v"] = "\\v" ,
    ["\f"] = "\\f" ,
    ["\r"] = "\\r" ,
    ["\""] = "\\\"",
    ["\'"] = "\\\'",
    ["`"] = "\\`",
    ["$"] = "\\$",
    ["{"] = "\\{",
    ["}"] = "\\}"
}

function string.JavascriptSafe( str )
    str = string.gsub( str, ".", javascript_escape_replacements )

    -- U+2028 and U+2029 are treated as line separators in JavaScript, handle separately as they aren't single-byte
    str = string.gsub( str, "\226\128\168", "\\\226\128\168" )
    str = string.gsub( str, "\226\128\169", "\\\226\128\169" )

    return str
end

--[[---------------------------------------------------------
    Name: string.PatternSafe( string )
    Desc: Takes a string and escapes it for insertion in to a Lua pattern
-----------------------------------------------------------]]
local pattern_escape_replacements = {
    ["("] = "%(",
    [")"] = "%)",
    ["."] = "%.",
    ["%"] = "%%",
    ["+"] = "%+",
    ["-"] = "%-",
    ["*"] = "%*",
    ["?"] = "%?",
    ["["] = "%[",
    ["]"] = "%]",
    ["^"] = "%^",
    ["$"] = "%$",
    ["\0"] = "%z"
}

function string.PatternSafe( str )
    return ( string.gsub( str, ".", pattern_escape_replacements ) )
end

string.Split = string.split

-- Removes the extension of a path.
--  See string.GetExtensionFromFilename for a function to retrieve the extension instead.
function string.StripExtension( path )
    for i = #path, 1, -1 do
        local c = string.sub( path, i, i )

        if ( c == "/" or c == "\\" ) then return path end
        if ( c == "." ) then return string.sub( path, 1, i - 1 ) end
    end

    return path
end

-- Returns whether or not the first string starts with the second.
function string.StartsWith( str, start )
    return string.sub( str, 1, string.len( start ) ) == start
end
string.StartWith = string.StartsWith

-- Returns whether or not the second passed string matches the end of the first.
function string.EndsWith( str, endStr )
    return endStr == "" or string.sub( str, -string.len( endStr ) ) == endStr
end

-- Converts a "string_likeThis" to a more human-friendly "String like This".
function string.NiceName( name )

    name = name:Replace( "_", " " )

    -- Try to split text into words, where words would start with single uppercase character
    local newParts = {}
    for id, str in ipairs( string.Explode( " ", name ) ) do
        local wordStart = 1

        for i = 2, str:len() do
            local c = str[ i ]

            if ( c:upper() == c ) then
                local toAdd = str:sub( wordStart, i - 1 )

                if ( toAdd:upper() == toAdd ) then continue end
                table.insert( newParts, toAdd )
                wordStart = i
            end

        end

        table.insert( newParts, str:sub( wordStart, str:len() ) )
    end

    -- Capitalize
    --[[
    for i, word in ipairs( newParts ) do
        if ( #word == 1 ) then
            newParts[i] = string.upper( word )
        else
            newParts[i] = string.upper( string.sub( word, 1, 1 ) ) .. string.sub( word, 2 )
        end
    end

    return table.concat( newParts, " " )]]

    local ret = table.concat( newParts, " " )
    ret = string.upper( string.sub( ret, 1, 1 ) ) .. string.sub( ret, 2 )

    return ret

end

local function pluralizeString( str, quantity )
    return str .. ( ( quantity ~= 1 ) and "s" or "" )
end

-- Formats the supplied number (in seconds) to the highest possible time unit.
function string.NiceTime( seconds )

    if ( seconds == nil ) then return "a few seconds" end

    if ( seconds < 60 ) then
        local t = math.floor( seconds )
        return t .. pluralizeString( " second", t )
    end

    if ( seconds < 60 * 60 ) then
        local t = math.floor( seconds / 60 )
        return t .. pluralizeString( " minute", t )
    end

    if ( seconds < 60 * 60 * 24 ) then
        local t = math.floor( seconds / (60 * 60) )
        return t .. pluralizeString( " hour", t )
    end

    if ( seconds < 60 * 60 * 24 * 7 ) then
        local t = math.floor( seconds / ( 60 * 60 * 24 ) )
        return t .. pluralizeString( " day", t )
    end

    if ( seconds < 60 * 60 * 24 * 365 ) then
        local t = math.floor( seconds / ( 60 * 60 * 24 * 7 ) )
        return t .. pluralizeString( " week", t )
    end

    local t = math.floor( seconds / ( 60 * 60 * 24 * 365 ) )
    return t .. pluralizeString( " year", t )

end