local table = table

table.SortDesc = table.sortdesc

-- Packs a set of items into a table and returns the new table. It is meant as an alternative implementation of table.pack from newer versions of Lua.
function table.Pack( ... )
    return { ... }, select( "#", ... )
end

-- Returns whether or not the given table is empty.
--  This works on both sequential and non-sequential tables, and is a lot faster for non-sequential tables than table.Count(tbl) == 0.
--  For sequential tables it is better to use tab[1] == nil.
function table.IsEmpty( tab )
    return next( tab ) == nil
end

-- Removes the first instance of a given value from the specified table with table.remove, then returns the key that the value was found at.
function table.RemoveByValue( tbl, val )
    local key = table.KeyFromValue( tbl, val )
    if ( !key ) then return false end

    if ( type( key ) == "number" ) then
        table.remove( tbl, key )
    else
        tbl[ key ] = nil
    end

    return key
end

-- Returns an array of values of given with given key from each table of given table.
function table.MemberValuesFromKey( tab, key )
    local res = {}

    for k, v in pairs( tab ) do
        if ( type( v ) == "table" and v[ key ] ~= nil ) then res[ #res + 1 ] = v[ key ] end
    end

    return res
end

-- Iterates for each key-value pair in the table, calling the function with the key and value of the pair. If the function returns anything, the loop is broken.
--  This was deprecated in Lua 5.1 and removed in 5.2. You should use pairs instead. (same thing with table.foreach and table.foreachi)
function table.ForEach( tab, funcname )
    for k, v in pairs( tab ) do
        funcname( k, v )
    end
end

-- Returns all keys of a table.
function table.GetKeys( tab )
    local keys = {}
    local id = 1

    for k, v in pairs( tab ) do
        keys[ id ] = k
        id = id + 1
    end

    return keys
end

function table.move( sourceTbl, from, to, dest, destTbl )
    if ( !type( sourceTbl ) == "table" ) then error( "bad argument #1 to 'move' (table expected, got " .. type( sourceTbl ) .. ")", 2 ) end
    if ( !type( from ) == "number" ) then error( "bad argument #2 to 'move' (number expected, got " .. type( from ) .. ")", 2 ) end
    if ( !type( to ) == "number" ) then error( "bad argument #3 to 'move' (number expected, got " .. type( to ) .. ")", 2 ) end
    if ( !type( dest ) == "number" ) then error( "bad argument #4 to 'move' (number expected, got " .. type( dest ) .. ")", 2 ) end
    if ( destTbl ~= nil ) then
        if ( !type( destTbl ) == "table" ) then error( "bad argument #5 to 'move' (table expected, got " .. type( destTbl ) .. ")", 2 ) end
    else destTbl = sourceTbl end

    local buffer = { unpack( sourceTbl, from, to ) }

    dest = math.floor( dest - 1 )
    for i, v in ipairs( buffer ) do
        destTbl[ dest + i ] = v
    end

    return destTbl
end

-- Flips key-value pairs of each element within a table, so that each value becomes the key, and each key becomes the value.
function table.Flip( tab )
    local res = {}

    for k, v in pairs( tab ) do
        res[ v ] = k
    end

    return res
end

-- Performs an inline Fisher-Yates shuffle on the table in O(n) time.
function table.Shuffle( t )
    local n = #t

    for i = 1, n - 1 do
        local j = math.random( i, n )
        t[ i ], t[ j ] = t[ j ], t[ i ]
    end
end

-- Returns a reversed copy of a sequential table.
--  Any non-sequential and non-numeric keyvalue pairs will not be copied.
function table.Reverse( tbl )
    local len = #tbl
    local ret = {}

    for i = len, 1, -1 do
        ret[ len - i + 1 ] = tbl[ i ]
    end

    return ret
end