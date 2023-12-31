local Fusion = require(script.Parent.Parent:WaitForChild('Fusion'))
local Mouse = game.Players.LocalPlayer:GetMouse()

type Props = {	
	CornerRadius: UDim,
	Child: GuiObject
}

return function(props: Props)
	local _uiCorner: UICorner = Fusion.New "UICorner" {
		Parent = props.Child;
		CornerRadius = props.CornerRadius or UDim.new(0, 8)	
	}
	return props.Child
end
