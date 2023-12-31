local Fusion = require(script.Parent.Parent:WaitForChild('Fusion'))
local Mouse = game.Players.LocalPlayer:GetMouse()

type Props = {	
	Color: UDim2,
	Thickness: number,
	Transparency: number,
	Child: GuiObject
}

return function(props: Props)
	local _uiStroke = Fusion.New "UIStroke" {
		Parent = props.Child;
		Color = props.Color or Color3.new();
		Thickness = props.Thickness or 1;
		Transparency = props.Transparency or 0;
		ApplyStrokeMode = props.ApplyStrokeMode or Enum.ApplyStrokeMode.Border
	}	
	return props.Child
end
