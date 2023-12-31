local Fusion = require(script.Parent.Parent:WaitForChild('Fusion'))
local Mouse = game.Players.LocalPlayer:GetMouse()

type Props = {	
	Child: GuiObject
}

return function(props: Props)
	props.Child.Position = UDim2.fromScale(0.5, 0.5)
	props.Child.AnchorPoint = Vector2.new(0.5, 0.5)
	return props.Child
end
