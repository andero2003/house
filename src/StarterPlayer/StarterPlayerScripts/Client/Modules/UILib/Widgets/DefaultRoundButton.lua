local Fusion = require(script.Parent.Parent:WaitForChild('Fusion'))

local AspectRatio = require(script.Parent:WaitForChild('AspectRatio'))
local RoundCorner = require(script.Parent:WaitForChild('RoundCorner'))
local Stroke = require(script.Parent:WaitForChild('Stroke'))
local AnimatedButton = require(script.Parent:WaitForChild('AnimatedButton'))

local RNG = Random.new()

return function(props)		
	local _strokeThickness = props.StrokeThickness or 3
	local _strokeColor = props.StrokeColor or Color3.new(0, 0, 0)
	props.StrokeThickness = nil
	props.StrokeColor = nil

	return AspectRatio {
		Ratio = 1,
		Child = RoundCorner {
			CornerRadius = UDim.new(0.5, 0),
			Child = Stroke { 
				Thickness = _strokeThickness;
				Color = _strokeColor;
				Child = AnimatedButton(props)
			}
		}
	}	
end
