local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local leaderboardFolder = game.Workspace:WaitForChild("Protected"):WaitForChild('StorefrontMain'):WaitForChild('Leaderboards')

local leaderboards = {}
local Stores = {}
local timeh = require(script:WaitForChild("time"))
local DSS = game:GetService("DataStoreService")
local availableStores = {"WinsEarnt", "TotalPlaytime", "BalloonsPlaced", "HighestAltitude", "RobuxSpent", "CashEarnt", "Rebirths"}
local availableLeaderboards = availableStores
local maxItems = 100
local itemsPerPage = 10

local MoneyLib = require(game.ReplicatedStorage:WaitForChild('MoneyLib'))

local writeFakeData = false
local playerSaveData = {}

function WaitLeaderboardReady(Stat)
	while not Stores[Stat] do wait() end
	return Stores[Stat]
end

function GetStoreName(fromName)
	return "GameLeader_0001_-"..fromName
end

function LoadStores()
	for i,v in pairs(availableStores) do
		local storeName = GetStoreName(v)
		Stores[v] = DSS:GetOrderedDataStore(storeName)
	end
end

function leaderboards.GetTop(Stat, Quantity)
	if not Quantity then Quantity = 100 end
	
	local currentStore = WaitLeaderboardReady(Stat)
	
	local success, page = pcall(function() 
		return currentStore:GetSortedAsync(false, Quantity)
	end)
	if success then
		local items = page:GetCurrentPage()
		return items --{["key"], ["value"]}
	else
		return {}
	end
end

function GetValueText(Stat, value)
	return value
end

local cache = {}
function UpdateShow(Stat)
	local items = leaderboards.GetTop(Stat, maxItems)
	local page = leaderboardFolder:WaitForChild(Stat):WaitForChild("Screen"):WaitForChild("SurfaceGui"):WaitForChild('Leaderboard')
	for _, v in pairs(page:GetChildren()) do
		if v:IsA('Frame') then
			v:Destroy()
		end
	end
	--Create new items
	local position = 0
	for i,v in pairs(items) do
		local userId = tonumber(v.key)
		local playerName, plrImage = '', ''
		if cache[tostring(userId)] then
			playerName, plrImage = unpack(cache[tostring(userId)])
		else
			local success1, err = pcall(function ()
				playerName = game.Players:GetNameFromUserIdAsync(tonumber(v.key))
			end)
			local success2, err = pcall(function()
				plrImage = game.Players:GetUserThumbnailAsync(userId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size60x60)
			end)
			if success1 and success2 then
				cache[tostring(userId)] = {playerName, plrImage}
			end
		end
		
		--if ok and playerName then -- and v.value > 0 then
		position = position + 1

		local fr = script:WaitForChild('PlayerTemplate'):Clone()
		fr:WaitForChild('Info'):WaitForChild("Username").Text = playerName
		fr:WaitForChild("Stats"):WaitForChild('Total').Text = (Stat == 'TotalPlaytime' and MoneyLib.DealWithTime(v.value, 4)) or (Stat == 'CashEarnt' and MoneyLib.HandleMoney(v.value)) or MoneyLib.DealWithPoints(v.value)
		fr:WaitForChild('Info'):WaitForChild('Rank').Text = "#" .. position
		
		fr.Info.Avatar.Image = plrImage
				
		fr.Position = UDim2.new(0.025, 0, 0.01 * (i -1), 0)
		fr.Visible = true

		fr.Parent = page		
		task.wait()
	end
	
	--[[
	for _, storeFront in game.Workspace:WaitForChild('Protected'):GetChildren() do
		if storeFront.Name == 'StoreFront' and storeFront:FindFirstChild('Leaderboards') then
			if storeFront:FindFirstChild('Leaderboards'):FindFirstChild(Stat) then
				local oldPage = storeFront:FindFirstChild('Leaderboards'):WaitForChild(Stat):WaitForChild("Screen"):WaitForChild("SurfaceGui"):WaitForChild('Leaderboard')
				oldPage:Destroy()
				page:Clone().Parent = storeFront:FindFirstChild('Leaderboards'):WaitForChild(Stat):WaitForChild("Screen"):WaitForChild("SurfaceGui")
			end
		end
	end
	]]
end

function LoadLeaderboards(fast)
	for i,v  in pairs(availableLeaderboards) do
		spawn(function()
			UpdateShow(v)
		end)
		wait(fast and 2 or 20)
	end
end

function LoadEverything()	
	LoadStores()
	
	spawn(function()
		wait(15)
		LoadLeaderboards(true)
		while true do
			wait(240)
			LoadLeaderboards()
		end
	end)
	
	UpdateLoop()
	while true do
		wait(60)
		UpdateLoop()
	end
end

function leaderboards.UpdatePlayerStats(Player)
	local UserId = Player.UserId
	for i,v in pairs(playerSaveData[Player.Name]) do
		leaderboards.OverwritePlayerStat(UserId, i, v)
	end
end

function UpdateLoop()
	for i,v in pairs(game.Players:GetPlayers()) do
		if v then
			if v.Parent then
				leaderboards.UpdatePlayerStats(v)
				wait(1)
			end
		end
	end
end

local randomUsernames = {13863572, 332519884, 27471521, 158437113, 852450543,
10656296, 4246419, 77010127, 235195722, 91522,
182667763}
function WriteValues(Store, minval, maxval)
	for i,v in pairs(randomUsernames) do
		local success, err = pcall(function()
			Store:SetAsync(tostring(v), math.random(minval, maxval))
		end)
		if not success then
			print("Something went wrong:",err)
		end
	end
end

function writeTestData()
	if not writeFakeData then return end
	
	local storeName = GetStoreName("Replays")
	local Store = DSS:GetOrderedDataStore(storeName)
	WriteValues(Store, 1, 15)
	
	--[[
	local storeName = GetStoreName("ReplaysW")
	local Store = DSS:GetOrderedDataStore(storeName)
	WriteValues(Store, 100, 15000)
	
	
	
	local storeName = GetStoreName("Replays24")
	local Store = DSS:GetOrderedDataStore(storeName)
	WriteValues(Store, 5, 100)
	
	local storeName = GetStoreName("Crates")
	local Store = DSS:GetOrderedDataStore(storeName)
	WriteValues(Store, 5, 100)
	
	local storeName = GetStoreName("KO24")
	local utc = timeh.GetUTC(KO24TimeOffset) / KO24Days
	local today = timeh.GetDate(utc)
	storeName = storeName.."-"..today
	local Store = DSS:GetOrderedDataStore(storeName)
	WriteValues(Store, 5, 100)
	
	print("TODAY'S DATA:", today)
	
	local storeName = GetStoreName("KO24")
	local utc = timeh.GetUTC(KO24TimeOffset) / KO24Days
	local yesterday = timeh.GetDate(utc, - 60 * 60 * 24)
	storeName = storeName.."-"..yesterday
	local Store = DSS:GetOrderedDataStore(storeName)
	WriteValues(Store, 5, 100)
	
	print("YESTERDAY'S DATA:", today)]]
end

function leaderboards.TrackPlayerData(Player, DataName, Value)
	local newTrack = {}
	newTrack.Uploaded = false
	newTrack.Value = math.round(Value)
	if not playerSaveData[Player.Name] or not table.find(availableStores, DataName) then return end
	playerSaveData[Player.Name][DataName] = newTrack
end

function leaderboards.OverwritePlayerStat(UserId, Stat, Item)
	if Item.Uploaded then return true end
	local currentStore = WaitLeaderboardReady(Stat)
	
	local success, err = pcall(function()
		currentStore:SetAsync(tostring(UserId), Item.Value)
	end)
	
	if not success then
		print("Err OverwritePlayerStat:", err)
	else
		Item.Uploaded = true
	end
	return success, err
end

function leaderboards.PlayerRemoving(LeavingPlayer)
	local UserID = LeavingPlayer.UserId
	local PName = LeavingPlayer.Name
	
	spawn(function()
		leaderboards.UpdatePlayerStats(LeavingPlayer)
		if not game.Players:FindFirstChild(PName) then
			playerSaveData[PName] = nil
		end
	end)
end

function leaderboards.PlayerAdded(NewPlayer)
	local PName = NewPlayer.Name
	playerSaveData[PName] = {}
end

writeTestData()
spawn(LoadEverything)


return leaderboards