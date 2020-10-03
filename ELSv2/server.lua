local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Nevermore"))

local ELSv2 = {}
ELSv2.__index = ELSv2

local RunService = game:GetService("RunService")
local Event = require("GetRemoteEvent")("ELSv2")

function ELSv2.new(Lightbar)
	local x = setmetatable({
		Lightbar = Lightbar,
		OnStatus = false,
		CurrentPattern = 0,
	}, ELSv2)
	
	game:GetService("Players").PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
		local checker = coroutine.wrap(function()
			x:UpdateStatus(player)
		end)
		checker()
		end)
	end)
	
	return x
end

function ELSv2:PlayPattern(patternNumber)
	assert(getmetatable(self) == ELSv2)
	self.CurrentPattern = patternNumber
	self.OnStatus = true
	Event:FireAllClients({{["Lightbar"] = self.Lightbar, ["Action"] = 1, ["Vars"] = patternNumber}})
end

function ELSv2:Stop()
	assert(getmetatable(self) == ELSv2)
	self.OnStatus = false
	Event:FireAllClients({{["Lightbar"] = self.Lightbar, ["Action"] = 2}})
end

function ELSv2:UpdateStatus(player)
	assert(getmetatable(self) == ELSv2)
	if self.OnStatus then
		if player then
			Event:FireClient(player, {{["Lightbar"] = self.Lightbar, ["Action"] = 1, ["Vars"] = self.CurrentPattern}})
			print("Ye1")
		else
			Event:FireAllClients({{["Lightbar"] = self.Lightbar, ["Action"] = 1, ["Vars"] = self.CurrentPattern}})
		end
	else
		if player then
			Event:FireClient(player, {{["Lightbar"] = self.Lightbar, ["Action"] = 2}})
			print("Ye2")
		else
			Event:FireAllClients({{["Lightbar"] = self.Lightbar, ["Action"] = 2}})
		end
	end
end

return ELSv2