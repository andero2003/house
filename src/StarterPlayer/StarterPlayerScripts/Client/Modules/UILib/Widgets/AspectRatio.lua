local Fusion = require(script.Parent.Parent:WaitForChild('Fusion'))
local Mouse = game.Players.LocalPlayer:GetMouse()

type Props = {	
	Ratio: number,
	Child: GuiObject
}

return function(props: Props)
	local _uiARConstraint = Fusion.New "UIAspectRatioConstraint" {
		Parent = props.Child;
		AspectRatio = props.Ratio or 1;		
	}
	return props.Child
end
