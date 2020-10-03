--// Utility module to get the Player instance from a BasePart

local module = {}

local players = game:GetService("Players")

local function RecursiveHumanoidSearch(part)
	local partParent = part.Parent
	if partParent == workspace then
		return false
	elseif partParent:IsA("Model") then
		local humanoid = partParent:FindFirstChild("Humanoid")
		if humanoid then
			return humanoid
		else
			RecursiveHumanoidSearch(part)
		end
	end
end

function module.GetPlayerFromPart(part)
	if part then
		local humanoid = RecursiveHumanoidSearch(part)
		if humanoid then
			local humParent = humanoid.Parent
			if humParent:IsA("Model") then
				local player = players:GetPlayerFromCharacter(humParent)
				if player then
					return player
				end
			end
		end
	end
	return false
end

function module.GetCharacterFromPart(part)
	local player = module.GetPlayerFromPart(part)
	if player then
		local character = player.Character
		if character then
			return character
		end
	end
	return false
end

return module