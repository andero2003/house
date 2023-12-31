local UILib = {}
local Fusion = require(script:WaitForChild('Fusion'))
UILib.Fusion = Fusion
UILib.WrapPropState = function(prop: Fusion.CanBeState, cleanup: {})
	local _stateVal = Fusion.Value(prop:get())
	table.insert(cleanup, Fusion.Observer(prop):onChange(function() 
		_stateVal:set(prop:get())
	end))
	return _stateVal
end

for _, module in script:WaitForChild('Widgets'):GetChildren() do
	UILib[module.Name] = require(module)	
end

return UILib
