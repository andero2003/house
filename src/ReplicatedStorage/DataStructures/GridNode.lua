local GridNode = {}
GridNode.__index = GridNode

export type GridNode = {
    _x: number,
    _z: number,
    wallNegativeId: number?
}

function GridNode.new(x, z, wallNegativeId)
    local self = setmetatable({}, GridNode)
    self._x = x
    self._z = z
    self.wallNegativeId = wallNegativeId
    return self
end

function GridNode:Equals(other)
    return self._x == other._x and self._z == other._z
end

function GridNode:__tostring()
    return string.format("GridNode(%d, %d)", self._x, self._z)
end

function GridNode:__lt(other: GridNode)
    if self._x == other._x then
        return self._z < other._z
    end
    return self._x < other._x
end

return GridNode