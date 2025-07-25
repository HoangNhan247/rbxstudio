--[[ Services ]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

--//TODO Framework
local Framework = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Framework"))
local print = Framework.log
local pcall = Framework.pcall

--[[ Vars ]]
local checkpointModule = {}
checkpointModule.__index = checkpointModule

local checkpointIds: {BasePart} = {}
local playerCheckpoint: {string} = {}

--[[ Functions ]]
--//TODO Checkpoint related

function checkpointTouched(hit: BasePart, CPointNum: number)
	local player = Players:GetPlayerFromCharacter(hit.Parent)
	
	if player then
		checkpointModule.assignCPoint(player, CPointNum)
	end
end

--// Reset and assign new checkpoints
function checkpointModule.renewCheckpoints()
	table.clear(checkpointIds)
	
	local collectCheckpoints: {Instance} = CollectionService:GetTagged('Checkpoint')
	
	if #collectCheckpoints > 0 then
		pcall(function()
			for _, checkpoint: Model in pairs(collectCheckpoints) do

			--[[
				CheckpointModelName = CheckpointId
				CheckpointSpawnPartName : "Spawn"
			]]

				local spawnPart: BasePart = checkpoint:FindFirstChild('Spawn')
				local id: number? = tonumber(checkpoint.Name)

				if spawnPart and id then
					checkpointIds[id] = spawnPart
					Framework.addConnectionDump(
						spawnPart.Touched:Connect(function(hit: BasePart)
							checkpointTouched(hit, id)
						end)
					)
				end
			end
		end)
	end
	
	print('Checkpoints renewed - Checkpoint assigned: '.. tostring(#checkpointIds))
end

--//TODO Player 

--// Reset player (All player) checkpoints
function checkpointModule.resetPlayerCPoint(plr: Player, forAll: boolean)
	if not forAll and plr then
		playerCheckpoint[plr.Name] = 0
	elseif forAll then
		for name, v in pairs(playerCheckpoint) do
			print(playerCheckpoint)
			if Players:FindFirstChild(name) then
				print(name..' checkpoint resetted')
				playerCheckpoint[name] = 0
			else
				playerCheckpoint[name] = nil
			end
		end
	end
end

--// Add checkpoint to player (All player)
function checkpointModule.registryCPoint(plr: Player, forAll: boolean)
	if not forAll and plr then
		playerCheckpoint[plr.Name] = 0
		
		print('Checkpoints registered for: '..plr.Name)
		
	elseif forAll then
		for _, plr in pairs(Players:GetPlayers()) do
			playerCheckpoint[plr.Name] = 0
		end
		
		print('Checkpoints registered for all')
	end
end

--// Change player checkpoint
function checkpointModule.assignCPoint(plr: Player, checkpointNum: number)
	local currentCPoint = playerCheckpoint[plr.Name]
	
	if currentCPoint and checkpointNum and currentCPoint < checkpointNum then
		playerCheckpoint[plr.Name] = checkpointNum
		print(plr.Name .. ' Reached checkpoint: '.. checkpointNum)
	end
end

function checkpointModule.playerRespawn(plr: Player)
	local playerId = playerCheckpoint[plr.Name]
	
	if playerId then
		local checkpoint: BasePart = checkpointIds[playerId]
		local char = plr.Character
		
		if checkpoint and char then
			print('Checkpoint detected, respawning...')
			
			local cPos = checkpoint.CFrame
			char:PivotTo(CFrame.new(cPos.X, cPos.Y + 3, cPos.Z))
		end
	end
end

return checkpointModule
