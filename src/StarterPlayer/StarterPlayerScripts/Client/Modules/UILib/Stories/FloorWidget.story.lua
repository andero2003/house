local UILib = require(script.Parent.Parent)
local Fusion = UILib.Fusion

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
local StyledButton = UILib.StyledButton


return {
	summary = 'SidebarButton',
	controls = {
		--color = Color3.fromRGB(119, 180, 255)	
	},
	story = function(parent, props) 
		local testFrame = Center {
			Child = Fusion.New "Frame" {
				BackgroundTransparency = 1;
				Size = UDim2.fromScale(0.25, 0.9);

				[Fusion.Children] = {
					StyledText {
						Size = UDim2.fromScale(1, 0.25),
						Text = 'FLOOR 1'
					},
					StyledButton {
						BackgroundColor3 = Color3.fromRGB(134, 134, 134);
						AnchorPoint = Vector2.new(0.5, 0),
						Position = UDim2.fromScale(0.25, 0.4),
						Size = UDim2.fromScale(0.35, 0.5),
						[Fusion.OnEvent "MouseButton1Click"] = function()
							
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
		testFrame.Parent = parent
		
		return function()
			testFrame:Destroy()
		end
	end
}
