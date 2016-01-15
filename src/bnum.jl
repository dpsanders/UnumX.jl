export Bnum, Bbound

immutable Bnum
    num::BigFloat
    open::Bool
end

Bnum(x::Real,open::Bool) = Bnum(BigFloat(x),open)
Bnum(x::Real) = Bnum(x,false)

convert(::Type{Bnum},x::Bnum) = x
convert(::Type{Bnum},x::Real) = Bnum(x)


import Base: +, -

import Base.MPFR.to_mpfr

function +(x::Bnum, y::Bnum, r::RoundingMode)
    znum = BigFloat()
    inex = ccall((:mpfr_add,:libmpfr), Int32, (Ptr{BigFloat}, Ptr{BigFloat}, Ptr{BigFloat}, Int32), &znum, &x.num, &y.num, to_mpfr(r)) != 0

    zopen = (x.open | y.open | inex) & (isfinite(x.num) | x.open) & (isfinite(y.num) | y.open)
    Bnum(znum, zopen)
end

function -(x::Bnum, y::Bnum, r::RoundingMode)
    znum = BigFloat()
    inex = ccall((:mpfr_sub,:libmpfr), Int32, (Ptr{BigFloat}, Ptr{BigFloat}, Ptr{BigFloat}, Int32), &znum, &x.num, &y.num, to_mpfr(r)) != 0

    zopen = (x.open | y.open | inex) & (isfinite(x.num) | x.open) & (isfinite(y.num) | y.open)
    Bnum(znum, zopen)
end


function *(x::Bnum, y::Bnum, r::RoundingMode)
    znum = BigFloat()
    inex = ccall((:mpfr_mul,:libmpfr), Int32, (Ptr{BigFloat}, Ptr{BigFloat}, Ptr{BigFloat}, Int32), &znum, &x.num, &y.num, to_mpfr(r)) != 0

    zopen = (x.open | y.open | inex) & (isfinite(x.num) & (x.num!=0) | x.open) & (isfinite(y.num) & (y.num!=0) | y.open)
    Bnum(znum, zopen)
end


import Base: min, max
# Technically not correct as we need to know the orientation, but assumes
# min is being used for lower bound, and max for upper bound
function min(x::Bnum,y::Bnum)
    if x.num == y.num
        Bnum(x.num,x.open & y.open)
    elseif x.num < y.num
        x
    else
        y
    end
end
function max(x::Bnum,y::Bnum)
    if x.num == y.num
        Bnum(x.num,x.open & y.open)
    elseif x.num > y.num
        x
    else
        y
    end
end

import Base: isnan
isnan(x::Bnum) = isnan(x.num)

typealias Bbound Interval{Bnum}

function convert(::Type{Bbound},x::Real)
    c = convert(Bnum,x)
    Interval(c,c)
end

function print(io::IO, b::Bbound)
    nlo = b.lo.num
    flo = Float64(nlo)
    nhi = b.hi.num
    fhi = Float64(nhi)
    
    if nlo == nhi
        print(io,nlo==flo?flo:nlo)
    else
        print(io,b.lo.open?'(':'[',nlo==flo?flo:nlo,',',nhi==fhi?fhi:nhi,b.hi.open?')':']')
    end
end

show(io::IO, b::Bbound) = print(io,typeof(b),'\n',b)


isposz(x::Bbound) = x.lo.num >= 0
isnegz(x::Bbound) = x.hi.num <= 0