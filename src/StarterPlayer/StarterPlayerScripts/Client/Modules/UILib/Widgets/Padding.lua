local Fusion = require(script.Parent.Parent:WaitForChild('Fusion'))
local Mouse = game.Players.LocalPlayer:GetMouse()

type Props = {	
	Padding: UDim2,
	Child: GuiObject
}

return function(props: Props)
	props.Child.Size = props.Child.Size - props.Padding - props.Padding
	props.Child.Position = props.Child.Position + props.Padding
	return props.Child
end
