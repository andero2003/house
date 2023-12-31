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

local PlacingService = Knit.CreateService {
	Name = "PlacingService",
	Client = {	

	}
}
-- INITIALISATION & CONNECTIONS --
function PlacingService:KnitInit()

end

function PlacingService:KnitStart()
	Players.PlayerAdded:Connect(function(player: Player)
		local plot: Model = Assets:WaitForChild('PlotTemp'):Clone()
		plot.Parent = game.Workspace:WaitForChild('Plots')
		plot.Name = player.UserId

		local freeId = self:GetFreePositionId()
		plot:SetAttribute('PosId', freeId)
		plot:PivotTo(CFrame.new(freeId*100, 0.1, -60))
	end)

	Players.PlayerRemoving:Connect(function(player: Player)
		local plot: Model = game.Workspace:WaitForChild('Plots'):WaitForChild(player.UserId)
		plot:Destroy()
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

	local localDoorPos = wall.CFrame:ToObjectSpace(absoluteCF).Position
	local width, height = item.PrimaryPart.Size.X, item.PrimaryPart.Size.Y

	local leftSize = Vector3.new(wallLength/2 - localDoorPos.X - width/2, wall.Size.Y, wall.Size.Z)
	local rightSize = Vector3.new(wallLength - width - leftSize.X, wall.Size.Y, wall.Size.Z)
	local topSize = Vector3.new(width, (wall.Size.Y - height)/2 - localDoorPos.Y , wall.Size.Z)
	local bottomSize = Vector3.new(width, wall.Size.Y - height - topSize.Y, wall.Size.Z)

	local leftCF = wall.CFrame * CFrame.new(localDoorPos.X + width/2 + leftSize.X/2, 0, 0)
	local rightCF = wall.CFrame * CFrame.new(localDoorPos.X - width/2 - rightSize.X/2, 0, 0)
	local topCF = wall.CFrame * CFrame.new(localDoorPos.X, localDoorPos.Y + height/2 + topSize.Y/2, 0)
	local bottomCF = wall.CFrame * CFrame.new(localDoorPos.X, localDoorPos.Y - height/2 - bottomSize.Y/2, 0)

	-- Create the left, right, and top parts of the wall
	if leftSize.X > 0.2 and leftSize.Y > 0.2 then
		local leftWall = Instance.new("Part")
		leftWall.Size = leftSize
		leftWall.CFrame = leftCF
		leftWall.Parent = wallsFolder
		leftWall.Color = Color3.fromRGB(168, 168, 168)
		leftWall.Anchored = true
	end

	if rightSize.X > 0.2 and rightSize.Y > 0.2 then
		local rightWall = Instance.new("Part")
		rightWall.Size = rightSize
		rightWall.CFrame = rightCF
		rightWall.Parent = wallsFolder
		rightWall.Color = Color3.fromRGB(168, 168, 168)
		rightWall.Anchored = true
	end

	if topSize.Y > 0.2 and topSize.X > 0.2 then
		local topWall = Instance.new("Part")
		topWall.Size = topSize
		topWall.CFrame = topCF
		topWall.Parent = wallsFolder
		topWall.Color = Color3.fromRGB(168, 168, 168)
		topWall.Anchored = true
	end

	if bottomSize.Y > 0.2 and bottomSize.X > 0.2 then
		local bottomWall = Instance.new("Part")
		bottomWall.Size = bottomSize
		bottomWall.CFrame = bottomCF
		bottomWall.Parent = wallsFolder
		bottomWall.Color = Color3.fromRGB(168, 168, 168)
		bottomWall.Anchored = true
	end

	item = item:Clone()
	item.Parent = itemsFolder
	item:PivotTo(absoluteCF)

	wall:Destroy()
end
function PlacingService.Client:PlaceWallNegative(...)
	return self.Server:PlaceWallNegative(...)
end

function PlacingService:Erase(player: Player, wallOrFloor: BasePart)
	local plot = game.Workspace:WaitForChild('Plots'):WaitForChild(player.UserId)
	if not wallOrFloor:IsDescendantOf(plot) then return end
	if wallOrFloor:FindFirstChild('DoorPointer') then
		wallOrFloor.DoorPointer.Value:Destroy()
	end
	wallOrFloor:Destroy()
end
function PlacingService.Client:Erase(...)
	return self.Server:Erase(...)
end

function PlacingService:DrawWall(player: Player, start: Vector3, current: Vector3, level: number)
	local plot = game.Workspace:WaitForChild('Plots'):WaitForChild(player.UserId)

	-- Determine whether the wall is being drawn along the X or Z axis
	local isXAxis = math.abs(start.X - current.X) > math.abs(start.Z - current.Z)

	local wallHeight = 10
	local wallThickness = 0.1
	
	local wallSize = Vector3.new((start-current).Magnitude, wallHeight, wallThickness)
	local wallCFrame = CFrame.new(start:Lerp(current, 0.5)) * CFrame.new(0, wallHeight/2, 0) * CFrame.Angles(0, isXAxis and 0 or math.pi/2, 0)

	local wallsFolder = plot:WaitForChild('Walls'):WaitForChild(level)
	local wall = Fusion.New "Part" {
		Parent = wallsFolder,
		Name = HttpService:GenerateGUID(false),
		Anchored = true,
		Material = Enum.Material.SmoothPlastic,
		Size = wallSize,
		CFrame = wallCFrame,
		Color = Color3.fromRGB(168, 168, 168),
	}
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

function PlacingService:DrawFloor(player: Player, start: Vector3, current: Vector3, level: number)
	local plot = game.Workspace:WaitForChild('Plots'):WaitForChild(player.UserId)

	local floorSize = Vector3.new(math.abs(start.X - current.X), 1, math.abs(start.Z - current.Z))
	local floorCFrame = CFrame.new(start:Lerp(current, 0.5))

	local floorsFolder = plot:WaitForChild('Floors'):WaitForChild(level)
	local floor = Fusion.New "Part" {
		Parent = floorsFolder,
		Anchored = true,
		Material = Enum.Material.Brick,
		Size = floorSize,
		CFrame = floorCFrame,
		Color = Color3.fromRGB(168, 168, 168),
	}

	return floorSize, floorCFrame
end
function PlacingService.Client:DrawFloor(...)
	return self.Server:DrawFloor(...)
end

return PlacingService