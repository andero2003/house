local Fusion = require(script.Parent.Parent:WaitForChild('Fusion'))
local Mouse = game.Players.LocalPlayer:GetMouse()

local Stroke = require(script.Parent:WaitForChild('Stroke'))
local StyledText = require(script.Parent:WaitForChild('StyledText'))
local Elevation = require(script.Parent:WaitForChild('Elevation'))
local RoundCorner = require(script.Parent:WaitForChild('RoundCorner'))

type Props = TextLabel

return function(props: Props)
	props.BackgroundTransparency = 0
	
	local _strokeColor = props.StrokeColor or Color3.new()
	props.StrokeColor = nil
    local _cornerRadius = props.CornerRadius or UDim.new(0.5, 0);
    props.CornerRadius = nil
	return RoundCorner {
        CornerRadius = _cornerRadius;
        Child = Stroke {
            Color = _strokeColor;
            Thickness = 2;
            Child = Elevation {
                Elevation = 10;
                Child = StyledText(props)
            }
        }
    };
end