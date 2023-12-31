local Fusion = require(script.Parent.Parent:WaitForChild('Fusion'))
local Mouse = game.Players.LocalPlayer:GetMouse()

local Stroke = require(script.Parent:WaitForChild('Stroke'))

type Props = TextLabel

return function(props: Props)
	props.FontFace = props.FontFace or Font.new("rbxasset://fonts/families/FredokaOne.json");
	props.TextColor3 = props.TextColor3 or Color3.new(1,1,1)
	if props.TextScaled == nil then
		props.TextScaled = true
	end
	props.Size = props.Size or UDim2.fromScale(1,1)
	props.TextWrapped = true
	props.BackgroundTransparency = props.BackgroundTransparency or 1
	
	local _strokeColor = props.StrokeColor or Color3.new()
	local _strokeThickness = props.StrokeThickness or 2
	props.StrokeColor = nil
	props.StrokeThickness = nil
	return Stroke {
		Thickness = _strokeThickness,
		Color = _strokeColor;
		ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
		Child =  Fusion.New("TextLabel")(props)
	}
end
