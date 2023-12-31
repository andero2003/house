local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

-- Load all services:
for _,v in ipairs(script.Parent.Services:GetDescendants()) do
	if (v:IsA("ModuleScript")) then
		require(v)
	end
end

-- Load all components:
for _,v in ipairs(script.Parent.Components:GetDescendants()) do
	if (v:IsA("ModuleScript")) then
		require(v)
	end
end

Knit.Start():catch(warn)
