-- GMod 13-style net API transported through GMod 12 datastream.
--
-- Wire format:
--   { id = <number> or name = <string>, bits = <number>, data = { {t=..., v=...}, ... } }
--
-- The actual values are carried in data. The bit count is metadata used by
-- BytesLeft/BytesWritten compatibility functions.

local netStringPool = CreateConVar(
    "sv_net_stringpool",
    "1",
    { FCVAR_REPLICATED, FCVAR_ARCHIVE },
    "Use numeric IDs for net message names."
)

module("net", package.seeall)
net = net or {}
net.Receivers = net.Receivers or {}
net.WriteVars = net.WriteVars or {}
net.ReadVars  = net.ReadVars or {}

local TRANSPORT = "__net"
local ADD_STRING = "__net_addstring"
local SYNC_STRINGS = "__net_syncstrings"

local _nameToID = {}
local _idToName = {}
local _nextID = 1

-- ---------------------------------------------------------------------------
-- Network string registry
-- ---------------------------------------------------------------------------

local function _validStringName(name, fn)
    if type(name) ~= "string" then
        error("[net] " .. fn .. ": expected string name, got " .. type(name), 3)
    end
    if name == "" then
        error("[net] " .. fn .. ": network string cannot be empty", 3)
    end
end

function util.AddNetworkString(name)
    _validStringName(name, "AddNetworkString")

    if !netStringPool:GetBool() then
        return 0
    end

    if _nameToID[name] then
        return _nameToID[name]
    end

    local id = _nextID
    _nextID = _nextID + 1

    _nameToID[name] = id
    _idToName[id] = name

    if SERVER then
        datastream.StreamToClients(
            player.GetAll(),
            ADD_STRING,
            { id = id, name = name }
        )
    end

    return id
end

if CLIENT then
    datastream.Hook(ADD_STRING, function(handler, id, encoded, decoded)
        if !istable(decoded) then return end
        if type(decoded.name) ~= "string" or type(decoded.id) ~= "number" then return end

        _nameToID[decoded.name] = decoded.id
        _idToName[decoded.id] = decoded.name
    end)

    datastream.Hook(SYNC_STRINGS, function(handler, id, encoded, decoded)
        if !istable(decoded) then return end

        for name, nid in pairs(decoded) do
            if type(name) == "string" and type(nid) == "number" then
                _nameToID[name] = nid
                _idToName[nid] = name
            end
        end
    end)
end

if SERVER then
    hook.Add("PlayerInitialSpawn", "net_shim_syncstrings", function(ply)
        if next(_nameToID) then
            datastream.StreamToClients(ply, SYNC_STRINGS, _nameToID)
        end
    end)
end

-- ---------------------------------------------------------------------------
-- Outgoing state
-- ---------------------------------------------------------------------------

-- IMPORTANT:
-- _msg is one temporary message currently being built by net.Start().
-- It lives only inside this Lua module chunk (upvalue/local), not globally.
--
-- Example lifecycle:
--   net.Start("foo")       -> _msg = { ... }
--   net.WriteString("bar")  -> _msg.data gets an entry
--   net.Send(ply)           -> serialize _msg, then _msg = nil
--   net.Abort()             -> _msg = nil
--
-- A single execution context can therefore have only one message in flight.
local _msg = nil

local function _checkWrite(fn)
    if !_msg then
        error("[net] " .. fn .. " called without net.Start", 2)
    end
end

local function _append(tag, value, bits)
    _checkWrite("Write")

    local data = _msg.data
    data[#data + 1] = { t = tag, v = value }

    if bits then
        _msg.bits = _msg.bits + bits
    end
end

local function _makePayload()
    _checkWrite("Send")

    local payload = {
        bits = _msg.bits,
        data = _msg.data
    }

    if netStringPool:GetBool() then
        payload.id = _msg.id
    else
        payload.name = _msg.name
    end

    return _msg.name, payload
end

-- ---------------------------------------------------------------------------
-- net.Start / net.Abort
-- ---------------------------------------------------------------------------

function net.Start(name, unreliable)
    _validStringName(name, "Start")

    if netStringPool:GetBool() then
        local id = _nameToID[name]
        if !id then
            ErrorNoHalt(
                "[net] net.Start: '" .. name .. "' was never passed to util.AddNetworkString\n"
            )
            _msg = nil
            return false
        end

        _msg = {
            name = name,
            id = id,
            data = {},
            bits = 0,
            unreliable = unreliable and true or false
        }
    else
        _msg = {
            name = name,
            data = {},
            bits = 0,
            unreliable = unreliable and true or false
        }
    end

    return true
end

function net.Abort()
    _msg = nil
end

-- ---------------------------------------------------------------------------
-- Write functions
-- ---------------------------------------------------------------------------

function net.WriteString(str)
    if type(str) ~= "string" then
        error("[net] WriteString: expected string, got " .. type(str), 2)
    end
    _append("s", str, (#str + 1) * 8)
end

function net.WriteFloat(value)
    if type(value) ~= "number" then
        error("[net] WriteFloat: expected number, got " .. type(value), 2)
    end
    _append("f", value, 32)
end

function net.WriteDouble(value)
    if type(value) ~= "number" then
        error("[net] WriteDouble: expected number, got " .. type(value), 2)
    end
    _append("d", value, 64)
end

function net.WriteInt(value, bitCount)
    if type(value) ~= "number" then
        error("[net] WriteInt: expected number, got " .. type(value), 2)
    end
    if type(bitCount) ~= "number" then
        error("[net] WriteInt: bit count must be a number", 2)
    end
    _append("i", value, bitCount)
end

function net.WriteUInt(value, bitCount)
    if type(value) ~= "number" then
        error("[net] WriteUInt: expected number, got " .. type(value), 2)
    end
    if type(bitCount) ~= "number" then
        error("[net] WriteUInt: bit count must be a number", 2)
    end
    _append("u", value, bitCount)
end

function net.WriteBit(value)
    _append("b", value and 1 or 0, 1)
end
net.WriteBool = net.WriteBit

function net.WriteAngle(a)
    if !a then
        error("[net] WriteAngle: expected Angle", 2)
    end
    _append("a", Angle(a.p, a.y, a.r), 96)
end

function net.WriteVector(v)
    if !v then
        error("[net] WriteVector: expected Vector", 2)
    end
    _append("v", Vector(v.x, v.y, v.z), 96)
end

function net.WriteNormal(v)
    if !v then
        error("[net] WriteNormal: expected Vector", 2)
    end
    _append("n", Vector(v.x, v.y, v.z), 96)
end

function net.WriteColor(c, hasAlpha)
    if !c then
        error("[net] WriteColor: expected Color", 2)
    end

    hasAlpha = hasAlpha == nil and true or hasAlpha

    _append("c", {
        r = c.r,
        g = c.g,
        b = c.b,
        a = hasAlpha and c.a or 255
    }, hasAlpha and 32 or 24)
end

function net.WriteEntity(ent)
    local index = 0
    if ent and IsValidEntity and IsValidEntity(ent) then
        index = ent:EntIndex()
    end
    _append("e", index, 16)
end

function net.WritePlayer(ply)
    local index = 0
    if ply and IsValidEntity and IsValidEntity(ply) then
        index = ply:EntIndex()
    end
    _append("p", index, 16)
end

function net.WriteTable(tbl, sequential)
    if type(tbl) ~= "table" then
        error("[net] WriteTable: expected table, got " .. type(tbl), 2)
    end
    -- Datastream/glon handles table serialization.
    _append("t", tbl, 0)
end

function net.WriteData(data, length)
    if type(data) ~= "string" then
        error("[net] WriteData: expected string, got " .. type(data), 2)
    end

    length = length or #data
    if length < 0 then length = 0 end
    if length > #data then length = #data end

    local value = string.sub(data, 1, length)
    _append("raw", value, #value * 8)
end

function net.WriteUInt64(value)
    _append("u64", tostring(value), 64)
end

function net.WriteType(value)
    local t = type(value)

    if t == "string" then
        _append("s", value, (#value + 1) * 8)
    elseif t == "number" then
        _append("d", value, 64)
    elseif t == "boolean" then
        _append("b", value and 1 or 0, 1)
    elseif t == "table" then
        _append("t", value, 0)
    elseif t == "Vector" then
        _append("v", Vector(value.x, value.y, value.z), 96)
    elseif t == "Angle" then
        _append("a", Angle(value.p, value.y, value.r), 96)
    elseif t == "nil" then
        _append("nil", false, 0)
    else
        ErrorNoHalt("[net] WriteType: unsupported type '" .. t .. "'\n")
        _append("nil", false, 0)
    end
end

function net.WriteMatrix(matrix)
    ErrorNoHalt("[net] WriteMatrix is not supported by the GMod 12 shim\n")
end

-- ---------------------------------------------------------------------------
-- Incoming read state
-- ---------------------------------------------------------------------------

local _readBuf = nil
local _readPos = 1
local _totalBits = 0
local _readBits = 0

local function _read(fn)
    if !_readBuf then
        error("[net] " .. fn .. " called outside of a net.Receive callback", 2)
    end

    local entry = _readBuf[_readPos]
    if !entry then
        error("[net] " .. fn .. ": read past end of message", 2)
    end

    _readPos = _readPos + 1
    return entry
end

local function _beginRead(payload)
    if !istable(payload) then
        error("[net] invalid payload: expected table", 0)
    end

    if !istable(payload.data) then
        error("[net] invalid payload: missing data table", 0)
    end

    _readBuf = payload.data
    _readPos = 1
    _totalBits = tonumber(payload.bits) or 0
    _readBits = 0
end

local function _endRead()
    _readBuf = nil
    _readPos = 1
    _totalBits = 0
    _readBits = 0
end

local function _resolvePayloadName(payload)
    if !istable(payload) then
        return nil
    end

    if payload.id ~= nil then
        local name = _idToName[payload.id]
        if type(name) == "string" then
            return name
        end

        ErrorNoHalt(
            "[net] Received unknown net message ID " .. tostring(payload.id) .. "\n"
        )
        return nil
    end

    if type(payload.name) == "string" then
        return payload.name
    end

    ErrorNoHalt("[net] Received net payload without a message name or ID\n")
    return nil
end

local function _dispatch(payload, ply)
    local name = _resolvePayloadName(payload)
    if !name then return end

    local callback = net.Receivers[string.lower(name)]
    if !callback then return end

    local ok, err

    _beginRead(payload)
    ok, err = pcall(callback, 0, ply)
    _endRead()

    if !ok then
        ErrorNoHalt(
            "[net] Error in receiver '" .. name .. "': " .. tostring(err) .. "\n"
        )
    end
end

-- ---------------------------------------------------------------------------
-- Read functions
-- ---------------------------------------------------------------------------

function net.ReadBool()
    local e = _read("ReadBool")
    _readBits = _readBits + 1
    return e.v == 1 or e.v == true
end

function net.ReadBit()
    local e = _read("ReadBit")
    _readBits = _readBits + 1
    return e.v
end

function net.ReadFloat()
    local e = _read("ReadFloat")
    _readBits = _readBits + 32
    return e.v
end

function net.ReadDouble()
    local e = _read("ReadDouble")
    _readBits = _readBits + 64
    return e.v
end

function net.ReadInt(bitCount)
    local e = _read("ReadInt")
    _readBits = _readBits + (tonumber(bitCount) or 0)
    return e.v
end

function net.ReadUInt(bitCount)
    local e = _read("ReadUInt")
    _readBits = _readBits + (tonumber(bitCount) or 0)
    return e.v
end

function net.ReadAngle()
    local e = _read("ReadAngle")
    _readBits = _readBits + 96
    return e.v
end

function net.ReadVector()
    local e = _read("ReadVector")
    _readBits = _readBits + 96
    return e.v
end

function net.ReadNormal()
    local e = _read("ReadNormal")
    _readBits = _readBits + 96
    return e.v
end

function net.ReadEntity()
    local e = _read("ReadEntity")
    _readBits = _readBits + 16
    return Entity(tonumber(e.v) or 0)
end

function net.ReadPlayer()
    local e = _read("ReadPlayer")
    _readBits = _readBits + 16
    return Entity(tonumber(e.v) or 0)
end

function net.ReadUInt64()
    local e = _read("ReadUInt64")
    _readBits = _readBits + 64
    return e.v
end

function net.ReadData(length)
    local e = _read("ReadData")
    length = tonumber(length) or 0
    _readBits = _readBits + length * 8
    return string.sub(e.v or "", 1, length)
end

function net.ReadTable(sequential)
    return _read("ReadTable").v
end

function net.ReadColor(hasAlpha)
    hasAlpha = hasAlpha == nil and true or hasAlpha

    local e = _read("ReadColor")
    _readBits = _readBits + (hasAlpha and 32 or 24)

    local v = e.v or {}
    return Color(v.r or 0, v.g or 0, v.b or 0, hasAlpha and (v.a or 255) or 255)
end

function net.ReadString()
    local e = _read("ReadString")
    local value = e.v

    if type(value) ~= "string" then
        error("[net] ReadString: message entry was not a string", 2)
    end

    _readBits = _readBits + (#value + 1) * 8
    return value
end

function net.ReadType(typeID)
    local entry = _read("ReadType")
    local t = entry.t

    if t == "nil" then
        return nil
    elseif t == "s" or t == "raw" or t == "u64" then
        return entry.v
    elseif t == "f" or t == "d" or t == "i" or t == "u" then
        return entry.v
    elseif t == "b" then
        return entry.v == 1 or entry.v == true
    elseif t == "t" then
        return entry.v
    elseif t == "v" or t == "n" then
        return entry.v
    elseif t == "a" then
        return entry.v
    elseif t == "c" then
        local c = entry.v or {}
        return Color(c.r or 0, c.g or 0, c.b or 0, c.a or 255)
    elseif t == "e" or t == "p" then
        return Entity(tonumber(entry.v) or 0)
    end

    return entry.v
end

function net.ReadMatrix()
    ErrorNoHalt("[net] ReadMatrix is not supported by the GMod 12 shim\n")
    return nil
end

-- ---------------------------------------------------------------------------
-- Size queries
-- ---------------------------------------------------------------------------

function net.BytesWritten()
    if !_msg then return 0, 0 end
    return math.ceil(_msg.bits / 8), _msg.bits
end

function net.BytesLeft()
    local bitsLeft = _totalBits - _readBits
    if bitsLeft < 0 then bitsLeft = 0 end
    return math.ceil(bitsLeft / 8), bitsLeft
end

-- ---------------------------------------------------------------------------
-- Receive / datastream hooks
-- ---------------------------------------------------------------------------

local _hooksInstalled = false

local function _installTransportHooks()
    if _hooksInstalled then return end
    _hooksInstalled = true

    if SERVER then
        datastream.Hook(TRANSPORT, function(pl, handler, id, encoded, decoded)
            _dispatch(decoded, pl)
        end)

        hook.Add("AcceptStream", "net_shim", function(pl, handler, id)
            if handler == TRANSPORT or handler == ADD_STRING or handler == SYNC_STRINGS then
                return true
            end
        end)
    else
        datastream.Hook(TRANSPORT, function(handler, id, encoded, decoded)
            _dispatch(decoded, nil)
        end)
    end
end

function net.Receive(name, callback)
    _validStringName(name, "Receive")

    if type(callback) ~= "function" then
        error("[net] Receive: callback must be a function", 2)
    end

    net.Receivers[string.lower(name)] = callback
    _installTransportHooks()
end

-- Install server-side transport hooks even before the first receiver is added,
-- so client messages cannot race registration of the first net.Receive call.
if SERVER then
    _installTransportHooks()
end

-- ---------------------------------------------------------------------------
-- Send functions — server
-- ---------------------------------------------------------------------------

if SERVER then

    local function _sendToClients(target)
        local name, payload = _makePayload()
        _msg = nil
        datastream.StreamToClients(target, TRANSPORT, payload)
    end

    function net.Send(ply)
        _sendToClients(ply)
    end

    function net.Broadcast()
        _sendToClients(player.GetAll())
    end

    function net.SendOmit(ply)
        _checkWrite("SendOmit")

        local filter = RecipientFilter()
        filter:AddAllPlayers()

        if istable(ply) then
            for _, p in ipairs(ply) do
                filter:RemovePlayer(p)
            end
        else
            filter:RemovePlayer(ply)
        end

        _sendToClients(filter)
    end

    function net.SendPVS(pos)
        _checkWrite("SendPVS")

        local filter = RecipientFilter()
        filter:AddPVS(pos)
        _sendToClients(filter)
    end

    function net.SendPAS(pos)
        -- GMod 12 does not expose AddPAS here; retain the old conservative PVS
        -- approximation rather than silently broadcasting.
        _checkWrite("SendPAS")

        local filter = RecipientFilter()
        filter:AddPVS(pos)
        _sendToClients(filter)
    end
end

-- ---------------------------------------------------------------------------
-- Send functions — client
-- ---------------------------------------------------------------------------

if CLIENT then
    function net.SendToServer()
        local _, payload = _makePayload()
        _msg = nil
        datastream.StreamToServer(TRANSPORT, payload)
    end
end

return net
