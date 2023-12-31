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
local Modules = script.Parent.Parent.Parent:WaitForChild('Modules')

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

type Props = {
    Position: Fusion.CanBeState<UDim2>,
	Items: {Model},
    OnItemClicked: (Model) -> ()
}

return function(props: Props)
    local _items = Fusion.ForPairs(props.Items, function(k, item: Model)
        return k, AspectRatio {
            AspectRatio = 1;
            Child = Fusion.New "Frame" {
                Size = UDim2.fromScale(0.25, 0.9),
                BackgroundTransparency = 1;
                [Fusion.Children] = {
                    Center {
                        Child = StyledButton {
                            BackgroundColor3 = Color3.fromRGB(134, 134, 134);
                            Size = UDim2.fromScale(0.9, 0.9),
                            [Fusion.OnEvent "MouseButton1Click"] = function()
                                props.OnItemClicked(item)
                            end,
                            [Fusion.Children] = {
                                Center {
                                    -- Child = Icon {
                                    --     Image = 'rbxassetid://15761822391';
                                    --     Size = UDim2.fromScale(0.85, 0.85);
                                    -- }
                                    Child = StyledText {
                                        Text = item.Name;
                                        Size = UDim2.fromScale(0.8, 0.4);
                                    }
                                }
                            }
                        }
                    }
                }
            },
        }
    end, Fusion.Cleanup)

    return MaterialBannerText {
        CornerRadius = UDim.new(0, 8),
        Size = UDim2.new(0.4, 0, 0.1, 0),
        Position = props.Position,
        AnchorPoint = Vector2.new(0.5, 1),
        [Fusion.Children] = {
            Fusion.New "ScrollingFrame" {
                ScrollingDirection = Enum.ScrollingDirection.X,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                CanvasSize = UDim2.new(0, 0, 0, 0),
                AutomaticCanvasSize = Enum.AutomaticSize.X,
                Size = UDim2.new(1, 0, 1, 0),
                [Fusion.Children] = {
                    Fusion.New "UIListLayout" {
                        Padding = UDim.new(0, 0),
                        FillDirection = Enum.FillDirection.Horizontal,
                        SortOrder = Enum.SortOrder.LayoutOrder,
                        VerticalAlignment = Enum.VerticalAlignment.Center,
                    },
                    _items
                }
            },
            
        }
    }
end