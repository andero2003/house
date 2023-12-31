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

local WallNegativePlacing = {}
WallNegativePlacing.__index = WallNegativePlacing

type Plot = {
	Baseplate: BasePart,
	CurrentLevel: Fusion.Value<number>,
	Floors: () -> Folder,
	Walls: () -> Folder,
	Items: () -> Folder,
}

type ClampFunction = (wall: BasePart, boundingBox: Vector3, localPos: Vector3) -> Vector3

function WallNegativePlacing.new(plot: Plot, onPlacement: (wall: BasePart, finish: Vector3) -> nil, item: Model, clampFunction: ClampFunction)
    local self = setmetatable({}, WallNegativePlacing)
    self._maid = Trove.new()

    self._plot = plot
    self._onPlacement = onPlacement

	self._currentGridTargetCFrame = Fusion.Value(CFrame.new())
	self._targetWall = Fusion.Value(nil)

	self._clampFunction = clampFunction

	self._itemId = item:GetAttribute('Id')

	self._boundingBox = item.PrimaryPart.Size

	local _itemVisual = item:Clone()
	_itemVisual.Parent = Workspace
	self._maid:Add(_itemVisual)

	self._maid:Add(Fusion.Observer(self._currentGridTargetCFrame):onChange(function()
		_itemVisual:PivotTo(self._currentGridTargetCFrame:get())
	end))

	self:SetupListeners()

    return self
end

function WallNegativePlacing:Reset()
	self._targetWall:set(nil)
	self._currentGridTargetCFrame:set(CFrame.new())
end

function WallNegativePlacing:Raycast(override: Vector2?)
	local _params = RaycastParams.new()
	_params.FilterType = Enum.RaycastFilterType.Include
	_params.FilterDescendantsInstances = {self._plot.Walls()}		
	local raycastResult: RaycastResult = self._mouse:Raycast(_params, 1000, override)
	if raycastResult then
		local pos = raycastResult.Position
		local wall: BasePart = raycastResult.Instance

        local dotProduct = raycastResult.Normal:Dot(wall.CFrame.LookVector)
		if math.abs(dotProduct) < 0.05 then
			self:Reset()
			return
		end

		local localPos = wall.CFrame:ToObjectSpace(CFrame.new(pos)).Position

		local xOffset = math.abs((self._boundingBox.X + wall.Size.X) % 2 - 1) < 0.005 and 0.5 or 0
		local yOffset = math.abs((self._boundingBox.Y + wall.Size.Y) % 2 - 1) < 0.005 and 0.5 or 0

		if self._clampFunction then
			localPos = self._clampFunction(wall, self._boundingBox, localPos)
		end


		local isXAxis = math.abs(localPos.X) > math.abs(localPos.Z)

		self._targetWall:set(wall)
		self._currentGridTargetCFrame:set(
			wall.CFrame * CFrame.new(
				(isXAxis and (math.round(localPos.X) + xOffset) or localPos.X),
				math.round(localPos.Y) + yOffset, 
				(isXAxis and localPos.Z or (math.round(localPos.Z) + xOffset))
			)
		)
	else
		self._targetWall:set(nil)
	end	
end

function WallNegativePlacing:ValidatePosition()
    -- Define the four corners of the wall negative
	local wall = self._targetWall:get()
	if not wall then return end
	local relativeCF = wall.CFrame:ToObjectSpace(self._currentGridTargetCFrame:get())
	local size = self._boundingBox

    local corners = {
		(relativeCF * CFrame.new(size.X / 2, size.Y / 2, 0)).Position,
		(relativeCF * CFrame.new(-size.X / 2, size.Y / 2, 0)).Position,
		(relativeCF * CFrame.new(size.X / 2, -size.Y / 2, 0)).Position,
		(relativeCF * CFrame.new(-size.X / 2, -size.Y / 2, 0)).Position,
	}

	
    -- Check if each corner is within the bounds of the wall
    for _, corner in ipairs(corners) do
       if math.abs(corner.X) > wall.Size.X / 2 + 0.1 or math.abs(corner.Y) > wall.Size.Y / 2 + 0.1 then
		   return false
	   end
    end

    return true
end

function WallNegativePlacing:FinishPlacement()
	if not self._targetWall:get() then return end
	if not self:ValidatePosition() then return end
	self._onPlacement(self._targetWall:get(), self._currentGridTargetCFrame:get(), self._itemId)
	self:Reset()
end

function WallNegativePlacing:SetupListeners()
    --MOUSE LISTENERS
    self._mouse = Mouse.new()
	self._mouse.LeftDown:Connect(function()
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
				BackgroundColor3 = Color3.fromRGB(83, 212, 90);
				Size = UDim2.fromScale(0.5, 0.5);
				[Fusion.OnEvent "MouseButton1Click"] = function()
					self:FinishPlacement()					
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

function WallNegativePlacing:Destroy()
    self._maid:Destroy()    
end

return WallNegativePlacing