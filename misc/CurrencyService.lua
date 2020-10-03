local ReplicatedStorage = game:GetService("ReplicatedStorage")
local require = require(ReplicatedStorage:WaitForChild("Nevermore"))

local Players = game:GetService("Players")

local DataStore2 = require("DataStore2")
local CurrencyEvent = require("GetRemoteEvent")("Currency")
local CurrencyFunction = require("GetRemoteFunction")("Currency")

local OldDS = game:GetService('DataStoreService'):GetDataStore('KL_DEC_1')

local Currency = {}

DataStore2.Combine("DATA", "ringgit")

function Currency.Debit(player, amount, note)
	local rmStore = DataStore2("ringgit", player)
	if amount >= 0 then
		if rmStore:Get(1000) then
			rmStore:Increment(amount)
			print(player.Name.." has been successfully debited RM"..amount.."!")
			if note then
				print(note)
			end
			return true, rmStore:Get(1000)
		end
	end
	return false
end

function Currency.Transaction(player, amount, note)
	local rmStore = DataStore2("ringgit", player)
	if amount >= 0 then
		if rmStore:Get(1000) >= amount then
			rmStore:Increment(-amount)
			print(player.Name.." has made a successful transaction of RM"..amount.."!")
			if note then
				print(note)
			end
			return true, rmStore:Get(1000)
		end
	end
	return false, amount - rmStore:Get(1000)
end

local function LoadPlayerData(player)
	local rmStore = DataStore2("ringgit", player)
	
	local StoredValue = rmStore:Get()
	
	if not StoredValue then
		local uniquekey = 'id-'..player.userId
		local GetSaved = OldDS:GetAsync(uniquekey)
		if GetSaved then
			if GetSaved[1] then
				rmStore:Set(GetSaved[1])
				OldDS:SetAsync(uniquekey, false)
			end
		end
	end
	
	local function callRemote(value)
		print("Updated datastore value!")
		CurrencyEvent:FireClient(player, value)
    end
	
    callRemote(rmStore:Get(1000))
    rmStore:OnUpdate(callRemote)
	
	local RegisteredVehicleStorage = Instance.new("Folder")
	RegisteredVehicleStorage.Name = "RegisteredVehicles"
	RegisteredVehicleStorage.Parent = player
	
	print("Loaded data for "..player.Name.." with RM"..rmStore:Get(1000))
end

CurrencyFunction.OnServerInvoke = function(player)
	local rmStore = DataStore2("ringgit", player)
	return rmStore:Get(1000)
end

Players.PlayerAdded:Connect(LoadPlayerData)

for index, player in pairs (Players:GetPlayers()) do
	LoadPlayerData(player)
end

return Currency