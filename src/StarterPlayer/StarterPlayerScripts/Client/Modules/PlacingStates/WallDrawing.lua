local Player = game.Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local HUD = PlayerGui:WaitForChild("HUD")

local CollectionService = game:GetService('CollectionService')
local Lighting = game:GetService('Lighting')
local TweenService = game:GetService('TweenService')
local RunService = game:GetService('RunService')
local UIS = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Knit = require(Packages.Knit)
local Trove = require(Knit.Util.Trove)
local TableUtil = require(Knit.Util.TableUtil)
local Promise = require(Knit.Util.Promise)
local Signal = require(Knit.Util.Signal)
local Timer = require(Knit.Util.Timer)
local Input = require(Packages:WaitForChild('Input'))
local Mouse = Input.Mouse
local Touch = Input.Touch

local MoneyLib = require(ReplicatedStorage:WaitForChild('MoneyLib'))
local Fusion = require(Packages:WaitForChild('Fusion'))

local RNG = Random.new()
local Modules = script.Parent.Parent

local UILib = require(Modules:WaitForChild('UILib'))

local AnimatedButton = UILib.AnimatedButton
local Center = UILib.Center
local RoundCorner = UILib.RoundCorner
local AspectRatio = UILib.AspectRatio
local Elevation = UILib.Elevation
local Stroke = UILib.Stroke
local CloseButton = UILib.CloseButton
local DefaultRoundButton = UILib.DefaultRoundButton
local Icon = UILib.Icon
local StyledText = UILib.StyledText
local StatDisplay = UILib.StatDisplay
local MaterialBannerText = UILib.MaterialBannerText
local StyledButton = UILib.StyledButton

local ContextBillboard = require(Modules:WaitForChild('ContextBillboard'))

local DataStructures = ReplicatedStorage:WaitForChild("DataStructures")
local WallGraph = require(DataStructures:WaitForChild("WallGraph"))
type WallGraph = WallGraph.WallGraph

local WallDrawing = {}
WallDrawing.__index = WallDrawing

type Plot = {
	Baseplate: BasePart,
	CurrentLevel: Fusion.Value<number>,
	Floors: () -> Folder,
	Walls: () -> Folder,
	Items: () -> Folder,
	WallGraph: WallGraph,
}

function WallDrawing.new(plot: Plot, onPlacement: (pos1: Vector2, pos2: Vector2) -> nil, height: number?, thickness: number?)
    local self = setmetatable({}, WallDrawing)
    self._maid = Trove.new()

    self._plot = plot
    self._onPlacement = onPlacement

	self._currentGridTargetPos = Fusion.Value(Vector3.new())
	self._startHoldingPos = Fusion.Value(nil)

	self._currentRelative = Fusion.Value(Vector3.new())
	self._startRelative = Fusion.Value(nil)

	self.Height = height or 10
	self.Thickness = thickness or 0.1

	local _wallsFolder = self._plot.Walls()

	local _isIntersecting = Fusion.Computed(function()
		local start, current = self._startHoldingPos:get(), self._currentGridTargetPos:get()
		if not start then return false end
        local direction = (current - start).Unit

        -- Perform a raycast to check if the new wall intersects with any existing walls
		local _intersectionParams = RaycastParams.new()
		_intersectionParams.FilterType = Enum.RaycastFilterType.Exclude
		_intersectionParams.FilterDescendantsInstances = {Player.Character}
        local raycastResult: RaycastResult = workspace:Raycast(
			start, 
			direction * (current - start).Magnitude, 
			_intersectionParams
		)
		if raycastResult then
			local wall = raycastResult.Instance
			if wall:IsDescendantOf(_wallsFolder) and wall.Name ~= 'Wall' then
				return true
			end
		end
	end)

	local _isLongEnough = Fusion.Computed(function()
		local start, current = self._startHoldingPos:get(), self._currentGridTargetPos:get()
		if not start then return false end
		return (current - start).Magnitude >= 1
	end)

	self._placementIsValid = Fusion.Computed(function()
		return not _isIntersecting:get() and _isLongEnough:get()
	end)

	self._wallSize = Fusion.Computed(function()
		if not self._startHoldingPos:get() then return Vector3.new() end
		local start, current = self._startHoldingPos:get(), self._currentGridTargetPos:get()
		local maxX, minX = math.max(start.X, current.X), math.min(start.X, current.X)
		local maxZ, minZ = math.max(start.Z, current.Z), math.min(start.Z, current.Z)

		start = Vector3.new(minX, start.Y, minZ)
		current = Vector3.new(maxX, start.Y, maxZ)

		return Vector3.new((start-current).Magnitude, self.Height, self.Thickness)
	end)

	self._wallCF = Fusion.Computed(function()
		if not self._startHoldingPos:get() then return CFrame.new() end
		local start, current = self._startHoldingPos:get(), self._currentGridTargetPos:get()
		local maxX, minX = math.max(start.X, current.X), math.min(start.X, current.X)
		local maxZ, minZ = math.max(start.Z, current.Z), math.min(start.Z, current.Z)

		start = Vector3.new(minX, start.Y + self.Height/2, minZ)
		current = Vector3.new(maxX, current.Y + self.Height/2, maxZ)

		-- Determine whether the wall is being drawn along the X or Z axis
		local isXAxis = math.abs(start.X - current.X) > math.abs(start.Z - current.Z)

		return CFrame.new(start:Lerp(current, 0.5)) * CFrame.Angles(0, isXAxis and 0 or math.pi/2, 0)
	end)

    self:SetupVisuals()
    self:SetupListeners()

    return self
end

function WallDrawing:Raycast(override: Vector2?)
	local _params = RaycastParams.new()
	_params.FilterType = Enum.RaycastFilterType.Include
	_params.FilterDescendantsInstances = {self._plot.Baseplate}

	local raycastResult: RaycastResult = self._mouse:Raycast(_params, 1000, override)

	if raycastResult then
		local floor = raycastResult.Instance
		local pos = raycastResult.Position

		local x = math.round(pos.X)
		local z = math.round(pos.Z)

		local start = self._startHoldingPos:get()
		if start then
			local diffX = math.abs(pos.X - start.X)
			local diffZ = math.abs(pos.Z - start.Z)
	
			-- Snap the current position to the nearest axis
			if diffX > diffZ then
				pos = Vector3.new(math.round(pos.X), start.Y, start.Z)
			else
				pos = Vector3.new(start.X, start.Y, math.round(pos.Z))
			end
	
			self._currentGridTargetPos:set(pos)		
		else
			self._currentGridTargetPos:set(Vector3.new(x, pos.Y, z))
		end

		local relative = CFrame.new(self._currentGridTargetPos:get()):ToObjectSpace(self._plot.Baseplate.CFrame)
		self._currentRelative:set(Vector2.new(relative.X, relative.Z))
	end
end

function WallDrawing:FinishPlacement()
	local start = self._startHoldingPos:get()
	local finish = self._currentGridTargetPos:get()
	if start and finish and self._placementIsValid:get() then
		self._onPlacement(self._startRelative:get(), self._currentRelative:get())
	end
	self._startHoldingPos:set(nil)
	self._startRelative:set(nil)
end

function WallDrawing:SetupListeners()
    --MOUSE LISTENERS
    self._mouse = Mouse.new()
	self._mouse.LeftDown:Connect(function()
		self._startHoldingPos:set(self._currentGridTargetPos:get())
		self._startRelative:set(self._currentRelative:get())
	end)
	self._mouse.LeftUp:Connect(function()
		self:FinishPlacement()
    end)
    self._maid:Add(self._mouse)

    --TOUCH LISTENERS
    if not UIS.TouchEnabled then 
        self._maid:Add(RunService.Heartbeat:Connect(function(deltaTime)
			self:Raycast()
		end))
        return 
    end
    local _touch = Touch.new()
    _touch.TouchTapInWorld:Connect(function(pos, gpe)
        if gpe then return end
        self:Raycast(pos)
    end)
    self._maid:Add(_touch)

    local contextBillboard = ContextBillboard(self._dragger, {
		AspectRatio {
			Ratio = 1,
			Child = StyledButton {
				Size = UDim2.fromScale(0.5, 0.5);
				BackgroundColor3 = Fusion.Computed(function()
					if self._startHoldingPos:get() == nil then
						return Color3.fromRGB(83, 212, 90)
					end
					return self._placementIsValid:get() and Color3.fromRGB(83, 212, 90) or Color3.fromRGB(255, 0, 0)
				end);
				[Fusion.OnEvent "MouseButton1Click"] = function()
					if self._startHoldingPos:get() == nil then
						self._startHoldingPos:set(self._currentGridTargetPos:get())
					else
						self:FinishPlacement()
					end
				end,
				[Fusion.Children] = {
					Center {
						Child = Icon {
							Image = 'rbxassetid://15757334056';
							Size = UDim2.fromScale(0.8, 0.8)
						}
					}
				}
			}
		}
    })
    self._maid:Add(contextBillboard)
end

function WallDrawing:SetupVisuals()
	local _visual = Fusion.New "Part" {
		Parent = Workspace,
		Anchored = true,
		CanCollide = false,
		Transparency = 0.5,
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(20, 0.25, 0.25),
		Color = Color3.fromRGB(18, 218, 68),
		CFrame = Fusion.Computed(function()
			local pos = self._currentGridTargetPos:get()
			return CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90))
		end),
	}	
	self._maid:Add(_visual)

	local _visualRect = Fusion.New "Part" {
		Parent = Workspace,
		Anchored = true,
		CanCollide = false,
		Transparency = 0.5,
		Size = self._wallSize,
		Color = Fusion.Computed(function()
			return self._placementIsValid:get() and Color3.fromRGB(18, 218, 68) or Color3.fromRGB(255, 0, 0) 
		end),
		CFrame = self._wallCF,
	}
	self._maid:Add(_visualRect)
end

function WallDrawing:Destroy()
    self._maid:Destroy()    
end

return WallDrawing