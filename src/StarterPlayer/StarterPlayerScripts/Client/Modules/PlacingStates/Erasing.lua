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

local Erasing = {}
Erasing.__index = Erasing

type Plot = {
	Baseplate: BasePart,
	CurrentLevel: Fusion.Value<number>,
	Floors: () -> Folder,
	Walls: () -> Folder,
	Items: () -> Folder,
}

function Erasing.new(plot: Plot, onErase: (item: PVInstance) -> nil)
    local self = setmetatable({}, Erasing)
    self._maid = Trove.new()

    self._plot = plot
    self._onErase = onErase

	self._targetObject = Fusion.Value(nil)
	
	local _highlight = Instance.new('Highlight')
	_highlight.FillColor = Color3.fromRGB(255, 0, 0)
	_highlight.Name = 'Highlight'

	self._highlight = _highlight
	self._maid:Add(_highlight)

    self:SetupListeners()

    return self
end

function Erasing:Reset()
	self._targetObject:set(nil)
	self._highlight.Adornee = nil
	self._highlight.Parent = script
end

local function recursivelyFindHitbox(part: PVInstance)
	if part:FindFirstChild('Hitbox') then
		return part.Hitbox
	end
	if part == game.Workspace then
		return nil
	end
	return recursivelyFindHitbox(part.Parent)
end

function Erasing:Raycast(override: Vector2?)
	local _params = RaycastParams.new()
	_params.FilterType = Enum.RaycastFilterType.Include
	_params.FilterDescendantsInstances = {self._plot.Walls(), self._plot.Floors(), self._plot.Items()}		
	local raycastResult: RaycastResult = self._mouse:Raycast(_params, 1000, override)
	if raycastResult then
		local part: BasePart = raycastResult.Instance
		
		if part:IsDescendantOf(self._plot.Items()) then
			local hitbox = recursivelyFindHitbox(part)
			if not hitbox then 
				self:Reset()
				return 
			end
			self._highlight.Adornee = hitbox.Parent
			self._highlight.Parent = hitbox.Parent
			self._targetObject:set(hitbox.Parent)
		else
			local wallOrFloor = part
			self._highlight.Adornee = wallOrFloor
			self._highlight.Parent = wallOrFloor
			self._targetObject:set(wallOrFloor)
		end
	else
		self:Reset()
	end
end

function Erasing:SetupListeners()
    --MOUSE LISTENERS
    self._mouse = Mouse.new()
	self._mouse.LeftDown:Connect(function()
		if not self._targetObject:get() then return end
		self._onErase(self._targetObject:get())
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
				BackgroundColor3 = Color3.fromRGB(204, 82, 82);
				Size = UDim2.fromScale(0.5, 0.5);
				[Fusion.OnEvent "MouseButton1Click"] = function()
					if not self._targetObject:get() then return end
					self._onErase(self._targetObject:get())
				end,
				[Fusion.Children] = {
					Center {
						Child = Icon {
							Image = 'rbxassetid://15757392336';
							Size = UDim2.fromScale(0.8, 0.8)
						}
					}
				}
			}
			
		}
    })
    self._maid:Add(contextBillboard)
end

function Erasing:Destroy()
    self._maid:Destroy()    
end

return Erasing