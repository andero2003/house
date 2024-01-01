local ServerScriptService = game:GetService('ServerScriptService')
local ServerStorage = game:GetService('ServerStorage')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local TweenService = game:GetService('TweenService')
local CollectionService = game:GetService('CollectionService')
local RunService = game:GetService('RunService')
local Players = game:GetService('Players')
local HttpService = game:GetService('HttpService')

local Packages = ReplicatedStorage:WaitForChild('Packages')

local Knit = require(Packages:WaitForChild('Knit'))
local Component = require(Packages:WaitForChild('Component'))
local TableUtil = require(Packages:WaitForChild('TableUtil'))
local Trove = require(Packages:WaitForChild('Trove'))
local Promise = require(Packages:WaitForChild('Promise'))
local Signal = require(Packages:WaitForChild('Signal'))

local Fusion = require(Packages:WaitForChild('Fusion'))
local Util = require(ReplicatedStorage.Util)

local Assets = ReplicatedStorage:WaitForChild('Assets')

local Server = ServerScriptService:WaitForChild('Server')
local Modules = Server:WaitForChild('Modules')
local Components = Server:WaitForChild('Components')

local DataStructures = ReplicatedStorage:WaitForChild("DataStructures")
local WallGraph = require(DataStructures:WaitForChild("WallGraph"))
local GridNode = require(DataStructures:WaitForChild("GridNode"))
type GridNode = GridNode.GridNode

local PlacingService = Knit.CreateService {
	Name = "PlacingService",
	Client = {	

	}
}
-- INITIALISATION & CONNECTIONS --
function PlacingService:KnitInit()
	self.WallGraphs = {}
	self.Maids = {}
end

function PlacingService:KnitStart()
	Players.PlayerAdded:Connect(function(player: Player)
		local plot: Model = Assets:WaitForChild('PlotTemp'):Clone()
		plot.Parent = game.Workspace:WaitForChild('Plots')
		plot.Name = player.UserId

		local freeId = self:GetFreePositionId()
		plot:SetAttribute('PosId', freeId)
		plot:PivotTo(CFrame.new(freeId*100, 0.1, -60))

		local wallGraph = WallGraph.new(plot:WaitForChild('Baseplate'))
		self.WallGraphs[player] = wallGraph

		local maid = Trove.new()
		self.Maids[player] = maid
		maid:Add(wallGraph.EdgeAdded:Connect(function(node1: GridNode, node2: GridNode, uuid: string)
			local plot = game.Workspace:WaitForChild('Plots'):WaitForChild(player.UserId)
			local level = 0
			local wallsFolder = plot:WaitForChild('Walls'):WaitForChild(level)
			if wallsFolder:FindFirstChild(uuid) then return end
			local isWallNegative = node1.wallNegativeId and node2.wallNegativeId
			if isWallNegative and node1.wallNegativeId == node2.wallNegativeId then return end

			local start = (plot:WaitForChild('Baseplate').CFrame * CFrame.new(Vector3.new(node1._x, 0, node1._z)):Inverse()).Position
			local current = (plot:WaitForChild('Baseplate').CFrame * CFrame.new(Vector3.new(node2._x, 0, node2._z)):Inverse()).Position

			-- Determine whether the wall is being drawn along the X or Z axis
			local isXAxis = math.abs(start.X - current.X) > math.abs(start.Z - current.Z)
		
			local wallHeight = 10
			local wallThickness = 0.1
			
			local wallSize = Vector3.new((start-current).Magnitude, wallHeight, wallThickness)
			local wallCFrame = CFrame.new(start:Lerp(current, 0.5)) * CFrame.new(0, wallHeight/2, 0) * CFrame.Angles(0, isXAxis and 0 or math.pi/2, 0)
		
			local wall = Fusion.New "Part" {
				Parent = wallsFolder,
				Name = uuid,
				Anchored = true,
				Material = Enum.Material.SmoothPlastic,
				Size = wallSize,
				CFrame = wallCFrame,
				Color = Color3.fromRGB(168, 168, 168),
			}		
		end))
		maid:Add(wallGraph.EdgeRemoved:Connect(function(uuid: string)
			local plot = game.Workspace:WaitForChild('Plots'):WaitForChild(player.UserId)
			local level = 0
			local wallsFolder = plot:WaitForChild('Walls'):WaitForChild(level)
			local wall = wallsFolder:FindFirstChild(uuid)
			if wall then
				wall:Destroy()
			end
		end))
	end)

	Players.PlayerRemoving:Connect(function(player: Player)
		local plot: Model = game.Workspace:WaitForChild('Plots'):WaitForChild(player.UserId)
		plot:Destroy()

		if self.WallGraphs[player] then
			self.WallGraphs[player] = nil
		end
		if self.Maids[player] then
			self.Maids[player]:Destroy()
			self.Maids[player] = nil
		end
	end)
end

local function getPlotByPosId(id: number)
	for _, plot in game.Workspace:WaitForChild('Plots'):GetChildren() do
		if plot:GetAttribute('PosId') == id then
			return plot
		end
	end
end

function PlacingService:GetFreePositionId()
	for i = 0, #game.Workspace:WaitForChild('Plots'):GetChildren() do
		if not getPlotByPosId(i) then
			return i
		end
	end
end

function PlacingService:PlaceWallNegative(player: Player, wall: BasePart, absoluteCF: CFrame, itemId: number, level: number)
	local plot = game.Workspace:WaitForChild('Plots'):WaitForChild(player.UserId)
	if not wall:IsDescendantOf(plot) then return end

	local item = Util.getById(Assets:WaitForChild('WallNegatives'), itemId)
	if not item then warn('Item does not exist') return end
	
	local wallLength = wall.Size.X

	local wallsFolder = plot:WaitForChild('Walls'):WaitForChild(level)
	local itemsFolder = plot:WaitForChild('Items'):WaitForChild(level)

	local width, height = item.PrimaryPart.Size.X, item.PrimaryPart.Size.Y

	local start, finish = (absoluteCF * CFrame.new(-width/2, 0, 0)):ToObjectSpace(plot.Baseplate.CFrame):Inverse(), (absoluteCF * CFrame.new(width / 2, 0, 0)):ToObjectSpace(plot.Baseplate.CFrame):Inverse()
	local pos1, pos2 = -Vector2.new(math.round(start.X), math.round(start.Z)), -Vector2.new(math.round(finish.X), math.round(finish.Z))

	--self:Erase(player, wall)
	local wallGraph = self.WallGraphs[player]
	if not wallGraph then return end
	--local wallNode1, wallNode2 = self:Erase(player, wall)
	local wallNegativeId = HttpService:GenerateGUID(false)
	local wallNegativeNode1, wallNegativeNode2 = wallGraph:InsertNode(pos1, wallNegativeId), wallGraph:InsertNode(pos2, wallNegativeId)
	wallGraph:_recalculateRooms()

	item = item:Clone()
	item.Parent = itemsFolder
	item:PivotTo(absoluteCF)

	item:SetAttribute('NodePos1', pos1)
	item:SetAttribute('NodePos2', pos2)

	local localDoorPos = wall.CFrame:ToObjectSpace(absoluteCF).Position

	local topSize = Vector3.new(width, (wall.Size.Y - height)/2 - localDoorPos.Y , wall.Size.Z)
	local topCF = wall.CFrame * CFrame.new(localDoorPos.X, localDoorPos.Y + height/2 + topSize.Y/2, 0)

	if topSize.Y > 0.2 and topSize.X > 0.2 then
		local topWall = Instance.new("Part")
		topWall.Size = topSize
		topWall.CFrame = topCF
		topWall.Parent = item
		topWall.Color = Color3.fromRGB(168, 168, 168)
		topWall.Anchored = true
	end
	local bottomSize = Vector3.new(width, wall.Size.Y - height - topSize.Y, wall.Size.Z)
	local bottomCF = wall.CFrame * CFrame.new(localDoorPos.X, localDoorPos.Y - height/2 - bottomSize.Y/2, 0)

	if bottomSize.Y > 0.2 and bottomSize.X > 0.2 then
		local bottomWall = Instance.new("Part")
		bottomWall.Size = bottomSize
		bottomWall.CFrame = bottomCF
		bottomWall.Parent = item
		bottomWall.Color = Color3.fromRGB(168, 168, 168)
		bottomWall.Anchored = true
	end
end
function PlacingService.Client:PlaceWallNegative(...)
	return self.Server:PlaceWallNegative(...)
end

function PlacingService:Erase(player: Player, wallOrFloor: BasePart)
	local plot = game.Workspace:WaitForChild('Plots'):WaitForChild(player.UserId)
	if not wallOrFloor:IsDescendantOf(plot) then return end
	if wallOrFloor:IsDescendantOf(plot:WaitForChild('Walls')) then
		local start, finish = (wallOrFloor.CFrame * CFrame.new(-wallOrFloor.Size.X / 2, 0, 0)):ToObjectSpace(plot.Baseplate.CFrame):Inverse(), (wallOrFloor.CFrame * CFrame.new(wallOrFloor.Size.X / 2, 0, 0)):ToObjectSpace(plot.Baseplate.CFrame):Inverse()
		local pos1, pos2 = -Vector2.new(start.X, start.Z), -Vector2.new(finish.X, finish.Z)
		
		local wallGraph = self.WallGraphs[player]
		if not wallGraph then return end
		local node1, node2 = wallGraph:RemoveEdge(pos1, pos2)
		return node1, node2
	else
		if wallOrFloor:GetAttribute('NodePos1') and wallOrFloor:GetAttribute('NodePos2') then
			local pos1, pos2 = wallOrFloor:GetAttribute('NodePos1'), wallOrFloor:GetAttribute('NodePos2')
			local wallGraph = self.WallGraphs[player]
			if not wallGraph then return end
			local node1, node2 = wallGraph:RemoveEdge(pos1, pos2, true)
			node1.wallNegativeId, node2.wallNegativeId = nil, nil
			wallGraph:InsertEdge(pos1, pos2)

			--Re-add nodes but without wallnegative tags
			wallGraph:_recalculateRooms()
		end
		wallOrFloor:Destroy()
	end
end
function PlacingService.Client:Erase(...)
	return self.Server:Erase(...)
end

function PlacingService:DrawWall(player: Player, pos1: Vector2, pos2: Vector2, level: number)
	local wallGraph = self.WallGraphs[player]
	if not wallGraph then return end
	wallGraph:InsertEdge(pos1, pos2)
end
function PlacingService.Client:DrawWall(...)
	return self.Server:DrawWall(...)
end

function PlacingService:PlaceItem(player: Player, cf: CFrame, level: number, itemId: number)
	local plot = game.Workspace:WaitForChild('Plots'):WaitForChild(player.UserId)
	--TODO sanity check for cframe
	local itemBase = Util.getById(Assets:WaitForChild('Items'), itemId)
	if not itemBase then warn('Item does not exist') return end

	local itemsFolder = plot:WaitForChild('Items'):WaitForChild(level)
	local item = itemBase:Clone()
	item.Parent = itemsFolder
	item:PivotTo(cf)
end
function PlacingService.Client:PlaceItem(...)
	return self.Server:PlaceItem(...)
end

function PlacingService:DrawFloor(player: Player, pos1: Vector2, pos2: Vector2, level: number)
	local wallGraph = self.WallGraphs[player]
	if not wallGraph then return end
	--Define 4 walls
	wallGraph:InsertEdge(pos1, Vector2.new(pos1.X, pos2.Y))
	wallGraph:InsertEdge(Vector2.new(pos1.X, pos2.Y), pos2)
	wallGraph:InsertEdge(pos2, Vector2.new(pos2.X, pos1.Y))
	wallGraph:InsertEdge(Vector2.new(pos2.X, pos1.Y), pos1)
end
function PlacingService.Client:DrawFloor(...)
	return self.Server:DrawFloor(...)
end

return PlacingService