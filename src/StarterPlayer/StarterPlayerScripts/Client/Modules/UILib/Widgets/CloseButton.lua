local Fusion = require(script.Parent.Parent:WaitForChild('Fusion'))

local Center = require(script.Parent:WaitForChild('Center'))
local StyledText = require(script.Parent:WaitForChild('StyledText'))
local DefaultRoundButton = require(script.Parent:WaitForChild('DefaultRoundButton'))

local RNG = Random.new()

return function(props)		
	props.BackgroundColor3 = props.BackgroundColor3 or Color3.new(0.854902, 0.0941176, 0.0941176)
	local _children = props[Fusion.Children] or {}
	table.insert(_children, Center {
		Child = StyledText{
			Size = UDim2.fromScale(0.6, 0.6);
			Text = 'X'
		}
	})
	props[Fusion.Children] = _children
	props.StrokeColor = Color3.fromRGB(157, 38, 38)
	
	return DefaultRoundButton(props)
end
