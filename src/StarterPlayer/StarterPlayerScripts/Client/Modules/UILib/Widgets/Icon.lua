local Fusion = require(script.Parent.Parent:WaitForChild('Fusion'))
local Mouse = game.Players.LocalPlayer:GetMouse()

local AspectRatio = require(script.Parent:WaitForChild('AspectRatio'))

return function(props)
	props.BackgroundTransparency = props.BackgroundTransparency or 1
	return
		AspectRatio {
			Ratio = 1;
			Child = Fusion.New("ImageLabel")(props)
		} 
	
end
