local Fusion = require(script.Parent.Parent:WaitForChild('Fusion'))
local Mouse = game.Players.LocalPlayer:GetMouse()

local Promise = require(script:WaitForChild('Promise'))

type Props = {	
	Promise: any,
	Builder: (response: {status: 'LOADING' | 'SUCCESS' | 'ERROR', data: any}) -> (GuiObject)
}

return function(props: Props)	
	local _response = Fusion.Value({
		status = 'LOADING',
		data = nil
	})
	
	props.Promise:andThen(function(...) 
		_response:set({
			status = 'SUCCESS',
			data = {...}
		})
	end):catch(function() 
		_response:set({
			status = 'ERROR',
			data = nil
		})	
	end)
	
	return Fusion.New "Frame" {
		Size = UDim2.fromScale(1,1);
		BackgroundTransparency = 1;
		[Fusion.Children] = {
			Fusion.Computed(function() 
				return props.Builder(_response:get())
			end, Fusion.cleanup)
		}
	}
end
