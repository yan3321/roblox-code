-- Vehicle collisions

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Nevermore"))

local VehicleCollider = {}
VehicleCollider.__index = VehicleCollider

local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")

local CG_Player = "VehicleCollider_Player"
local CG_VehicleBody = "VehicleCollider_VehicleBody"
local CG_VehicleWheels = "VehicleCollider_VehicleWheels"

PhysicsService:CreateCollisionGroup(CG_Player)
PhysicsService:CreateCollisionGroup(CG_VehicleBody)
PhysicsService:CreateCollisionGroup(CG_VehicleWheels)

PhysicsService:CollisionGroupSetCollidable(CG_Player, CG_VehicleBody, false)
PhysicsService:CollisionGroupSetCollidable(CG_Player, CG_VehicleWheels, false)
PhysicsService:CollisionGroupSetCollidable(CG_VehicleBody, CG_VehicleWheels, false)


local function SetCollisionGroup(object, collisionGroupName)
	for _, ObjectDescendant in pairs (object:GetDescendants()) do
		if ObjectDescendant:IsA("BasePart") then
			PhysicsService:SetPartCollisionGroup(ObjectDescendant, collisionGroupName)
		end
	end
end

local function GetCrashSmoke(Vehicle)
	local CrashSmokes = {}
	for i,v in pairs (Vehicle:GetDescendants()) do
		if v:IsA("Smoke") and v.Name == "CrashSmoke" then
			table.insert(CrashSmokes, v)
		end
	end
	return CrashSmokes
end

local function UpdatePlayerCollision(player)
	local character = player.Character
	if character then
		SetCollisionGroup(character, CG_Player)
	end
end

local function UpdatePlayerCollisionGlobal()
	for index, player in pairs (Players:GetPlayers()) do
		UpdatePlayerCollision(player)
	end
end

function VehicleCollider.new(Vehicle)
	UpdatePlayerCollisionGlobal()
	return setmetatable({
		Vehicle = Vehicle,
		VehicleHealth = 100,
		processingHit = false,
		crashEnabled = false,
		crashConnections = {},
		crashSmokes = GetCrashSmoke(Vehicle),
	}, VehicleCollider)
end

function VehicleCollider:Setup(crashEnabled)
	local Vehicle = self.Vehicle
	local VehicleData = {}
	
	if crashEnabled then
		self.crashEnabled = true
		local vehicleDurabilityIntValue = Instance.new("IntValue")
		vehicleDurabilityIntValue.Name = "vehicleDurability"
		vehicleDurabilityIntValue.Value = self.VehicleHealth
		self.VehicleHealthObject = vehicleDurabilityIntValue
		vehicleDurabilityIntValue.Parent = Vehicle
	end
	
	for i,v in pairs (Vehicle:GetChildren()) do
		if v:IsA("Model") then
			local modelName = v.Name
			if modelName == "Body" then
				for _, BodyObjects in pairs (v:GetDescendants()) do
					if BodyObjects:IsA("BasePart") then
						PhysicsService:SetPartCollisionGroup(BodyObjects, CG_VehicleBody)
						if self.crashEnabled then
						local crashConnection = BodyObjects.Touched:Connect(function(hit)
						if BodyObjects:CanCollideWith(hit) and not self.processingHit and self.crashEnabled and self.VehicleHealth > 0 then
								self.processingHit = true
								local hitMagnitude = math.floor((BodyObjects.Velocity - hit.Velocity).Magnitude)
								if hitMagnitude > 10 then
									local healthBefore = self.VehicleHealth
									local healthAfter = healthBefore - hitMagnitude
									if healthAfter < 0 then
										healthAfter = 0
									end
									self.VehicleHealth = healthAfter
									self.VehicleHealthObject.Value = self.VehicleHealth
									if healthAfter == 0 then
										self:Crash()
									end
									print("Hit! Health before: "..healthBefore.." \n Health after: "..healthAfter)
								end
								wait(.2)
								self.processingHit = false
							end
						end)
						table.insert(self.crashConnections, crashConnection)
						end
					end
				end
			elseif modelName == "Wheels" then
				for _, WheelObjects in pairs (v:GetDescendants()) do
					if WheelObjects:IsA("BasePart") then
						PhysicsService:SetPartCollisionGroup(WheelObjects, CG_VehicleWheels)
					end
				end
			end
		end
	end
end

function VehicleCollider:Crash()
	pcall(function()
		for i,v in pairs (self.crashConnections) do
			v:Disconnect()
		end
	end)
	self.Vehicle.DriveSeat.Disabled = true
	for i,v in pairs (self.Vehicle.Body:GetDescendants()) do
		if v:IsA("BasePart") then
			v.CanCollide = false
		end
	end
	for i,v in pairs (self.crashSmokes) do
		v.Enabled = true
	end
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		SetCollisionGroup(character, CG_Player)
		character.DescendantAdded:Connect(function()
			SetCollisionGroup(character, CG_Player)
		end)
	end)
end)

return VehicleCollider