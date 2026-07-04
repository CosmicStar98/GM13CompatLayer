--[[

 JSON Encoder and Parser for Lua 5.1

 Copyright © 2007 Shaun Brown (http://www.chipmunkav.com).
 All Rights Reserved.

 Permission is hereby granted, free of charge, to any person 
 obtaining a copy of this software to deal in the Software without 
 restriction, including without limitation the rights to use, 
 copy, modify, merge, publish, distribute, sublicense, and/or 
 sell copies of the Software, and to permit persons to whom the 
 Software is furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be 
 included in all copies or substantial portions of the Software.
 If you find this software useful please give www.chipmunkav.com a mention.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, 
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES 
 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR 
 ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF 
 CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN 
 CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

    MODIFIED BY COSMIC (cleaner naming conventions)

 Usage:

 -- Lua script:
 local t = { 
    ["name1"] = "value1",
    ["name2"] = {1, false, true, 23.54, "a \021 string"},
    name3 = json.Null() 
 }

 local json = json.Encode(t)
 print (json) 
 --> {"name1":"value1","name3":null,"name2":[1,false,true,23.54,"a \u0015 string"]}

 local t = json.Decode(json)
 print(t.name2[4])
 --> 23.54

 Notes:
 1) Encodable Lua types: string, number, boolean, table, nil
 2) Use json.Null() to insert a null value into a json object
 3) All control chars are encoded to \uXXXX format eg "\021" encodes to "\u0015"
 4) All json \uXXXX chars are decoded to chars (0-255 byte range only)
 5) Json single line // and /* */ block comments are discarded during decoding
 6) Numerically indexed Lua arrays are encoded to json Lists eg [1,2,3]
 7) Lua dictionary tables are converted to json objects eg {"one":1,"two":2}
 8) json nulls are decoded to Lua nil and treated by Lua in the normal way

--]]

local string = string
local math = math
local table = table
local error = error
local tonumber = tonumber
local tostring = tostring
local type = type
local setmetatable = setmetatable
local pairs = pairs
local ipairs = ipairs
local assert = assert

json = {}

local Null -- forward declare


local stringBuilder = {
    buffer = {}
}

function stringBuilder:New()
    local o = {}
    setmetatable(o, self)

    self.__index = self
    o.buffer = {}

    return o
end

function stringBuilder:Append(s)
    self.buffer[#self.buffer+1] = s
end

function stringBuilder:ToString()
    return table.concat(self.buffer)
end

local jsonWriter = {
    backslashes = {
        ['\b'] = "\\b",
        ['\t'] = "\\t",
        ['\n'] = "\\n",
        ['\f'] = "\\f",
        ['\r'] = "\\r",
        ['"']  = "\\\"",
        ['\\'] = "\\\\",
        ['/']  = "\\/"
    }
}

function jsonWriter:New()
    local o = {}
    o.writer = stringBuilder:New()

    setmetatable(o, self)
    self.__index = self

    return o
end

function jsonWriter:Append(s)
    self.writer:Append(s)
end

function jsonWriter:ToString()
    return self.writer:ToString()
end

function jsonWriter:Write(o)
    local t = type(o)
    if t == "nil" then
        self:WriteNil()
    elseif t == "boolean" then
        self:WriteString(o)
    elseif t == "number" then
        self:WriteString(o)
    elseif t == "string" then
        self:ParseString(o)
    elseif t == "table" or t == "vector" then
        self:WriteTable(o)
    elseif t == "function" then
        self:WriteFunction(o)
    elseif t == "thread" then
        self:WriteError(o)
    elseif t == "userdata" then
        self:WriteError(o)
    end
end

function jsonWriter:WriteNil()
    self:Append("null")
end

function jsonWriter:WriteString(o)
    self:Append(tostring(o))
end

function jsonWriter:ParseString(s)
    self:Append('"')
    self:Append( string.gsub(s, "[%z%c\\\"/]", function(n)
        local c = self.backslashes[n]
        if c then return c end

        return string.format("\\u%.4X", string.byte(n))
    end) )

    self:Append('"')
end

function jsonWriter:IsArray(t)
    local count = 0
    local isindex = function(k) 
        if type(k) == "number" and k > 0 then
            if math.floor(k) == k then
                return true
            end
        end

        return false
    end

    for k,v in pairs(t) do
        if !isindex(k) then
            return false, '{', '}'
        else
            count = math.max(count, k)
        end
    end

    return true, '[', ']', count
end

function jsonWriter:WriteTable(t)
    local ba, st, et, n = self:IsArray(t)
    self:Append(st)

    if ba then
        for i = 1, n do
            self:Write(t[i])
            if i < n then
                self:Append(',')
            end
        end
    else
        local first = true;
        for k, v in pairs(t) do
            if !first then
                self:Append(',')
            end

            first = false;
            self:ParseString(k)
            self:Append(':')
            self:Write(v)
        end
    end

    self:Append(et)
end

function jsonWriter:WriteError(o)
    error( string.format("Encoding of %s unsupported", tostring(o)) )
end

function jsonWriter:WriteFunction(o)
    if o == Null then 
        self:WriteNil()
    else
        self:WriteError(o)
    end
end

local stringReader = {
    s = "",
    i = 0
}

function stringReader:New(s)
    local o = {}

    setmetatable(o, self)
    self.__index = self
    o.s = s or o.s

    return o
end

function stringReader:Peek()
    local i = self.i + 1

    if i <= #self.s then
        return string.sub(self.s, i, i)
    end

    return nil
end

function stringReader:Next()
    self.i = self.i+1

    if self.i <= #self.s then
        return string.sub(self.s, self.i, self.i)
    end

    return nil
end

function stringReader:All()
    return self.s
end

local jsonReader = {
    escapes = {
        ['t'] = '\t',
        ['n'] = '\n',
        ['f'] = '\f',
        ['r'] = '\r',
        ['b'] = '\b',
    }
}

function jsonReader:New(s)
    local o = {}

    o.reader = stringReader:New(s)
    setmetatable(o, self)
    self.__index = self

    return o;
end

function jsonReader:Read()
    self:SkipWhiteSpace()
    local peek = self:Peek()

    if peek == nil then
        error( string.format("Nil string: '%s'", self:All()) )
    elseif peek == '{' then
        return self:ReadObject()
    elseif peek == '[' then
        return self:ReadArray()
    elseif peek == '"' then
        return self:ReadString()
    elseif string.find(peek, "[%+%-%d]") then
        return self:ReadNumber()
    elseif peek == 't' then
        return self:ReadTrue()
    elseif peek == 'f' then
        return self:ReadFalse()
    elseif peek == 'n' then
        return self:ReadNull()
    elseif peek == '/' then
        self:ReadComment()
        return self:Read()
    else
        error( string.format("Invalid input: '%s'", self:All()) )
    end
end

function jsonReader:ReadTrue()
    self:TestReservedWord{'t','r','u','e'}
    return true
end

function jsonReader:ReadFalse()
    self:TestReservedWord{'f','a','l','s','e'}
    return false
end

function jsonReader:ReadNull()
    self:TestReservedWord{'n','u','l','l'}
    return nil
end

function jsonReader:TestReservedWord(t)
    for i, v in ipairs(t) do
        if self:Next() ~= v then
            error( string.format("Error reading '%s': %s", table.concat(t), self:All()) )
        end
    end
end

function jsonReader:ReadNumber()
    local result = self:Next()
    local peek = self:Peek()

    while peek ~= nil and string.find( peek, "[%+%-%d%.eE]") do
        result = result .. self:Next()
        peek = self:Peek()
    end

    result = tonumber(result)

    if result == nil then
        error( string.format("Invalid number: '%s'", result) )
    else return result end
end

function jsonReader:ReadString()
    local result = ""

    assert(self:Next() == '"')
    while self:Peek() ~= '"' do
        local ch = self:Next()

        if ch == '\\' then
            ch = self:Next()
            if self.escapes[ch] then
                ch = self.escapes[ch]
            end
        end

        result = result .. ch
    end

    assert(self:Next() == '"')
    local fromunicode = function(m)
        return string.char( tonumber(m, 16) )
    end

    return string.gsub( result, "u%x%x(%x%x)", fromunicode )
end

function jsonReader:ReadComment()
    assert(self:Next() == '/')
    local second = self:Next()

    if second == '/' then
        self:ReadSingleLineComment()
    elseif second == '*' then
        self:ReadBlockComment()
    else
        error( string.format("Invalid comment: %s", self:All()) )
    end
end

function jsonReader:ReadBlockComment()
    local done = false
    while !done do
        local ch = self:Next()
        if ch == '*' and self:Peek() == '/' then
            done = true
        end
        if !done and ch == '/' and
        self:Peek() == "*" then
            error( string.format("Invalid comment: %s, '/*' illegal.", self:All()) )
        end
    end

    self:Next()
end

function jsonReader:ReadSingleLineComment()
    local ch = self:Next()

    while ch ~= '\r' and ch ~= '\n' do
        ch = self:Next()
    end
end

function jsonReader:ReadArray()
    local result = {}
    assert(self:Next() == '[')
    local done = false

    if self:Peek() == ']' then done = true; end
    while !done do
        local item = self:Read()

        result[ #result + 1 ] = item
        self:SkipWhiteSpace()

        if self:Peek() == ']' then done = true end
        if !done then
            local ch = self:Next()
            if ch ~= ',' then
                error( string.format("Invalid array: '%s' due to: '%s'", self:All(), ch) )
            end
        end
    end

    assert(']' == self:Next())
    return result
end

function jsonReader:ReadObject()
    local result = {}
    assert(self:Next() == '{')

    local done = false
    local amt = 0

    if self:Peek() == '}' then done = true end
    while !done do
        local key = self:Read()
        if type(key) ~= "string" then
            error( string.format("Invalid non-string object key: %s", key) )
        end

        self:SkipWhiteSpace()

        local ch = self:Next()
        if ch ~= ':' then
            error( string.format("Invalid object: '%s' due to: '%s'", self:All(), ch) )
        end

        self:SkipWhiteSpace()

        local val = self:Read()
        result[key] = val
        amt = amt + 1

        self:SkipWhiteSpace()

        if self:Peek() == '}' then done = true end
        if !done then
            ch = self:Next()
            if ch ~= ',' then
                error( string.format("Invalid array: '%s' near: '%s'", self:All(), ch) )
            end
        end
    end

    assert(self:Next() == "}")
    if (amt == 2) then
        if (result.x and result.y) then
            result = greenshell.vector:new(result.x, result.y)
        end
    end

    return result
end

function jsonReader:SkipWhiteSpace()
    local p = self:Peek()
    while p ~= nil and string.find(p, "[%s/]") do
        if p == '/' then
            self:ReadComment()
        else self:Next() end

        p = self:Peek()
    end
end

function jsonReader:Peek()
    return self.reader:Peek()
end

function jsonReader:Next()
    return self.reader:Next()
end

function jsonReader:All()
    return self.reader:All()
end

function json.Encode(o)
    local writer = jsonWriter:New()
    writer:Write(o)

    return writer:ToString()
end

function json.Decode(s)
    local reader = jsonReader:New(s)

    return reader:Read()
end

Null = function()
    return Null
end

json.Null = Null