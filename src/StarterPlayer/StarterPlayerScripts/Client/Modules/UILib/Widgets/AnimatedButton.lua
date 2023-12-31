local Fusion = require(script.Parent.Parent:WaitForChild('Fusion'))
local Mouse = game.Players.LocalPlayer:GetMouse()

type Props = GuiButton & {
	Sound: string?,
	Animation: TweenInfo?
}

return function(props: Props)	
	local _anim = props.Animation or TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
	local _initialSize = props.Size or UDim2.fromOffset(100, 100)
	
	local _hovering = Fusion.Value(false)
	local _clicked = Fusion.Value(false)
		
	local _sound = Fusion.New "Sound" {
		SoundId = props.Sound or 'rbxassetid://6895079853',
	};
	
	local _children = props[Fusion.Children] or {}
	table.insert(_children, _sound)
	props[Fusion.Children] = _children
	
	props.AutoButtonColor = true
	
	props[Fusion.OnEvent "MouseEnter"] = function()
		_hovering:set(true)
	end

	props[Fusion.OnEvent "MouseLeave"] = function()
		task.defer(function() 				
			_hovering:set(false)
		end)
	end

	props[Fusion.OnEvent "MouseButton1Click"] = function()
		_clicked:set(true)
		_sound:Play()
		local callback = props[Fusion.OnEvent "MouseButton1Click"] or function() end
		callback()
		task.delay(_anim.Time, function() 
			_clicked:set(false)
		end)
	end
	
	props.Size = Fusion.Tween(Fusion.Computed(function() 
		return (_hovering:get() and not _clicked:get() and _initialSize + UDim2.fromOffset(6,6)) or (_clicked:get() and _initialSize - UDim2.fromOffset(2, 2)) or _initialSize
	end), _anim);
	
	
	--Prevent Instance initialisation from erroring
	props.OnClick = nil
	props.Sound = nil
	props.Animation = nil
	
	return Fusion.New( "TextButton" )(props)
end
