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

local MoneyLib = require(ReplicatedStorage:WaitForChild('MoneyLib'))
local Fusion = require(Packages:WaitForChild('Fusion'))
local Assets = ReplicatedStorage:WaitForChild('Assets')

local RNG = Random.new()
local Modules = script.Parent.Parent:WaitForChild('Modules')

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

local PlacingController = Knit.CreateController { 
	Name = "PlacingController" 
}

local DataStructures = ReplicatedStorage:WaitForChild('DataStructures')
local WallGraph = require(DataStructures:WaitForChild('WallGraph'))

local ItemsList = require(script:WaitForChild('ItemsList'))

local PlacingStates = Modules:WaitForChild('PlacingStates')
local FloorPlacing = require(PlacingStates:WaitForChild('FloorPlacing'))
local WallNegativePlacing = require(PlacingStates:WaitForChild('WallNegativePlacing'))
local Erasing = require(PlacingStates:WaitForChild('Erasing'))
local WallDrawing = require(PlacingStates:WaitForChild('WallDrawing'))
local ItemPlacing = require(PlacingStates:WaitForChild('ItemPlacing'))

function PlacingController:KnitInit()
	local plots = game.Workspace:WaitForChild('Plots')

	local baseplate = plots:WaitForChild(Player.UserId):WaitForChild('Baseplate')

	local _currentLevel = Fusion.Value(0)
	self.Plot = {
		Baseplate = baseplate,
		CurrentLevel = _currentLevel,
		Floors = function()
			return plots:WaitForChild(Player.UserId):WaitForChild('Floors'):WaitForChild(_currentLevel:get())
		end,
		Walls = function()
			return plots:WaitForChild(Player.UserId):WaitForChild('Walls'):WaitForChild(_currentLevel:get())
		end,
		Items = function()
			return plots:WaitForChild(Player.UserId):WaitForChild('Items'):WaitForChild(_currentLevel:get())
		end,
		WallGraph = WallGraph.new(baseplate)
	}

	local _state = Fusion.Value(nil)
	self.State = _state
end

type StateClass = {
	new: (props: any) -> StateClass,
	Destroy: () -> nil,
}

function PlacingController:ToggleState(stateBuilder: () -> StateClass)
	local oldState = self.State:get()
	if oldState then
		oldState:Destroy()
	end
	if not stateBuilder then self.State:set(nil) return end
	self.State:set(stateBuilder())
end

function PlacingController:ButtonBuilder(text: string, stateBuilder: () -> StateClass)
	return DefaultRoundButton {
		Size = UDim2.fromScale(0.125, 0.85);
		[Fusion.OnEvent "MouseButton1Click"] = function()
			self:ToggleState(stateBuilder)
		end;
		[Fusion.Children] = {
			Center {
				Child = StyledText {
					Text = text,
				}
			}
		}
	}
end

function PlacingController:KnitStart()	
	local PlacingService = Knit.GetService('PlacingService')
	Fusion.Hydrate(self.Plot.Baseplate) {
		CFrame = Fusion.Tween(Fusion.Computed(function()
			local level = self.Plot.CurrentLevel:get()
			return CFrame.new(self.Plot.Baseplate.Position.X, 0.1 + level*10, self.Plot.Baseplate.Position.Z)
		end), TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)),
		Transparency = Fusion.Tween(Fusion.Computed(function()
			local level = self.Plot.CurrentLevel:get()
			return level == 0 and 0 or 0.75
		end), TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)),
	}

	local _itemsListOpen = Fusion.Value(false)
	local itemsList = ItemsList({
		Position = Fusion.Tween(Fusion.Computed(function()
			local open = _itemsListOpen:get()
			local state = self.State:get()
			return UDim2.new(0.5, 0, (open and state == nil) and 0.75 or 1.5, 0)
		end), TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)),
		Items = Assets:WaitForChild('Items'):GetChildren(),
		OnItemClicked = function(item: Model)
			self:ToggleState(function()
				return ItemPlacing.new(self.Plot, function(cf: CFrame)
					PlacingService:PlaceItem(cf, self.Plot.CurrentLevel:get(), item:GetAttribute('Id'))
				end, item)
			end)
		end
	})
	itemsList.Parent = HUD

	local _wallNegativesListOpen = Fusion.Value(false)
	local wallNegativesList = ItemsList({
		Position = Fusion.Tween(Fusion.Computed(function()
			local open = _wallNegativesListOpen:get()
			local state = self.State:get()
			return UDim2.new(0.5, 0, (open and state == nil) and 0.75 or 1.5, 0)
		end), TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)),
		Items = Assets:WaitForChild('WallNegatives'):GetChildren(),
		OnItemClicked = function(item: Model)
			self:ToggleState(function()
				return WallNegativePlacing.new(self.Plot, function(wall: BasePart, absoluteCF: CFrame, itemId: number)
					PlacingService:PlaceWallNegative(wall, absoluteCF, itemId, self.Plot.CurrentLevel:get())
				end, item, function(wall, boundingBox, localPos)
					return Vector3.new(
						localPos.X, 
						item.Name == 'Door' and -wall.Size.Y/2 + boundingBox.Y/2 or localPos.Y, 
						localPos.Z
					)
				end)
			end)
		end
	})
	wallNegativesList.Parent = HUD

	local optionBar = MaterialBannerText {
		CornerRadius = UDim.new(0, 8),
		Size = UDim2.new(0.4, 0, 0.15, 0),
		Position = Fusion.Tween(Fusion.Computed(function()
			local state = self.State:get()
			return UDim2.new(0.5, 0, state == nil and 0.925 or 1.5, 0)
		end), TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)),
		AnchorPoint = Vector2.new(0.5, 1),
		
		[Fusion.Children] = {
			Fusion.New "Folder" {
				[Fusion.Children] = {
					Fusion.New "Frame" {
						BackgroundTransparency = 1;
						Size = UDim2.fromScale(0.25, 0.9);
						Position = UDim2.fromScale(1.025, 0.5);
						AnchorPoint = Vector2.new(0, 0.5);

						[Fusion.Children] = {
							StyledText {
								Size = UDim2.fromScale(1, 0.25),
								Text = Fusion.Computed(function()
									local level = self.Plot.CurrentLevel:get()
									return 'FLOOR ' .. level
								end),
							},
							StyledButton {
								BackgroundColor3 = Color3.fromRGB(134, 134, 134);
								AnchorPoint = Vector2.new(0.5, 0),
								Position = UDim2.fromScale(0.25, 0.4),
								Size = UDim2.fromScale(0.35, 0.5),
								[Fusion.OnEvent "MouseButton1Click"] = function()
									self.Plot.CurrentLevel:set(math.min(self.Plot.CurrentLevel:get() + 1, 3))
								end,
								[Fusion.Children] = {
									Center {
										Child = Icon {
											Image = 'rbxassetid://15761822391';
											Size = UDim2.fromScale(0.8, 0.8);
										}
									}
								}
							};
							StyledButton {
								BackgroundColor3 = Color3.fromRGB(134, 134, 134);
								AnchorPoint = Vector2.new(0.5, 0),
								Position = UDim2.fromScale(0.75, 0.4),
								Size = UDim2.fromScale(0.35, 0.5),
								[Fusion.OnEvent "MouseButton1Click"] = function()
									self.Plot.CurrentLevel:set(math.max(self.Plot.CurrentLevel:get() - 1, 0))
								end,
								[Fusion.Children] = {
									Center {
										Child = Icon {
											Image = 'rbxassetid://15761825174';
											Size = UDim2.fromScale(0.8, 0.8);
										}
									}
								}
							}
						}
					}
				}
			};
			Fusion.New "UIListLayout" {
				Padding = UDim.new(0.025, 0),
				FillDirection = Enum.FillDirection.Horizontal,
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Center,
			},
			Fusion.New "UIPadding" {
				PaddingLeft = UDim.new(0.025, 0),
			};
			self:ButtonBuilder('FLOOR', function()
				return FloorPlacing.new(self.Plot, function(pos1: Vector2, pos2: Vector2)
					PlacingService:DrawFloor(pos1, pos2, self.Plot.CurrentLevel:get())
				end)
			end),
			self:ButtonBuilder('DOOR', function()
				_wallNegativesListOpen:set(not _wallNegativesListOpen:get())
				_itemsListOpen:set(false)
				return nil
			end),
			self:ButtonBuilder('ERASE', function()
				return Erasing.new(self.Plot, function(object: PVInstance)
					PlacingService:Erase(object)
				end)
			end),
			self:ButtonBuilder('WALL', function()
				return WallDrawing.new(self.Plot, function(pos1: Vector2, pos2: Vector2)
					PlacingService:DrawWall(pos1, pos2, self.Plot.CurrentLevel:get())
				end)
			end),
			self:ButtonBuilder('ITEM', function()
				_itemsListOpen:set(not _itemsListOpen:get())
				_wallNegativesListOpen:set(false)
				return nil
			end),

		}
	}
	

	local backButton = DefaultRoundButton {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = Fusion.Tween(Fusion.Computed(function()
			local state = self.State:get()
			return UDim2.new(0.5, 0, state == nil and 1.5 or 0.9, 0)
		end), TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)),
		[Fusion.OnEvent "MouseButton1Click"] = function()
			self:ToggleState(nil)
		end,
		BackgroundColor3 = Color3.fromRGB(200, 2, 2),
		Size = UDim2.new(0.1, 0, 0.1, 0),
		[Fusion.Children] = {
			Center {
				Child = Icon {
					Image = 'rbxassetid://15759312157';
					Size = UDim2.fromScale(0.8, 0.8);
				}
			}
		}
	}

	backButton.Parent = HUD
	optionBar.Parent = HUD
end

return PlacingController
