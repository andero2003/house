local Player = game.Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local UILib = require(script.Parent:WaitForChild('UILib'))
local Fusion = UILib.Fusion
local Center = UILib.Center
local Icon = UILib.Icon
local StyledButton = UILib.StyledButton
local AspectRatio = UILib.AspectRatio

return function(adornee: BasePart, widgets: {GuiObject})
    return Fusion.New "BillboardGui" {
        Parent = PlayerGui,
        Adornee = adornee,
        AlwaysOnTop = true,
        LightInfluence = 0,
        Size = UDim2.fromOffset(100, 100),
        StudsOffset = Vector3.new(0, 2, 0),
        MaxDistance = 50,
        Active = true,
        ResetOnSpawn = false,
        [Fusion.Children] = {
            Fusion.New "UIListLayout" {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0.025, 0),
                FillDirection = Enum.FillDirection.Horizontal,
            };
            widgets
        }
    }
end