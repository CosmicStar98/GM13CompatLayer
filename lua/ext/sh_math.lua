local math = math

math.deg = math.Rad2Deg
math.rad = math.Deg2Rad

-- A variable containing the mathematical constant tau, which is equivalent to 2*pi. (6.28318530718)
math.tau = 2 * math.pi

-- Cubic Hermite spline algorithm.
function math.CHSpline( frac, p0, m0, p1, m1 )
    if ( frac >= 1 ) then return p1 end
    if ( frac <= 0 ) then return p0 end

    local t2 = frac * frac
    local t3 = frac * t2

    return p0 * ( 2 * t3 - 3 * t2 + 1 ) +
        m0 * ( t3 - 2 * t2 + frac ) +
        p1 * ( -2 * t3 + 3 * t2 ) +
        m1 * ( t3 - t2 )
end

-- Lerp point between 4 control points with cubic bezier.
function math.CubicBezier( frac, p0, p1, p2, p3 )
    local frac2 = frac * frac
    local inv = 1 - frac
    local inv2 = inv * inv

    return inv2 * inv * p0 + 3 * inv2 * frac * p1 + 3 * inv * frac2 * p2 + frac2 * frac * p3
end

-- Lerp point between 3 control points with quadratic bezier.
function math.QuadraticBezier( frac, p0, p1, p2 )
    local frac2 = frac * frac
    local inv = 1 - frac
    local inv2 = inv * inv

    return inv2 * p0 + 2 * inv * frac * p1 + frac2 * p2
end

-- Simple function that calculates factorial of a whole number.
--  https://en.wikipedia.org/wiki/Factorial
function math.Factorial( num )
    if ( num < 0 ) then
        return nil
    elseif ( num < 2 ) then
        return 1
    end

    local res = 1
    for i = 2, num do
        res = res * i
    end

    return res
end

-- Returns the squared difference between two points in 2D space.
--  This is computationally faster than math.Distance.
function math.DistanceSqr( x1, y1, x2, y2 )
    local xd = x2 - x1
    local yd = y2 - y1

    return xd * xd + yd * yd
end

-- Checks if two floating point numbers are nearly equal.
--  This is useful to mitigate accuracy issues in floating point numbers.
--  https://en.wikipedia.org/wiki/Floating-point_arithmetic#Accuracy_problems
function math.IsNearlyEqual( a, b, tolerance )
    if ( tolerance == nil ) then
        tolerance = 1e-8
    end

    return math.abs( a - b ) <= tolerance
end

-- Remaps the value from one range to another.
function math.Remap( value, inMin, inMax, outMin, outMax )
    return outMin + ( ( ( value - inMin ) / ( inMax - inMin ) ) * ( outMax - outMin ) )
end

-- Returns the mathematical negative/positive sign of the input number.
function math.Sign( num )
    return ( num > 0 and 1 ) or ( num < 0 and -1 ) or 0
end

-- Snaps the provided number to the nearest multiple.
function math.SnapTo( num, multiple )
    return math.floor( num / multiple + 0.5 ) * multiple
end

-- Trim unwanted decimal places.
function math.Truncate( num, idp )
    local mult = 10 ^ ( idp or 0 )
    return ( num < 0 and math.ceil or math.floor )( num * mult ) / mult
end