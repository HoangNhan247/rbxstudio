--!nonstrict
--[[ Services ]]
local MarketplaceService = game:GetService("MarketplaceService")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--[[ Vars ]]
local framework = {}
local connections = {}

local remoteStorage = ReplicatedStorage.Remote
--[[ Functions ]]

--//TODO System (Shared)
function framework.log(...)
	print('::Debug:: ', ...)
end

function framework.pLog(...)
	warn('::Pcall:: ', ...)
end

function framework.inTable(haystack: {any}, needle: any)
	return table.find(haystack, needle) ~= nil
end

function framework.rmvTable(haystack: {any}, needle: any)
	table.remove(haystack, table.find(haystack, needle))
end

function framework.pcall(func: (any))
	local success, result = pcall(function()
		func()
	end)

	if not success then
		framework.pLog(result)
	end

	return success, result
end

function framework.deepCopy(t: {any})
	local new = {}
	if t then
		for key, value in pairs(t) do
			new[key] = value
		end
	end
	
	return new
end

--//TODO Remote (Shared)
function framework.Fire(cmd: string, data: {any})
	local data = framework.deepCopy(data)
	data.cmd = cmd
	remoteStorage.plrRemote:FireServer(data)
end

function framework.Invoke(cmd: string, data: {any})
	local data = framework.deepCopy(data)
	data.cmd = cmd
	return remoteStorage.plrRFunc:InvokeServer(data)
end

function framework.remoteRegister(func: () -> ())
	return remoteStorage.plrRemote.OnClientEvent:Connect(func)
end

function framework.Callback(plr: Player, ...: {any})
	remoteStorage.plrRemote:FireClient(plr, ...)
end

--//TODO Connections (ServerOnly)
function framework.addConnectionDump(connection: RBXScriptConnection)
	table.insert(connections, connection)
end

function framework.removeConnectionDump(connection: RBXScriptConnection)
	table.remove(connections, table.find(connections, connection))
end

function framework.dumpConnection()
	for _, c: RBXScriptConnection in pairs(connections) do
		c:Disconnect()
	end
	table.clear(connections)
end

--//TODO Marketplace (Shared)
function framework:promptGamepass(player: Player, id: number)
	MarketplaceService:PromptGamePassPurchase(player, id)
end

function framework:promptDevProduct(player: Player, id: number)
	MarketplaceService:PromptProductPurchase(player, id)
end

--//TODO Sound (Shared)
function framework:play(catagory: string, name: string)
	ReplicatedStorage.SFX[catagory]:FindFirstChild(name):Play()
end

--//TODO Color (Shared)
function framework.cConvert(RGB: Color3)
	return Color3.fromRGB(RGB.R*255+.5, RGB.G*255+.5, RGB.B*255+.5)
end

return framework
