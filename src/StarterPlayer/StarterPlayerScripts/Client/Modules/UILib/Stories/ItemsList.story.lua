local UILib = require(script.Parent.Parent)
local MaterialBannerText = require(script.Parent.Parent.Widgets.MaterialBannerText)
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

local function item()
	return 							
end

return {
	summary = 'SidebarButton',
	controls = {
		--color = Color3.fromRGB(119, 180, 255)	
	},
	story = function(parent, props) 
		local testFrame = Center {
			Child = MaterialBannerText {
				CornerRadius = UDim.new(0, 8),
				Size = UDim2.new(0.4, 0, 0.1, 0),
				Position = Fusion.Tween(Fusion.Computed(function()
					--local state = self.State:get()
					return UDim2.fromScale(0.5, 0.9) --UDim2.new(0.5, 0, state == nil and 0.9 or 1.5, 0)
				end), TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)),
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
							AspectRatio {
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
						
												end,
												[Fusion.Children] = {
													Center {
														Child = Icon {
															Image = 'rbxassetid://15761822391';
															Size = UDim2.fromScale(0.85, 0.85);
														}
													}
												}
											}
										}
									}
								},
							}
						}
					},
					
				}
			}
		} 
		testFrame.Parent = parent
		
		return function()
			testFrame:Destroy()
		end
	end
}
