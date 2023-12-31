local Packages = game:GetService("ReplicatedStorage").Packages
local Knit = require(Packages:WaitForChild("Knit"))

local Loader = require(Packages:WaitForChild("Loader"))
Loader.LoadChildren(script.Parent:WaitForChild("ClientControllers"))

Knit.Start():andThen(function() 
	Loader.LoadChildren(script.Parent:WaitForChild("ClientComponents"))
end):catch(warn)