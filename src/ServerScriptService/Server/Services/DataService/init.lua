local ServerScriptService = game:GetService('ServerScriptService')
local ServerStorage = game:GetService('ServerStorage')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local TweenService = game:GetService('TweenService')
local CollectionService = game:GetService('CollectionService')
local RunService = game:GetService('RunService')
local Players = game:GetService('Players')

local Packages = ReplicatedStorage:WaitForChild('Packages')

local Knit = require(Packages:WaitForChild('Knit'))
local Component = require(Packages:WaitForChild('Component'))
local TableUtil = require(Packages:WaitForChild('TableUtil'))
local Trove = require(Packages:WaitForChild('Trove'))
local Promise = require(Packages:WaitForChild('Promise'))
local Signal = require(Packages:WaitForChild('Signal'))

local Server = ServerScriptService:WaitForChild('Server')
local Modules = Server:WaitForChild('Modules')
local Components = Server:WaitForChild('Components')

local Semaphore = require(script:WaitForChild('Semaphore'))

local ProfileService = require(Modules:WaitForChild('ProfileService'))
local ProfileTemplate = require(ReplicatedStorage:WaitForChild('ProfileTemplate'))

local DataService = Knit.CreateService {
	Name = "DataService",
	Client = {	
		DataLoaded = Knit.CreateSignal(),
		PropertyChanged = Knit.CreateSignal(),
		ShowUpdateLog = Knit.CreateSignal()
	}
}

DataService.Profiles = {}
DataService.DataLoaded = Signal.new()

local ProfileStore = ProfileService.GetProfileStore(
	"TestData0006",
	ProfileTemplate
)

-- PRIVATE FUNCTIONS

local function PlayerAdded(player: Player, profiles)
	local profile = ProfileStore:LoadProfileAsync("Player_" .. player.UserId)
	if profile ~= nil then
		profile:AddUserId(player.UserId) -- GDPR compliance
		profile:Reconcile() -- Fill in missing variables from ProfileTemplate (optional)
		
		profile:ListenToRelease(function()
			profiles[player] = nil
			-- The profile could've been loaded on another Roblox server:
			player:Kick()
		end)
		if player:IsDescendantOf(Players) == true then
			profiles[player] = profile
						
			DataService.DataLoaded:Fire(player, profile.Data)
			DataService.Client.DataLoaded:Fire(player, profile.Data)
			
			-- A profile has been successfully loaded:
		else
			-- Player left before the profile loaded:
			profile:Release()
		end
	else
		-- The profile couldn't be loaded possibly due to other
		--   Roblox servers trying to load this profile at the same time:
		player:Kick() 
	end
	
	print(profiles)
end

function DataService:GetProfileData(player)
	if not self.Profiles[player] then return end
	return self.Profiles[player].Data
end

-- PUBLIC FUNCTIONS --
function DataService:Get(player, attribute)
	local profile = self:GetProfileData(player)
	if not profile then return end
	if not attribute then return profile end
	
	if profile[attribute] == nil then warn('No attribute named '..attribute..' exists in data file for Player '..player.Name..'!') return end
	
	return profile[attribute]
end

function DataService:Update(player, attribute, callback)
	local profile = self:GetProfileData(player)
	if not profile then return Promise.resolve() end
	
	return Promise.new(function(resolve)
		
		self._semaphores[player]:acquire()
		
		local old = self:Get(player, attribute)
		local new = callback(old)
		profile[attribute] = new
		
		self._semaphores[player]:release()
		
		self.Client.PropertyChanged:Fire(player, attribute, new)
		resolve(profile)
	end)
end

-- INITIALISATION & CONNECTIONS --
function DataService:KnitInit()
	self._semaphores = {}
end


function DataService:KnitStart()
	-- Incase Players have joined the server earlier than this script ran:
	for _, player in Players:GetPlayers() do
		task.spawn(PlayerAdded, player, self.Profiles)
	end
	
	-- New player joins
	Players.PlayerAdded:Connect(function(player)
		self._semaphores[player] = Semaphore.new()
		PlayerAdded(player, self.Profiles)
	end)
	
	-- Player leaves
	Players.PlayerRemoving:Connect(function(player)
		local profile = self.Profiles[player]
		if profile ~= nil then
			profile:Release()
		end
		if self._semaphores[player]   then
			self._semaphores[player]  = nil
		end
	end)
	
	_G.DataService = self
end

return DataService