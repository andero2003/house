local Fusion = require(script.Parent.Parent:WaitForChild('Fusion'))
local Mouse = game.Players.LocalPlayer:GetMouse()

type Props = {	
	Elevation: number,
	Child: GuiObject
}

return function(props: Props)
	local _elevation =Fusion.New "UIGradient" {
		Parent = props.Child;
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(0.496, Color3.fromRGB(253, 253, 253)),
			ColorSequenceKeypoint.new(0.503, Color3.fromRGB(188, 188, 188)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(176, 176, 176))
		});
		Offset = Vector2.new(0, 0.5 - (props.Elevation or 5)/200);
		Rotation = 90;
	};
	return props.Child
end
