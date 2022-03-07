local MAX_ENTRIES = 100


local Leaderboard = {}
Leaderboard.__index = Leaderboard

--SERVICES--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local Knit = require(ReplicatedStorage.Knit)
local ProfileService = Knit.GetService("ProfileService")
local DatastoreService = game:GetService("DataStoreService")
--LOCALIZED VARIABLES--

local dataStores = {
	["Kills"] = DatastoreService:GetOrderedDataStore("Kills"),
	["Revives"] = DatastoreService:GetOrderedDataStore("Revives"),
	["Escapes"] = DatastoreService:GetOrderedDataStore("Escapes")
}

local insert = table.insert
local sort = table.sort
local format = string.format



--[[

USAGE:

Create a new leaderboard:
local myLeaderboard = Leaderboard.new(leaderboard_type : string(server or global), leaderboard_instance : instance(reference to the model))

Update the leaderboard:
myLeaderboard:Update()

]]



function Leaderboard.new(leaderboard_type, leaderboard_instance, sort_object)
	local self = {}
	
	self.instance = leaderboard_instance
	self.lb = leaderboard_type
	self.sort = sort_object
	self.cache = {}
	
	return setmetatable(self, Leaderboard)
end


--Return an array similar to the way ordered datastore does so we can handle data in the same update func

--[[


local returnData = {
	[1] = {key = "player1", value = 50},
	[2] = {key = "player2", value = 30}
}


]]
function Leaderboard:GetList()
	local list
	if self.lb == "Server" then
		
		local to_sort = {}
		
		for _, player in ipairs (Players:GetPlayers()) do
			local playerProfile = ProfileService:GetProfile(player)
			local sortingData = playerProfile.Progress[self.sort]
			assert(sortingData, format("There is not currently an existing stat named: %s", self.sort))

			insert(to_sort, {player.Name, sortingData})
		end
		
		sort(to_sort, function(a, b)
			return a[2] > b[2]
		end)
		
		local finalSort = {}
		
		for currIndex, sorted_value in ipairs (to_sort) do
			local newSort = {}
			newSort.key = sorted_value[1]
			newSort.value = sorted_value[2]
			finalSort[currIndex] = newSort
		end
		
		list = finalSort
		
	elseif self.lb == "Global" then
		
		local curr_pages = dataStores[self.sort]:GetSortedAsync(false, MAX_ENTRIES)
		list = curr_pages:GetCurrentPage()
		
	end
	
	return list
end


function Leaderboard:Update()
	local function cleanupLeaderboard()
		local leaderboardContainer = self.instance.BoardList.List.Container
		for _, object in ipairs (leaderboardContainer:GetChildren()) do
			if object:IsA("Frame") then
				object:Destroy()
			end
		end
	end
	
	cleanupLeaderboard()
	
	local sortedEntries = self:GetList()
	local template = ServerStorage.LeaderboardTemplate
	for _, entry in ipairs (sortedEntries) do
		local template_clone = template:Clone()
		template_clone.Username.Text = entry.key
		template_clone.Stat.Text = entry.value
		template_clone.Parent = self.instance.BoardList.List.Container
	end
end





return Leaderboard