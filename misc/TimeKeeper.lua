-- Tracks time spent in game

--// Dependencies
-- Requires Quenty's Nevermore Engine: https://github.com/Quenty/NevermoreEngine
-- Requires DataStore2
-- Requires TFM

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local require = require(ReplicatedStorage:WaitForChild("Nevermore"))
local Players = game:GetService("Players")

local TFM = require("TFM")
local DataStore2 = require("DataStore2")

local DSName = "SessionTimeKeeper"

local TimekeeperEvent = require("GetRemoteEvent")("Timekeeper")
local TimekeeperFunction = require("GetRemoteFunction")("Timekeeper")

local TimeCache = {}
local saving = {}
local TimeKeeper = {}

DataStore2.Combine("DATA", DSName)

function SessionBegin(player)
	player.AncestryChanged:Connect(function()
		if player:IsDescendantOf(game) then return end
		SessionEnd(player)
	end)
	TimeCache[tostring(player.UserId)] = {["StartMarker"] = os.time()}
	local timeStore = DataStore2(DSName, player)
	if timeStore then
		local cumulativeTime = timeStore:Get(0)
		if cumulativeTime then
			TimekeeperEvent:FireClient(player, cumulativeTime)
			print(player.Name.." has logged on! Cumulative playtime: "..TFM:Convert(cumulativeTime, "Short"))
		end
		timeStore:OnUpdate(function(value)
			print("Updated timestore value!")
			TimekeeperEvent:FireClient(player, value)
   		end)
	end
end

function SaveTime(player)
	if not saving[player.Name] then
		saving[player.Name] = true
		print("Saving time for " .. player.Name)
		local cache = TimeCache[tostring(player.UserId)]
		if cache then
			local logOnTime = cache["StartMarker"]
			local sessionTime = os.time() - logOnTime
			if sessionTime then
				local timeStore = DataStore2(DSName, player)
				if timeStore then
					timeStore:Increment(sessionTime, 0)
					cache["StartMarker"] = os.time()
				end
			end
		end
		saving[player.Name] = false
	end
end

function SessionEnd(player)
	if not saving[player.Name] then
		saving[player.Name] = true
		local logOnTime = TimeCache[tostring(player.UserId)]["StartMarker"]
		local sessionTime = os.time() - logOnTime
		if sessionTime then
			local timeStore = DataStore2(DSName, player)
			if timeStore then
				timeStore:Increment(sessionTime, 0)
				TimeCache[tostring(player.UserId)] = nil
				timeStore:Save()
			end
		end
		saving[player.Name] = false
	end
end

game:BindToClose(function()
	for index, player in pairs (Players:GetPlayers()) do
		SessionEnd(player)
	end
end)

Players.PlayerAdded:Connect(SessionBegin)
Players.PlayerRemoving:Connect(SessionEnd)

TimekeeperFunction.OnServerInvoke = function(player)
	local timeStore = DataStore2(DSName, player)
	local cumulativeTime = timeStore:Get(0)
	if cumulativeTime then
		return cumulativeTime
	end
	return false
end

coroutine.wrap(function()
	while true do
		for index, player in pairs (Players:GetPlayers()) do
			coroutine.wrap(function()
				SaveTime(player)
			end)()
		end
		wait(30)
	end
end)()

return TimeKeeper