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

local STATES = require(Modules:WaitForChild('States'))

local FloorPlacing = {}
FloorPlacing.__index = FloorPlacing

type Plot = {
	Baseplate: BasePart,
	CurrentLevel: Fusion.Value<number>,
	Floors: () -> Folder,
	Walls: () -> Folder,
	Items: () -> Folder,
}

function FloorPlacing.new(plot: Plot, onPlacement: (pos1: Vector2, pos2: Vector2) -> nil)
    local self = setmetatable({}, FloorPlacing)
    self._maid = Trove.new()

    self._plot = plot
    self._onPlacement = onPlacement

	self._currentGridTargetPos = Fusion.Value(Vector3.new())
	self._startHoldingPos = Fusion.Value(nil)

	self._currentRelative = Fusion.Value(Vector2.new())
	self._startRelative = Fusion.Value(nil)

	self._floorSize = Fusion.Computed(function()
		if not self._startHoldingPos:get() then return Vector3.new() end
		local pos = self._startHoldingPos:get()
		local targetPos = self._currentGridTargetPos:get()
		local size = targetPos - pos
		return Vector3.new(math.abs(size.X), 1, math.abs(size.Z))
	end)

	self._floorCFrame = Fusion.Computed(function()
		if not self._startHoldingPos:get() then return CFrame.new()	end
		local pos = self._startHoldingPos:get()
		local targetPos = self._currentGridTargetPos:get()
		return CFrame.new(pos:Lerp(targetPos, 0.5))
	end)

	self._isOverlapping = Fusion.Computed(function()
		local currentCFrame, currentSize = self._floorCFrame:get(), self._floorSize:get()

		local floorsFolder = self._plot.Floors()
		for _, existingFloor in floorsFolder:GetChildren() do
			local bottomLeft = existingFloor.CFrame * Vector3.new(-existingFloor.Size.X/2, 0, -existingFloor.Size.Z/2)
			local topRight = existingFloor.CFrame * Vector3.new(existingFloor.Size.X/2, 0, existingFloor.Size.Z/2)

			local bottomLeft2 = currentCFrame * Vector3.new(-currentSize.X/2, 0, -currentSize.Z/2)				
			local topRight2 = currentCFrame * Vector3.new(currentSize.X/2, 0, currentSize.Z/2)

			if bottomLeft.X < topRight2.X and topRight.X > bottomLeft2.X and bottomLeft.Z < topRight2.Z and topRight.Z > bottomLeft2.Z then
				print(existingFloor)
				return true
			end
		end
		return false
	end)

	self._isBigEnough = Fusion.Computed(function()
		local currentSize = self._floorSize:get()
		return currentSize.X >= 5 and currentSize.Z >= 5
	end)

	self._placementIsValid = Fusion.Computed(function()
		return self._isBigEnough:get() and not self._isOverlapping:get()
	end)

    self:SetupVisuals()
    self:SetupListeners()

    return self
end

function FloorPlacing:Raycast(override: Vector2?)
    local _params = RaycastParams.new()
	_params.FilterType = Enum.RaycastFilterType.Include
	_params.FilterDescendantsInstances = {self._plot.Baseplate}

    local raycastResult: RaycastResult = self._mouse:Raycast(_params, 1000, override)
    if raycastResult then
        local pos = raycastResult.Position
        local x = math.round(pos.X)
        local z = math.round(pos.Z)

        self._currentGridTargetPos:set(Vector3.new(x, pos.Y, z))
		
		local relative = CFrame.new(self._currentGridTargetPos:get()):ToObjectSpace(self._plot.Baseplate.CFrame)
		self._currentRelative:set(Vector2.new(relative.X, relative.Z))
	end
end

function FloorPlacing:FinishPlacement()
    local start, current = self._startHoldingPos:get(), self._currentGridTargetPos:get()
    local maxX, minX = math.max(start.X, current.X), math.min(start.X, current.X)
    local maxZ, minZ = math.max(start.Z, current.Z), math.min(start.Z, current.Z)

    start = Vector3.new(minX, start.Y, minZ)
    current = Vector3.new(maxX, start.Y, maxZ)
    
    if self._placementIsValid:get() then
        self._onPlacement(self._startRelative:get(), self._currentRelative:get())
    end

    self._startHoldingPos:set(nil)
	self._startRelative:set(nil)
end

function FloorPlacing:SetupListeners()
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

function FloorPlacing:SetupVisuals()
    local _dragger = Fusion.New "Part" {
		Parent = Workspace,
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.Neon,
		Transparency = 0.5,
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(4, 0.25, 0.25),
		Color = Fusion.Computed(function()
			return self._placementIsValid:get() and Color3.fromRGB(105, 223, 217) or Color3.fromRGB(255, 0, 0)
		end),
		CFrame = Fusion.Computed(function()
			local pos = self._currentGridTargetPos:get()
			return CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90))
		end),
	}	
    self._maid:Add(_dragger)
    self._dragger = _dragger

	local _visualRect = Fusion.New "Part" {
		Parent = Workspace,
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.Neon,
		Transparency = 0.5,
		Shape = Enum.PartType.Block,
		Size = self._floorSize,
		CFrame = Fusion.Computed(function()
			return self._floorCFrame:get()
		end),
		Color = Fusion.Computed(function()
			return self._placementIsValid:get() and Color3.fromRGB(105, 223, 217) or Color3.fromRGB(255, 0, 0)
		end),
	}
    self._maid:Add(_visualRect)
    self._visualRect = _visualRect
end

function FloorPlacing:Destroy()
    self._maid:Destroy()    
end

return FloorPlacing