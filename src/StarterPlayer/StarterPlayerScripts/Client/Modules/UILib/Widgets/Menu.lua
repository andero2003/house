local Fusion = require(script.Parent.Parent:WaitForChild('Fusion'))
local Mouse = game.Players.LocalPlayer:GetMouse()

type Props = {	
	IsShown: Fusion.CanBeState<boolean>,
	
	Animation: TweenInfo,
	Child: GuiObject,
}


return function(props: Props)
	local _isShown = props.IsShown
	local _position = Fusion.Computed(function() 
		return _isShown:get() and UDim2.fromScale(0.5,0.5) or UDim2.fromScale(0.5,1.5)
	end)
		
	local _anim = props.Animation or TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
	
	local _blur = Fusion.New "BlurEffect" {
		Parent = game.Lighting,
		Size = Fusion.Tween(Fusion.Computed(function() 
			return _isShown:get() and 16 or 0
		end), _anim)
	}
	
	local frame = Fusion.New "Frame" {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = Fusion.Tween(_position, _anim); -- UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1,1); -- Fusion.Tween(_size, _anim),
		[Fusion.Children] = props.Child,
		[Fusion.Cleanup] = {
			_blur,
			function()
				_isShown:set(false)
			end,
		}
	}	
	
	return frame
end
