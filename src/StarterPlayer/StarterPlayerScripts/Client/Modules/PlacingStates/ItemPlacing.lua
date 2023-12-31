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
local Keyboard = Input.Keyboard

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

local ItemPlacing = {}
ItemPlacing.__index = ItemPlacing

type Plot = {
	Baseplate: BasePart,
	CurrentLevel: Fusion.Value<number>,
	Floors: () -> Folder,
	Walls: () -> Folder,
	Items: () -> Folder,
}

function ItemPlacing.new(plot: Plot, onPlacement: (cf: CFrame) -> nil, item: Model)
    local self = setmetatable({}, ItemPlacing)
    self._maid = Trove.new()

    self._plot = plot
    self._onPlacement = onPlacement
	self._currentGridTargetCFrame = Fusion.Value(CFrame.new())	
	self._rotation = Fusion.Value(0)

	self._item = item:Clone()
	self._item.Parent = Workspace
	self._item:PivotTo(self._currentGridTargetCFrame:get())

	self._maid:Add(self._item)
	self._maid:Add(	Fusion.Observer(self._currentGridTargetCFrame):onChange(function()
		local cframe = self._currentGridTargetCFrame:get()
		self._item:PivotTo(cframe)
	end))


    self:SetupVisuals()
    self:SetupListeners()

    return self
end

function ItemPlacing:Reset()
	self._currentGridTargetCFrame:set(CFrame.new())
end

function ItemPlacing:Raycast(override: Vector2?)
	local baseplate = self._plot.Baseplate
	local _boundingBox = self._item.PrimaryPart.Size
	local _params = RaycastParams.new()
	_params.FilterType = Enum.RaycastFilterType.Include
	_params.FilterDescendantsInstances = {baseplate, self._plot.Floors(), game.Workspace:WaitForChild('Baseplate')}		
	local raycastResult: RaycastResult = self._mouse:Raycast(_params, 1000, override)
	if raycastResult then			
		local pos = raycastResult.Position

		local sizeX, sizeZ = _boundingBox.X, _boundingBox.Z
		if self._rotation:get() % 180 == 90 then
			sizeX, sizeZ = sizeZ, sizeX
		end

		local offsetX = sizeX % 2 == 1 and 0.5 or 0
        local offsetZ = sizeZ % 2 == 1 and 0.5 or 0

		local relativeCFrame = CFrame.new(pos):ToObjectSpace(baseplate.CFrame)
		local snappedPosition = Vector3.new(
			math.round(relativeCFrame.Position.X) - offsetX,
			0,
			math.round(relativeCFrame.Position.Z) - offsetZ
		)

		local isFloor = raycastResult.Instance:IsDescendantOf(self._plot.Floors())
		local yOffset = isFloor and raycastResult.Instance.Size.Y/2 or 0

		local clampedPos = Vector3.new(
			math.clamp(snappedPosition.X, -baseplate.Size.X/2 + sizeX/2, baseplate.Size.X/2 - sizeX/2),
			-(_boundingBox.Y/2 + yOffset),
			math.clamp(snappedPosition.Z, -baseplate.Size.Z/2 + sizeZ/2, baseplate.Size.Z/2 - sizeZ/2)
		)

		local cframe = baseplate.CFrame * CFrame.new(-clampedPos) * CFrame.Angles(0, math.rad(self._rotation:get()), 0)
		self._currentGridTargetCFrame:set(cframe)
	end	
end

function ItemPlacing:SetupListeners()
    --MOUSE LISTENERS
    self._mouse = Mouse.new()
	self._mouse.LeftDown:Connect(function()
		self._onPlacement(self._currentGridTargetCFrame:get())
	end)
    self._maid:Add(self._mouse)

	--KEYBOARD LISTENERS
	local _keyboard = Keyboard.new()
	_keyboard.KeyDown:Connect(function(key)
		if key == Enum.KeyCode.R then
			self._rotation:set((self._rotation:get() + 90) % 360)
		end
	end)
	self._maid:Add(_keyboard)

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
					self._onPlacement(self._currentGridTargetCFrame:get())
					self:Reset()
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

function ItemPlacing:SetupVisuals()
	local _selectionBox = Instance.new('SelectionBox')
	_selectionBox.Adornee = self._item.PrimaryPart
	_selectionBox.Color3 = Color3.fromRGB(99, 216, 88)
	_selectionBox.LineThickness = 0.05
	_selectionBox.SurfaceColor3 = Color3.fromRGB(99, 216, 88)
	_selectionBox.SurfaceTransparency = 0.5
	_selectionBox.Parent = self._item
	self._maid:Add(_selectionBox)
end

function ItemPlacing:Destroy()
    self._maid:Destroy()    
end

return ItemPlacing