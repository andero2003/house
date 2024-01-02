local Graph = require(script.Parent:WaitForChild("Graph"))
local GridNode = require(script.Parent:WaitForChild("GridNode"))

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Knit = require(Packages.Knit)
local Signal = require(Knit.Util.Signal)

local HttpService = game:GetService("HttpService")

local WallGraph = {}
WallGraph.__index = WallGraph
setmetatable(WallGraph, Graph)

type GridNode = GridNode.GridNode
type Graph = Graph.Graph

export type WallGraph = Graph & {
    _baseplate: BasePart,
}

function WallGraph.new(baseplate: BasePart): WallGraph
    local self = setmetatable(Graph.new(), WallGraph)
    self._baseplate = baseplate

    self.EdgeAdded = Signal.new()
    self.EdgeRemoved = Signal.new()

    return self
end

function WallGraph:_interalAddEdge(node1: GridNode, node2: GridNode): nil
    local uuid = Graph.InsertEdge(self, node1, node2)
    self.EdgeAdded:Fire(node1, node2, uuid)
end

function WallGraph:_internalRemoveEdge(node1: GridNode, node2: GridNode): nil
    local uuid = Graph.RemoveEdge(self, node1, node2)
    self.EdgeRemoved:Fire(uuid)
end

function WallGraph:InsertNode(relativePos: Vector2, wallNegativeId: number?)
    local node = GridNode.new(relativePos.X, relativePos.Y, wallNegativeId)
    Graph.InsertNode(self, node)

    -- Check if the new node lies on any existing edges
    for node1, edges in pairs(self._edges) do
        for node2, _ in pairs(edges) do
            if self:_isOnEdge(node, node1, node2) then
                -- Remove the old edge
                self:_internalRemoveEdge(node1, node2)

                -- Add two new edges
                self:_interalAddEdge(node, node1)
                self:_interalAddEdge(node, node2)

                --break
            end
        end
    end

    return node
end

function WallGraph:_isOnEdge(node, node1, node2)
    -- Return false if the node is the same as node1 or node2
    if node == node1 or node == node2 then
        return false
    end

    
    local ax, ay = node1._x, node1._z
    local bx, by = node2._x, node2._z
    local px, py = node._x, node._z

    -- Check if it's a vertical line
    if ax == bx and ax == px then
        return py >= math.min(ay, by) and py <= math.max(ay, by)
    end

    -- Check if it's a horizontal line
    if ay == by and ay == py then
        return px >= math.min(ax, bx) and px <= math.max(ax, bx)
    end

    -- If neither, the point is not on the line segment
    return false
end

function WallGraph:InsertEdge(pos1: Vector2, pos2: Vector2)
    --Essentially it just creates the nodes if they don't exist
    local node1 = Graph.GetNodeByPosition(self, pos1)
    if not node1 then
        node1 = self:InsertNode(pos1)
    end
    local node2 = Graph.GetNodeByPosition(self, pos2)
    if not node2 then
        node2 = self:InsertNode(pos2)
    end

    local oldNodesOnTheLine = {node1, node2}

    for oldNode, _ in self._edges do
        if oldNode ~= node1 and oldNode ~= node2 and self:_isOnEdge(oldNode, node1, node2) then
            --Old edge endpoint falls on the line of the new edge
            --New edge must be subdivided further
            table.insert(oldNodesOnTheLine, oldNode)
        end
    end

    table.sort(oldNodesOnTheLine, function(node1, node2)
        return node1 < node2
    end)

    --Create segments
    for i = 1, #oldNodesOnTheLine - 1 do
        self:_interalAddEdge(oldNodesOnTheLine[i], oldNodesOnTheLine[i + 1])
    end

    self:_recalculateRooms()
end

function WallGraph:RemoveEdge(pos1: Vector2, pos2: Vector2, returnNodes: boolean?)
    local node1 = Graph.GetNodeByPosition(self, pos1)
    local node2 = Graph.GetNodeByPosition(self, pos2)

    if node1 and node2 then
        self:_internalRemoveEdge(node1, node2)

        if returnNodes then
            return node1, node2
        end
        
        for node, _ in self._nodes do
            if next(self._edges[node]) == nil then
                Graph.RemoveNode(self, node)
            end
        end

        self:_recalculateRooms()
    end
end

-- DFS method for cycle detection
function WallGraph:_DFS(currentNode, visited, path, allCycles)
    visited[currentNode] = true
    table.insert(path, currentNode)

    for neighbor, _ in (self._edges[currentNode] or {}) do
        if not visited[neighbor] then
            self:_DFS(neighbor, visited, path, allCycles)
        elseif self:_isCycle(path, neighbor) then
            local cycle = self:_extractCycle(path, neighbor)
            self:_addCycleIfUnique(allCycles, cycle)
        end
    end

    -- Backtrack
    visited[currentNode] = false
    table.remove(path)
end

-- Check if adding a node to a path forms a cycle
function WallGraph:_isCycle(path, node)
    if #path > 1 and path[#path - 1] ~= node and table.find(path, node) then
        return true
    end
    return false
end

-- Extract a cycle from a path
function WallGraph:_extractCycle(path, node)
    local cycle = {}
    local startCycle = false
    for i = 1, #path do
        if path[i] == node then
            startCycle = true
        end
        if startCycle then
            table.insert(cycle, path[i])
        end
    end
    table.insert(cycle, node)  -- Add the starting node to complete the cycle
    return cycle
end

-- Add a cycle to the list if it is unique
function WallGraph:_addCycleIfUnique(allCycles, cycle)
    -- Convert the cycle to a set of nodes
    local cycleSet = self:_cycleToSet(cycle)
    for _, other in allCycles do
        if self:_areSetsEqual(cycleSet, self:_cycleToSet(other)) then
            return  -- The cycle is not unique
        end
    end

    table.insert(allCycles, cycle)  -- Add the new unique cycle
end

type Cycle = {GridNode}

function WallGraph:_cycleToSet(cycle: Cycle)
    local cycleSet = {}
    for _, node in cycle do
        cycleSet[node] = true
    end
    return cycleSet
end

function WallGraph:_cycleToEdgeSet(cycle: Cycle)
    local edgeSet = {}
    -- Assuming the cycle is an ordered list of nodes
    for i = 1, #cycle - 1 do
        local node1 = cycle[i]
        local node2 = cycle[i + 1]
        local edge = node1 < node2 and (tostring(node1) .. ':' .. tostring(node2)) or (tostring(node2) .. ':' .. tostring(node1))
        edgeSet[edge] = true -- Create a string representation of the edge for the key
    end
    return edgeSet
end

function WallGraph:_setXOR(set1, set2)
    local xorSet = {}
    for edge, _ in set1 do
        xorSet[edge] = true
    end
    for edge, _ in set2 do
        if xorSet[edge] then
            xorSet[edge] = nil
        else
            xorSet[edge] = true
        end
    end
    return xorSet
end

local function append(t, new)
    local clone = {}
    for _, item in t do
        clone [#clone + 1] = item
    end
    clone [#clone + 1] = new
    return clone
end

local function unique_combinations(tbl, sub, min)
    sub = sub or {}
    min = min or 1
    return coroutine.wrap(function ()
        if #sub > 0 then
            coroutine.yield (sub) -- yield short combination.
        end
        if #sub < #tbl then
            for i = min, #tbl do    -- iterate over longer combinations.
                for combo in unique_combinations (tbl, append (sub, tbl [i]), i + 1) do
                    coroutine.yield (combo)
                end
            end
        end
    end)
end

function WallGraph:_areSetsEqual(set1, set2)
    for key, _ in set1 do
        if not set2[key] then
            return false
        end
    end
    for key, _ in set2 do
        if not set1[key] then
            return false
        end
    end
    return true
end

function WallGraph:_isCycleExpressibleAsXORSum(cycle, cycleBasis)
    local cycleAsEdgeSet = self:_cycleToEdgeSet(cycle)

    for combination in unique_combinations(cycleBasis) do
        local combinedXOR = {}
        for _, basisCycle in combination do
            local basisCycleAsEdgeSet = self:_cycleToEdgeSet(basisCycle)
            combinedXOR = self:_setXOR(combinedXOR, basisCycleAsEdgeSet)
        end

        if self:_areSetsEqual(combinedXOR, cycleAsEdgeSet) then
            return true
        end
    end

    return false
end

function WallGraph:_recalculateRooms()
    self._baseplate.Parent:WaitForChild('Visuals'):ClearAllChildren()

    local visited = {}
    local path = {}
    local allCycles: {Cycle} = {} --List of unique cycles

    for node, _ in pairs(self._nodes) do
        if not visited[node] then
            self:_DFS(node, visited, path, allCycles)
        end
    end

    table.sort(allCycles, function(cycle1, cycle2)
        return #cycle1 < #cycle2
    end)

    local cycleBasis = {}
    for _, cycle in allCycles do
        if not self:_isCycleExpressibleAsXORSum(cycle, cycleBasis) then
            table.insert(cycleBasis, cycle)
        end    
    end

    for node, _ in self._nodes do
        local part = Instance.new("Part")
        part.Parent = self._baseplate.Parent:WaitForChild('Visuals')
        part.Anchored = true
        part.CanCollide = false
        part.Material = Enum.Material.Neon
        part.Shape = Enum.PartType.Ball
        part.Name = tostring(node)
        part.Size = Vector3.new(1, 1, 1)
        part.CFrame = self._baseplate.CFrame * CFrame.new(node._x, 0, node._z):Inverse()
        part.Color = Color3.fromHSV(0, 0, 1)
    end

    -- Visualise the cycles
    for i, cycle in cycleBasis do
        local color = Color3.fromHSV(i / #cycleBasis, 1, 1)
        for _, node in cycle do
            local part = Instance.new("Part")
            part.Parent = self._baseplate.Parent:WaitForChild('Visuals')
            part.Anchored = true
            part.CanCollide = false
            part.Material = Enum.Material.Neon
            part.Size = Vector3.new(1, 1, 1)
            part.CFrame = self._baseplate.CFrame * CFrame.new(node._x, 0-i, node._z):Inverse()
            part.Color = color
        end

        local floorParts = self:_generateFloorPartsForRoom(cycle)
        if self:_isCompletelyEnclosed(cycle, cycleBasis) then
           continue
        end

        for _, floortPart in floorParts do
            local part = Instance.new("Part")
            part.Parent = self._baseplate.Parent:WaitForChild('Visuals')
            part.Anchored = true
            part.Color = color
            part.TopSurface = Enum.SurfaceType.SmoothNoOutlines

            local x1, x2 = floortPart.x1, floortPart.x2
            local z1, z2 = floortPart.y1, floortPart.y2
            local height = 1
            local cframe = CFrame.new((x1 + x2) / 2 + 0.5, -height / 2, (z1 + z2) / 2)
            local size = Vector3.new(math.abs(x2 - x1) + 1, height, math.abs(z2 - z1))
        
            part.Size = size
            part.CFrame = self._baseplate.CFrame * cframe:Inverse()
        end
    end

end

function WallGraph:_isCompletelyEnclosed(cycle: Cycle, cycleBasis: {Cycle})
    
end

function WallGraph:_generateFloorPartsForRoom(room)
    -- Assuming room is a list of nodes in clockwise or counterclockwise order
    local horizontalStrips = self:_getHorizontalStrips(room)
    local floorParts = {}

    for i = 1, #horizontalStrips - 1 do
        local y1 = horizontalStrips[i]
        local y2 = horizontalStrips[i + 1]

        local segments = self:_getHorizontalSegments(y1, y2, room)
        
        for _, segment in ipairs(segments) do
            local floorPart = {x1 = segment.start, x2 = segment.stop, y1 = y1, y2 = y2}
            table.insert(floorParts, floorPart)
        end
    end

    return floorParts
end

function WallGraph:_getHorizontalStrips(room)
    local yCoords = {}
    for _, node in ipairs(room) do
        yCoords[node._z] = true
    end

    local sortedYCoords = {}
    for yCoord, _ in pairs(yCoords) do
        table.insert(sortedYCoords, yCoord)
    end
    table.sort(sortedYCoords)

    return sortedYCoords
end

function WallGraph:_getHorizontalSegments(y1, y2, room)
    local segments = {}
    local roomBoundaries = self:_getRoomBoundaries(room)

    local xMin = roomBoundaries.xMin
    local xMax = roomBoundaries.xMax

    -- Scan from left to right to find segments
    local segmentStart = nil
    for x = xMin, xMax do
        local pointInside = self:_isPointInsideRoom({x, (y1 + y2) / 2}, room)
        
        if pointInside and not segmentStart then
            segmentStart = x
        elseif not pointInside and segmentStart then
            table.insert(segments, {start = segmentStart, stop = x - 1})
            segmentStart = nil
        end
    end

    -- Close the last segment if it reaches all the way to xMax
    if segmentStart then
        table.insert(segments, {start = segmentStart, stop = xMax})
    end

    return segments
end

function WallGraph:_getRoomBoundaries(room)
    local xMin, xMax, zMin, zMax = math.huge, -math.huge, math.huge, -math.huge
    for _, node in room do
        xMin = math.min(xMin, node._x)
        xMax = math.max(xMax, node._x)
        zMin = math.min(zMin, node._z)
        zMax = math.max(zMax, node._z)
    end
    return {xMin = xMin, xMax = xMax, zMin = zMin, zMax = zMax}
end

function WallGraph:_isPointInsideRoom(point, room)
    local x, y = point[1], point[2]
    local inside = false

    -- Find horizontal bounds
    local minX, maxX = math.huge, -math.huge
    for _, node in room do
        minX = math.min(minX, node._x)
        maxX = math.max(maxX, node._x)
    end

    -- Find vertical bounds
    local minY, maxY = math.huge, -math.huge
    for _, node in room do
        minY = math.min(minY, node._z)
        maxY = math.max(maxY, node._z)
    end

    -- Check if the point is inside the bounds
    if x >= minX and x <= maxX and y >= minY and y <= maxY then
        -- Further refine check to see if within room edges
        -- Assuming room nodes are ordered either clockwise or counterclockwise
        local j = #room
        for i = 1, #room do
            local xi, yi = room[i]._x, room[i]._z
            local xj, yj = room[j]._x, room[j]._z
            
            -- Check if point is on room edge
            if yi == yj and y == yi and x >= math.min(xi, xj) and x <= math.max(xi, xj) then
                return true
            end
            
            -- Check intersections
            local intersect = ((yi > y) ~= (yj > y)) and (x < (xj - xi) * (y - yi) / (yj - yi) + xi)
            if intersect then
                inside = not inside
            end
            j = i
        end
    end

    return inside
end

return WallGraph