--[[ Services ]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

--[[ Modules ]]
local playerModule = require(ServerScriptService.ServerModule.playerModule)
local barrierModule = require(ServerScriptService.ServerModule.barrierModule)
local bridgeModule = require(ServerScriptService.ServerModule.bridgeModule)
local checkpointModule = require(ServerScriptService.ServerModule.checkpointModule)

--// Framework
local Framework = require(ReplicatedStorage.Shared.Framework)
local print, pcall = Framework.log, Framework.pcall

--[[ Vars ]]

local winPartTrigger = workspace.BridgeEnd.winTrigger

local inRound = false
local roundTimer = 0
local roundCount = 1

local allPlayers: {Player} = {}
local winners: {Player} = {}
local isWinable = false

--[[ Functions ]]

--// Add/Remove player from allPlayers table
function assignPlayer(plr: Player, add: boolean)
	local inTable = Framework.inTable(allPlayers, plr.Name)
	
	if add and not inTable then
		table.insert(allPlayers, plr.Name)
	elseif not add and inTable then
		Framework.rmvTable(allPlayers, plr.Name)
	end
end

--//TODO Game related

function winPartHit(hit: BasePart)
	if not inRound or not isWinable then return end

	local winner = hit.Parent.Name

	if Players:FindFirstChild(winner) and not Framework.inTable(winners, winner) then
		table.insert(winners, winner)
		print(winner.. ' has reached the end.')

		roundCount = roundCount*2
		if #winners >= #allPlayers then
			inRound = false
		end
	end 
end

function startRoundTimer()

	--// Start the round
	inRound = true 
	isWinable = true

	--// Countdown
	task.spawn(function()
		while inRound and roundTimer > 0 do
			roundTimer -= roundCount
			task.wait(1)
			print('timer: '..roundTimer)
		end

		gameOver()
	end)
end

function gameStart()
	
	--// System preparation

	roundCount = 1
	roundTimer = 300
	
	--// Intermission
	local countdownEvent: BindableEvent = barrierModule.bCountdown(20, 'Intermission:')
	countdownEvent.Event:Once(startRoundTimer)
	
	--// Generation
	bridgeModule.generateBridges()
	checkpointModule.renewCheckpoints()
	
end

function gameOver()
	
	--// Disconnect
	roundCount = 0
	isWinable = false
	inRound = false
	
	table.clear(winners)
	
	--// Reset system and clean up
	Framework.dumpConnection()
	
	checkpointModule.resetPlayerCPoint(nil, true)
	playerModule.resetPlayer(nil, true)
	
	barrierModule.bToggle(true)
	bridgeModule.clearBridges()
	
	gameStart()
end

--//TODO Player connections
function onJoined(plr: Player)
	assignPlayer(plr, true)
	checkpointModule.registryCPoint(plr)

	plr.CharacterAdded:Connect(function()
		checkpointModule.playerRespawn(plr)
	end)
end

function onLeave(plr: Player)
	assignPlayer(plr, false)
end

--[[ Connection ]]
Players.PlayerAdded:Connect(onJoined)
winPartTrigger.Touched:Connect(winPartHit)

gameStart()
