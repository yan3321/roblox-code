local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Nevermore"))

local ELSv2 = {}
ELSv2.__index = ELSv2

local RunService = game:GetService("RunService")
local patterns = require(script:WaitForChild("Patterns"))

local Event = require("GetRemoteEvent")("ELSv2")

local CachingTable = {}

local function GetLights(Lightbar)
	
	local frontLights = {}
	local rearLights = {}
	local finalTable = {}
	
	for i = 1, 8 do
		local lightpart = Lightbar:WaitForChild("Front"..tostring(i), 5)
		if lightpart then
			local spotlight = lightpart:WaitForChild("SpotLight", 5)
			if spotlight then
				table.insert(frontLights, {lightpart, spotlight})
			end
		end
	end
	
	for i = 8, 1, -1 do
		local lightpart = Lightbar:WaitForChild("Rear"..tostring(i), 5)
		if lightpart then
			local spotlight = lightpart:WaitForChild("SpotLight", 5)
			if spotlight then
				table.insert(rearLights, {lightpart, spotlight})
			end
		end
	end
	
	for i, v in pairs (frontLights) do
		table.insert(finalTable, {v, rearLights[i]})
	end
	
	return finalTable
end

local function ToggleLights(Lights, lightIndex, bool)
	
	local LightSpecific = Lights[lightIndex]
	
	local FrontLights = LightSpecific[1]
	local RearLights = LightSpecific[2]
	
	if bool then
		FrontLights[1].Transparency = 0
		FrontLights[2].Enabled = true
		RearLights[1].Transparency = 0
		RearLights[2].Enabled = true
	else
		FrontLights[1].Transparency = 1
		FrontLights[2].Enabled = false
		RearLights[1].Transparency = 1
		RearLights[2].Enabled = false
	end
	
end

local function Off(self)	
	if self.LoopRunning then
		self.StopNow = true
		self.BindableEvent.Event:Wait()
	end
	
	for i,v in pairs (self.Lights) do
		ToggleLights(self.Lights, i, false)
	end
	
	self.StopNow = false
end

local function LoopPattern(self, pattern)
	self.LoopRunning = true
	print("Loop started...")
	while true do
		if self.StopNow then break end
		for i,v in pairs (pattern) do
			if self.StopNow then break end
			local LightSequence = v.Pattern
			local Delay = v.Delay
			local DelayTimes = Delay/.05
			for LightNumber, LightOnOff in pairs (LightSequence) do
				if self.StopNow then break end
				ToggleLights(self.Lights, LightNumber, LightOnOff)
			end
			for i = 1, DelayTimes do
				if self.StopNow then break end
				wait(.05)
			end
		end
	end
	print("Loop ended or broken!")
	
	self.LoopRunning = false
	self.BindableEvent:Fire()
end

local function PlayPattern(self, patternNumber)
	print("Playing!!")
	local pattern = patterns[patternNumber]
	if pattern then
		Off(self)
		LoopPattern(self, pattern)
	end
end

function ELSv2.new(Lightbar)
	return setmetatable({
		Lightbar = Lightbar,
		Lights = GetLights(Lightbar),
		LoopRunning = false,
		StopNow = false,
		BindableEvent = Instance.new("BindableEvent")
	}, ELSv2)
end

function ELSv2:PlayPattern(patternNumber)
	assert(getmetatable(self) == ELSv2)
	PlayPattern(self, patternNumber)
end

function ELSv2:Stop()
	assert(getmetatable(self) == ELSv2)
	print("Turning off")
	Off(self)
end

local function GetHandler(ELSData)
	local ModelToCheck = ELSData.Lightbar
	if ModelToCheck ~= nil then
	for index, HandlerContainer in pairs (CachingTable) do
		if HandlerContainer then
			local Lightbar = HandlerContainer["Lightbar"]
			if Lightbar ~= nil then
				if Lightbar == ModelToCheck then
					return HandlerContainer["Handler"]
				end
			else
				table.remove(CachingTable, index)
			end
		end
	end
	local NewDataSet = {["Lightbar"] = ModelToCheck, ["Handler"] = ELSv2.new(ModelToCheck)}
	print("New record made")
	local index = #CachingTable + 1
	table.insert(CachingTable, NewDataSet)
	return CachingTable[index].Handler
	end
	return false
end

Event.OnClientEvent:Connect(function(ELSData)
	local process = coroutine.wrap(function()
		for i,v in pairs (ELSData) do
		if v and v ~= nil then
			local Handler = GetHandler(v)
			if Handler then
				local action = v.Action
				if action == 1 then
					Handler:PlayPattern(v.Vars)
				elseif action == 2 then
					Handler:Stop()
				end
			end
		end
	end
	end)
	process()
end)

return ELSv2