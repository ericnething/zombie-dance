local Vec = {}

function Vec.sub(a, b)
   return { x = a.x - b.x,
            y = a.y - b.y }
end

function Vec.mag(vec)
   return math.sqrt(vec.x * vec.x + vec.y * vec.y)
end

function Vec.unit(vec)
   return Vec.mul(1 / Vec.mag(vec), vec)
end

function Vec.mul(scalar, vec)
   return { x = scalar * vec.x,
            y = scalar * vec.y }
end

return Vec
