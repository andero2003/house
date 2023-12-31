local Fusion = require(script.Parent.Parent:WaitForChild('Fusion'))

local AspectRatio = require(script.Parent:WaitForChild('AspectRatio'))
local RoundCorner = require(script.Parent:WaitForChild('RoundCorner'))
local Center = require(script.Parent:WaitForChild('Center'))
local StyledText = require(script.Parent:WaitForChild('StyledText'))

local MoneyLib = require(game.ReplicatedStorage:WaitForChild('MoneyLib'))

local RNG = Random.new()

type Props = Frame & {	
	StatValue: Fusion.CanBeState,
}

return function(props: Props)	
	local _statValue =  props.StatValue
	local initialSize = props.Size or UDim2.fromScale(1,1)
	local _size = Fusion.Value(initialSize)
	local _onValueChange
	
	props.Size = Fusion.Tween(_size, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut));
	props[Fusion.Cleanup] = {_onValueChange}
	
	local _statText = Fusion.Value(MoneyLib.DealWithPoints(_statValue:get()))
	
	local _children = props[Fusion.Children] or {}
	table.insert(_children, StyledText {
		Position = UDim2.fromScale(0.6, 0.5);
		AnchorPoint = Vector2.new(0.5, 0.5);
		Size = UDim2.fromScale(0.6, 0.6);
		Text = _statText
	})
	props[Fusion.Children] = _children
	
	props.StatValue = nil
	local frame = Fusion.New("Frame")(props)
	local previousValue = _statValue:get()
	_onValueChange = Fusion.Observer(_statValue):onChange(function() 
		local newValue = _statValue:get()
		_statText:set(MoneyLib.DealWithPoints(newValue))
		local diff = newValue - previousValue
		previousValue = newValue
		if diff <= 0 then return end
		
		_size:set(initialSize + UDim2.fromOffset(14, 14))
		task.delay(0.15, function() _size:set(initialSize) end)

		local statChange = Center {
			Child = StyledText {
				Parent = frame;
				Size = UDim2.fromScale(0.8, 0.5);
				Text = `+{MoneyLib.DealWithPoints(diff)}`;
			}
		} 
		game:GetService('TweenService'):Create(statChange, TweenInfo.new(0.8), {
			Position = UDim2.fromScale(RNG:NextNumber(0.6, 0.75), RNG:NextNumber(1, 1.25)),
			Rotation = -RNG:NextNumber(10, 20)
		}):Play()
	
		game.Debris:AddItem(statChange, 0.8)
	end)

	return frame
end
