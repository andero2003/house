local GridNode = require(script.Parent:WaitForChild("GridNode"))
local HttpService = game:GetService("HttpService")

type GridNode = GridNode.GridNode

local Graph = {}
Graph.__index = Graph

export type Graph = {
    _nodes: {[GridNode]: boolean},
    _edges: {[GridNode]: {[GridNode]: boolean}},
}

function Graph.new(): Graph
    local self = setmetatable({}, Graph)
    self._nodes = {}
    self._edges = {}
    return self
end

function Graph:GetNodeByPosition(pos: Vector2): GridNode?
    for node, _ in self._nodes do
        if math.abs(node._x - pos.X) < 0.05 and math.abs(node._z - pos.Y) < 0.05 then
            return node
        end
    end
    return nil    
end

function Graph:InsertNode(node): nil
    self._nodes[node] = true
    self._edges[node] = {}
end

function Graph:RemoveNode(node): nil
    self._nodes[node] = nil
    self._edges[node] = nil
    for _, edges in pairs(self._edges) do
        edges[node] = nil
    end
end

function Graph:InsertEdge(node1, node2): string
    if not self._nodes[node1] or not self._nodes[node2] then
        return
    end
    if not self._edges[node1] then
        self._edges[node1] = {}
    end
    if not self._edges[node2] then
        self._edges[node2] = {}
    end

    local uuid = node1 < node2 and (tostring(node1) .. ':' .. tostring(node2)) or (tostring(node2) .. ':' .. tostring(node1))
    self._edges[node1][node2] = uuid
    self._edges[node2][node1] = uuid

    return uuid
end

function Graph:RemoveEdge(node1, node2): string
    if not self._nodes[node1] or not self._nodes[node2] then
        return
    end
    if not self._edges[node1] or not self._edges[node2] then
        return
    end

    local uuid = self._edges[node1][node2]
    self._edges[node1][node2] = nil
    self._edges[node2][node1] = nil

    return uuid
end

return Graph