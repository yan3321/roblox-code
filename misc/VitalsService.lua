-- WIP service to handle player "vitals"

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Nevermore"))

local VitalsService = {}
VitalsService.__index = VitalsService

local VitalsEvent = require("GetRemoteEvent")("Vitals")

local VitalsData = {}

local function Update()
	for i,v in pairs (VitalsData) do
		print(v.Vitals.Temperature)
	end
	VitalsEvent:FireAllClients(VitalsData)
end

function VitalsService.new(player)
	local VitalsTable = {
		Temperature = 36.1,
		theVirus = false,
		Sicknesses = {},
		Symptoms = {},
	}
	return setmetatable({
		["Player"] = player,
		["Vitals"] = VitalsTable,
	}, VitalsService)
end

function VitalsService:GetVitalsData()
	return self
end

function VitalsService:Setup(player)
	local key = tostring(player.UserId)
	local playerVitals = VitalsData[key]
	
	if not playerVitals then
		VitalsData[key] = VitalsService.new(player)
		playerVitals = VitalsData[key]
		for i,v in pairs (playerVitals) do
			print(i, v)
		end
	else
		playerVitals["Player"] = player
	end
	
	return VitalsData[key]
end

function VitalsService:ChangeTemperature(temperature)
	local Vitals = self.Vitals
	print(Vitals.Temperature)
	self.Vitals.Temperature = temperature
	print(Vitals.Temperature)
	print(self.Player.Name)
	Update()
end

function GetPlayerVitalData(player)
	
end

game:GetService("Players").PlayerAdded:Connect(function(player)
	local playerVitals = VitalsService:Setup(player)
	player.CharacterAdded:Connect(function(character)
		for i,v in pairs (playerVitals.Vitals) do
			print(i, v)
		end
	end)
	Update()
end)

local cwrap = coroutine.wrap(function()
	wait(5)
	for i,v in pairs (VitalsData) do
		v:ChangeTemperature(37)
		print("Changed temp")
	end
end)

cwrap()

return VitalsService