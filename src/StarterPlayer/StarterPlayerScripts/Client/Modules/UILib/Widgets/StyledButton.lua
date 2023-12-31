local Fusion = require(script.Parent.Parent:WaitForChild('Fusion'))
local Mouse = game.Players.LocalPlayer:GetMouse()

local Stroke = require(script.Parent:WaitForChild('Stroke'))
local RoundCorner = require(script.Parent:WaitForChild('RoundCorner'))
local Elevation = require(script.Parent:WaitForChild('Elevation'))
local AnimatedButton = require(script.Parent:WaitForChild('AnimatedButton'))

type Props = TextButton

return function(props: Props)
	local _cornerRadius = props.CornerRadius or UDim.new(0, 12)
	props.CornerRadius = nil;
	return Stroke {
		Thickness = 2;
		Child = RoundCorner {
			CornerRadius = _cornerRadius;	
			Child = Elevation {
				Elevation = 6;
				Child = AnimatedButton(props)
			} 	
		}
	} 
end
