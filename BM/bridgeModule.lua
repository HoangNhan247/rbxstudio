--[[ Services ]]
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Framework
local Framework = require(ReplicatedStorage.Shared.Framework)
local log = Framework.log

--[[ Vars ]]

local bridgeModule = {}
local bridgeIds = {}

local serverBridge = ServerStorage.BridgeStorage
local gameBridge = workspace.BridgePart

local checkpoint = ServerStorage.Placeholder.Checkpoint
local bridgeStartCFrame = ServerStorage.Placeholder.BridgeStartEdge.CFrame

--[[ Functions ]]

--// Make sure bridge IDs exist
function check()
	if #bridgeIds > 0 then return end
	
	bridgeIds = {}

	for id, bridge in pairs(serverBridge:GetChildren()) do
		bridgeIds[id] = bridge
	end
end

--// Generate bridge seed
function generateSeed(amount: number)
	check()
	
	local seedPackage = {}
	for i = 1, amount do
		seedPackage[i] = math.random(1, #bridgeIds)
	end
	
	return seedPackage
end

--// Return bridge sizes
function sizeCalc(primaryPart: BasePart)
	return primaryPart.Size.X/2, primaryPart.Size.Y/2
end

--[[ Modules ]]

--// Clear all bridges
function bridgeModule.clearBridges()
	gameBridge:ClearAllChildren()
end

function bridgeModule.generateBridges(amount: number, CheckpointFrequency: number)
	--// Generating bridges / checkpoints / end - from seed
	amount = amount or 30
	CheckpointFrequency = CheckpointFrequency or 5
	
	local seed: {number} = generateSeed(amount)
	local checkpointNum = 1
	
	local currentX = bridgeStartCFrame.X
	local lastHalfWidth = 0

	for bridgeCount, id in pairs(seed) do
		Framework.pcall(function()
			local bridge: Model = bridgeIds[id]:Clone()
			local primary = bridge.PrimaryPart

			if primary then
				local halfWidth, halfHeight = sizeCalc(primary)
				currentX += lastHalfWidth + halfWidth

				bridge:PivotTo(CFrame.new(currentX, bridgeStartCFrame.Y - halfHeight, bridgeStartCFrame.Z))
				bridge.Parent = gameBridge

				lastHalfWidth = halfWidth
			end
		end)
		
		if bridgeCount % CheckpointFrequency == 0 then
			Framework.pcall(function()
				local newCheckpoint = checkpoint:Clone()
				local primary = newCheckpoint.PrimaryPart

				if primary then
					local halfWidth, halfHeight = sizeCalc(primary)
					currentX += lastHalfWidth + halfWidth

					newCheckpoint:PivotTo(CFrame.new(currentX, bridgeStartCFrame.Y - halfHeight, bridgeStartCFrame.Z))
					newCheckpoint.Name = checkpointNum
					newCheckpoint.Parent = gameBridge
					newCheckpoint:AddTag('Checkpoint')
					
					checkpointNum += 1
					lastHalfWidth = halfWidth
				end
			end)
		end
	end
end

return bridgeModule
