local file = file
local type = type
local pairs = pairs
local ipairs = ipairs
local sort   = table.sort
local upper  = string.upper
local sub    = string.sub
local string = string
local tostring = tostring
local assert = assert
local include = include
local AddCSLuaFile = AddCSLuaFile

-- TODO: add fileio by discord/@cookie_cakes

-- hold on to the original functions
local oldAppend     = file.Append
local oldCreateDir  = file.CreateDir
local oldDelete     = file.Delete
local oldExists     = file.Exists
local oldExistsEx   = file.ExistsEx
local oldFind       = file.Find
local oldFindDir    = file.FindDir
local oldFindInLua  = file.FindInLua
local oldIsDir      = file.IsDir
local oldRead       = file.Read
local oldSize       = file.Size
local oldTFind      = file.TFind
local oldTime       = file.Time
local oldWrite      = file.Write

-- Search path translation
local SEARCH_PATHS = {
    DATA       = { "DATA",       false, "" },
    MOD        = { "MOD",        true,  "" },
    GARRYSMOD  = { "MOD",        true,  "" },
    GAME       = { "GAME",       true,  "" },

    THIRDPARTY = { "THIRDPARTY", true,  "addons/" },
    WORKSHOP   = { "WORKSHOP",   true,  "addons/" },
    GAMEBIN    = { "GAMEBIN",    true,  "bin/" },
    DOWNLOAD   = { "DOWNLOAD",   true,  "lua/_downloaded/" },

    LUA        = { "LUA",        nil,   nil },
    LCL        = { "LCL",        nil,   nil },
    LSV        = { "LSV",        nil,   nil },
    LUAMENU    = { "LUAMENU",    nil,   nil },

    BASE_PATH  = { "BASE_PATH",  true,  nil },
    EXECUTABLE_PATH = { "EXECUTABLE_PATH", true, "bin/" }
}

local function resolvePath(path, searchPath)
    if searchPath == nil then
        return "DATA", false, path
    end

    if type(searchPath) == "boolean" then
        return nil, searchPath, path
    end

    if type(searchPath) != "string" then
        return nil, nil, nil
    end

    local key = upper(searchPath)
    local resolved = SEARCH_PATHS[key]

    if resolved then
        return resolved[1], resolved[2], resolved[3]
    end

    return key, true, path
end

-- Helper functions
local function joinPrefix(prefix, path)
    if !prefix or prefix == "" then
        return path
    end

    if !path or path == "" then
        return prefix
    end

    return prefix .. path
end

local function translate(name, path)
    local kind, base, prefix = resolvePath(path)

    if !kind and type(path) == "boolean" then
        return nil, base, name
    end

    if !kind then
        return nil, nil, nil
    end

    if base == nil then
        return kind, nil, nil
    end

    return kind, base, joinPrefix(prefix, name)
end

local function isLuaPath(kind)
    return kind == "LUA"
        or kind == "LCL"
        or kind == "LSV"
        or kind == "LUAMENU"
end


local function readLua(filepath)
    -- The physical GMod 12 lua/ directory can be reached with the old
    -- base-folder flag.
    local value = oldRead("lua/" .. filepath, true)

    if value ~= nil then
        return value
    end

    -- Compatibility fallback for old code which happened to use a root-
    -- relative path.
    return oldRead(filepath, true)
end

local function findLua(pattern)
    local files = oldFindInLua(pattern)

    if !files then
        return {}, {}
    end

    -- FindInLua only supplies filenames. It gives us no reliable directory
    -- enumeration API for every Lua search root, so we intentionally do not
    -- manufacture directory entries.
    return files, {}
end


-- Sorting
local function sortNames(list, descending)
    sort(list, function(a, b)
        if descending then
            return a > b
        end

        return a < b
    end)
end

local function sortByNumber(list, valueFunction, descending)
    sort(list, function(a, b)
        local av = valueFunction(a) or 0
        local bv = valueFunction(b) or 0

        if av == bv then
            return a < b
        end

        if descending then
            return av > bv
        end

        return av < bv
    end)
end

local function applySorting(files, dirs, pattern, searchPath, sorting)
    sorting = sorting or "nameasc"

    if sorting == "nameasc" then
        sortNames(files, false)
        sortNames(dirs, false)
        return
    end

    if sorting == "namedesc" then
        sortNames(files, true)
        sortNames(dirs, true)
        return
    end

    if sorting == "sizeasc" or sorting == "sizedesc" then
        local descending = sorting == "sizedesc"

        sortByNumber(files, function(name)
            local slash = 0

            for i = #pattern, 1, -1 do
                if sub(pattern, i, i) == "/" then
                    slash = i
                    break
                end
            end

            local directory = slash > 0 and sub(pattern, 1, slash) or ""

            return file.Size(
                directory .. name,
                searchPath
            )
        end, descending)

        sortNames(dirs, descending)
        return
    end

    if sorting == "dateasc" or sorting == "datedesc" then
        local descending = sorting == "datedesc"

        sortByNumber(files, function(name)
            local slash = 0

            for i = #pattern, 1, -1 do
                if sub(pattern, i, i) == "/" then
                    slash = i
                    break
                end
            end

            local directory = slash > 0 and sub(pattern, 1, slash) or ""

            return file.Time(
                directory .. name,
                searchPath
            )
        end, descending)

        sortNames(dirs, descending)
        return
    end

    sortNames(files, false)
    sortNames(dirs, false)
end
-- helpers ended, begin files

function file.ExistsInLua( filepath )
    if !filepath or filepath == "" then
        return false
    end

    local name    = string.GetFileFromFilename( filepath )
    local results = file.FindInLua( filepath )

    if !results then return false end

    for _, found in pairs( results ) do
        if found == name then
            return true
        end
    end

    return false
end

function file.Exists(name, path)
    if path == nil then
        return oldExists(name, false)
    end

    if type(path) == "boolean" then
        return oldExists(name, path)
    end

    local kind, base, translated = translate(name, path)

    if isLuaPath(kind) then
        return file.ExistsInLua(name)
    end

    return oldExists(translated, base)
end

function file.Read(name, path)
    if path == nil then
        return oldRead(name, false)
    end

    if type(path) == "boolean" then
        return oldRead(name, path)
    end

    local kind, base, translated = translate(name, path)

    if isLuaPath(kind) then
        return readLua(name)
    end

    return oldRead(translated, base)
end

function file.IsDir(name, path)
    if path == nil then
        return oldIsDir(name, false)
    end

    if type(path) == "boolean" then
        return oldIsDir(name, path)
    end

    local kind, base, translated = translate(name, path)

    if isLuaPath(kind) then
        -- FindInLua cannot reliably report that an arbitrary search-path directory exists.
        return false
    end

    return oldIsDir(translated, base)
end

function file.Size(name, path)
    if path == nil then
        return oldSize(name, false)
    end

    if type(path) == "boolean" then
        return oldSize(name, path)
    end

    local kind, base, translated = translate(name, path)

    if isLuaPath(kind) then
        -- This only covers the physical base lua/ directory.
        return oldSize("lua/" .. name, true)
    end

    return oldSize(translated, base)
end

function file.Time(name, path)
    if path == nil then
        return oldTime(name, false)
    end

    if type(path) == "boolean" then
        return oldTime(name, path)
    end

    local kind, base, translated = translate(name, path)

    if isLuaPath(kind) then
        return oldTime("lua/" .. name, true)
    end

    return oldTime(translated, base)
end

function file.Find(pattern, path, sorting)
    if type(path) == "boolean" then
        return oldFind(pattern, path)
    end

    if path == nil then
        return oldFind(pattern, false)
    end

    local kind, base, translated = translate(pattern, path)

    if isLuaPath(kind) then
        local files, dirs = findLua(pattern)

        applySorting(
            files,
            dirs,
            pattern,
            path,
            sorting
        )

        return files, dirs
    end

    local mixed = oldFind(translated, base) or {}

    local files = {}
    local dirs  = {}

    local slash = 0

    for i = #translated, 1, -1 do
        if sub(translated, i, i) == "/" then
            slash = i
            break
        end
    end

    local directory =
        slash > 0 and sub(translated, 1, slash) or ""

    for _, name in ipairs(mixed) do
        if oldIsDir(directory .. name, base) then
            dirs[#dirs + 1] = name
        else
            files[#files + 1] = name
        end
    end

    applySorting(
        files,
        dirs,
        pattern,
        path,
        sorting
    )

    return files, dirs
end

-- gmod 12-only API, but extended to accept string search paths.
function file.FindDir(pattern, path)

    if type(path) == "boolean" then
        return oldFindDir(pattern, path)
    end

    if path == nil then
        return oldFindDir(pattern, false)
    end

    local kind, base, translated = translate(pattern, path)

    if isLuaPath(kind) then
        return {}
    end

    local mixed = oldFind(translated, base) or {}

    local slash = 0

    for i = #translated, 1, -1 do
        if sub(translated, i, i) == "/" then
            slash = i
            break
        end
    end

    local directory =
        slash > 0 and sub(translated, 1, slash) or ""

    local dirs = {}

    for _, name in ipairs(mixed) do
        if oldIsDir(directory .. name, base) then
            dirs[#dirs + 1] = name
        end
    end

    sortNames(dirs, false)

    return dirs
end