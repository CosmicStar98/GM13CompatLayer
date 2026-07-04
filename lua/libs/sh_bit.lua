--[[

DESCRIPTION

  This library implements bitwise operations entirely in Lua.
  This module is typically intended if for some reasons you don't want
  to or cannot  install a popular C based bit library like BitOp 'bit' [1]
  (which comes pre-installed with LuaJIT) or 'bit32' (which comes
  pre-installed with Lua 5.2) but want a similar interface.
  
  This modules represents bit arrays as non-negative Lua numbers. [1]
  It can represent 32-bit bit arrays when Lua is compiled
  with lua_Number as double-precision IEEE 754 floating point.

  The module is nearly the most efficient it can be but may be a few times
  slower than the C based bit libraries and is orders or magnitude
  slower than LuaJIT bit operations, which compile to native code.  Therefore,
  this library is inferior in performane to the other modules.

  The `xor` function in this module is based partly on Roberto Ierusalimschy's
  post in http://lua-users.org/lists/lua-l/2002-09/msg00134.html .

STATUS

  WARNING: Not all corner cases have been tested and documented.
  Some attempt was made to make these similar to the Lua 5.2 [2]
  and LuaJit BitOp [3] libraries, but this is not fully tested and there
  are currently some differences.  Addressing these differences may
  be improved in the future but it is not yet fully determined how to
  resolve these differences.
  
  The BIT.bit32 library passes the Lua 5.2 test suite (bitwise.lua)
  http://www.lua.org/tests/5.2/ .  The BIT.bit library passes the LuaBitOp
  test suite (bittest.lua).  However, these have not been tested on
  platforms with Lua compiled with 32-bit integer numbers.

REFERENCES

  [1] http://lua-users.org/wiki/FloatingPoint
  [2] http://www.lua.org/manual/5.2/
  [3] http://bitop.luajit.org/

LICENSE

  (c) 2008-2011 David Manura.  Licensed under the same terms as Lua (MIT).

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in
  all copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
  THE SOFTWARE.
  (end license)

--]]

bit = {}


local floor = math.floor

local MOD = 2^32
local MODM = MOD-1

local function memoize(f)
    local mt = {}
    local t = setmetatable({}, mt)

    function mt:__index(k)
        local v = f(k); t[k] = v
        return v
    end

    return t
end

local function make_bitop_uncached(t, m)
    local function bitop(a, b)
        local res,p = 0,1

        while a ~= 0 and b ~= 0 do
            local am, bm = a%m, b%m
            res = res + t[am][bm]*p
            a = (a - am) / m
            b = (b - bm) / m
            p = p*m
        end

        res = res + (a+b)*p

        return res
    end

    return bitop
end

local function make_bitop(t)
    local op1 = make_bitop_uncached(t,2^1)
    local op2 = memoize( function(a)
        return memoize(function(b)
            return op1(a, b)
        end)
    end )

    return make_bitop_uncached( op2, 2^(t.n or 1) )
end

local b_bxor = make_bitop( {[0]={[0]=0,[1]=1},[1]={[0]=1,[1]=0}, n=4} )
local function b_bnot(a) return MODM - a end
local function b_band(a, b) return ((a+b) - b_bxor(a,b))/2 end
local function b_bor(a, b) return MODM - b_band(MODM - a, MODM - b) end

local b_lshift, b_rshift -- forward declare

local function b_rshift( a, disp )
    if disp < 0 then return b_lshift(a,-disp) end
    return floor(a % 2^32 / 2^disp)
end

local function b_lshift( a, disp )
    if disp < 0 then return b_rshift(a,-disp) end 
    return (a * 2^disp) % 2^32
end

local function b_rrotate( x, disp )
    disp = disp % 32

    local low = b_band(x, 2^disp-1)

    return b_rshift(x, disp) + b_lshift(low, 32-disp)
end

local function b_lrotate( x, disp )
    return b_rrotate(x, -disp)
end

function bit.btest( x, y )
    return b_band(x, y) ~= 0
end

function bit.extract( n, field, width )
    width = width or 1
    return b_band( b_rshift(n, field), 2^width-1 )
end

function bit.replace( n, v, field, width )
    width = width or 1
    local mask1 = 2^width-1

    v = b_band(v, mask1) -- required by spec?
    local mask = b_bnot( b_lshift(mask1, field) )

    return b_band(n, mask) + b_lshift(v, field)
end

function bit.tobit(x)
    x = x % MOD
    if x >= 0x80000000 then x = x - MOD end

    return x
end
local bit_tobit = bit.tobit

function bit.tohex( x, n )
    n = n or 8
    local up

    if n <= 0 then
        if n == 0 then return '' end
        up = true
        n = -n
    end

    x = b_band( x % MOD, 16^n-1 )

    return ( '%0' .. n .. (up and 'X' or 'x') ):format(x)
end

function bit.bnot(x)
    return bit_tobit( b_bnot(x % MOD) )
end

function bit.bor( a, b, c, ... )
    if c then
        return bit.bor( bit.bor(a, b), c, ... )
    elseif b then
        return bit_tobit( b_bor(a % MOD, b % MOD) )
    else
        return bit_tobit(a)
    end
end

function bit.band( a, b, c, ... )
    if c then
        return bit.band( bit.band(a, b), c, ... )
    elseif b then
        return bit_tobit( b_band(a % MOD, b % MOD) )
    else
        return bit_tobit(a)
    end
end

function bit.bxor( a, b, c, ... )
    if c then
        return bit.bxor( bit.bxor(a, b), c, ... )
    elseif b then
        return bit_tobit( b_bxor(a % MOD, b % MOD) )
    else
        return bit_tobit(a)
    end
end

function bit.lshift( x, n )
    return bit_tobit( b_lshift(x % MOD, n % 32) )
end

function bit.rshift( x, n )
    return bit_tobit( b_rshift(x % MOD, n % 32) )
end

function bit.arshift( x, n )
    x = x % MOD
    n = n % 32

    local z = b_rshift(x, n)
    if x >= 0x80000000 then z = z + b_lshift( 2^n-1, 32-n ) end

    return bit_tobit(z)
end

function bit.rol( x, n )
    return bit_tobit( b_lrotate(x % MOD, n % 32) )
end

function bit.ror( x, n )
    return bit_tobit( b_rrotate(x % MOD, n % 32) )
end

function bit.bswap( x )
    x = x % MOD

    local a = b_band(x, 0xff); x = b_rshift(x, 8)
    local b = b_band(x, 0xff); x = b_rshift(x, 8)
    local c = b_band(x, 0xff); x = b_rshift(x, 8)
    local d = b_band(x, 0xff)

    return bit_tobit( b_lshift(b_lshift(b_lshift(a, 8) + b, 8) + c, 8) + d )
end