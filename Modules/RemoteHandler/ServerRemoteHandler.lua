--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local module = {}

local remoteFolderIndex = {}
local remoteIndex = {}

local onCooldown = {}
local onHold = {}
local Initialized = false

local remoteMeta = {}
local connectionMeta = {}

remoteMeta.__index = remoteMeta
connectionMeta.__index = connectionMeta

--// Meta functions

function remoteMeta:registerEvent(func: (Player, any) -> (), restrictions: {}?, cooldown: number?)
	if self._signal then
		local newConnectionMeta = {}

		newConnectionMeta._func = func
		newConnectionMeta._id = self._id
		newConnectionMeta._remote = self._instance
		newConnectionMeta._restrictions = restrictions

		self._id += 1
		self._connections[tostring(newConnectionMeta._id)] = newConnectionMeta

		setmetatable(newConnectionMeta, connectionMeta)
		print('New event connection', newConnectionMeta)
		return newConnectionMeta
	else
		warn("RH :: '" .. self._instance.Name .. "' is not a RemoteEvent.")
	end
end

function remoteMeta:registerRequest(func: (Player, any) -> (), restrictions: {}?, cooldown: number?)
	if not self._signal then
		
		if self._connection and func then
			warn('RH :: Connection overlapped', self, func)
		end
		
		self._connection = func
		self._restrictions = restrictions
		self._cooldown = cooldown
		
		print('new conection', self)
	else
		warn("RH :: '" .. self._instance.Name .. "' is not a RemoteFunction.")
	end
end

function remoteMeta:Fire(p: Player, data: any)
	if onCooldown[self._instance.Name][p.UserId] then
		print(p.Name, ' on cooldown')
	else
		task.spawn(function()
			onCooldown[self._instance.Name][p.UserId] = true
			task.wait(self._cooldown or 0)
			onCooldown[self._instance.Name][p.UserId] = nil
		end)
	end
	
	for _, connection in self._connections do
		local restrictionHit = false
		if connection._restrictions then
			for _, func in connection._restrictions do
				if not func(p, data) then
					warn("RH :: Restrictions validate failed", {self, p, data})
					restrictionHit = true
					break
				end
			end
		end
		
		if restrictionHit then
			continue
		end
		
		local success, err = pcall(function()
			connection._func(p, data)
		end)
		
		if not success then
			warn("RH :: Error while firing ", {self, connection, p, data})
		end
	end
end

function remoteMeta:holdFire(p: Player, data: any)
	if onHold[self._instance.Name][p.UserId] then
		print(p.Name, ' on fired')
	else
		onHold[self._instance.Name][p.UserId] = true
	end

	for _, connection in self._connections do
		local restrictionHit = false
		if connection._restrictions then
			for _, func in connection._restrictions do
				if not func(p, data) then
					warn("RH :: Restrictions validate failed", {self, p, data})
					restrictionHit = true
					break
				end
			end
		end

		if restrictionHit then
			continue
		end

		local success, err = pcall(function()
			connection._func(p, data)
		end)

		if not success then
			warn("RH :: Error while firing ", {self, connection, p, data})
		end
	end
	
	onHold[self._instance.Name][p.UserId] = nil
end

function remoteMeta:Invoke(p: Player, data: any)
	if onCooldown[self._instance.Name][p.UserId] then
		print(p.Name, ' on cooldown')
		return { Success = false, Result = 0 }
	else
		task.spawn(function()
			onCooldown[self._instance.Name][p.UserId] = true
			task.wait(self._cooldown or 0)
			onCooldown[self._instance.Name][p.UserId] = nil
		end)
	end
	
	if self._connection then
		if self._restrictions then
			for _, func in self._restrictions do
				if not func(p, data) then
					warn("RH :: Restrictions validate failed", {self, p, data})
					return { Success = false, Result = 0 }
				end
			end
		end
		
		local success, connectionSuccess, result = pcall(function()
			return self._connection(p, data)
		end)
		
		print(success, connectionSuccess, result)
		
		return { Success = ( success == true and connectionSuccess == true ), Result = result or 5 }
	end
end

function remoteMeta:Reset()
	if self._signal then
		self._connections = {}
		self._id = 0
		self._cooldown = 0
		warn('RH :: ' .. self._instance.Name .. ' reseted.')
	elseif self._connection then
		self._connection = nil
		self._cooldown = 0
		self._restrictions = {}
		warn('RH :: ' .. self._instance.Name .. ' reseted.')
	end
end

--// Module functions

function module.Init()
	assert(ReplicatedStorage.Remotes, "RH :: Remotes folder not found.")
	
	for _, remote in ReplicatedStorage.Remotes:GetDescendants() do
		if ( remote:IsA("RemoteEvent") or remote:IsA('RemoteFunction') or remote:IsA('UnreliableRemoteEvent') ) and not remoteIndex[remote.Name] then
			local newRemoteMeta = {}
			
			newRemoteMeta._instance = remote
			newRemoteMeta._id = 0
			
			setmetatable(newRemoteMeta, remoteMeta)
			remoteIndex[remote.Name] = newRemoteMeta
			remoteFolderIndex[remote.Name] = remote
			
			onCooldown[remote.Name] = {}
			onHold[remote.Name] = {}
			
			if ( remote:IsA('RemoteEvent') or remote:IsA('UnreliableRemoteEvent') ) then
				newRemoteMeta._connections = {}
				newRemoteMeta._onSignal = "Fire"
				newRemoteMeta._signal = remote.OnServerEvent:Connect(function(p, data)
					newRemoteMeta[newRemoteMeta._onSignal](newRemoteMeta, p, data)
				end)
			elseif remote:IsA('RemoteFunction') then
				newRemoteMeta._connection = nil
				newRemoteMeta._onSignal = "Invoke"
				newRemoteMeta._restrictions = {}
				
				remote.OnServerInvoke = function(p, data)
					return newRemoteMeta[newRemoteMeta._onSignal](newRemoteMeta, p, data)
				end
			end
			
			print('New remotte', newRemoteMeta)
		end
	end
	
	Initialized = true
end

function module.registerRemote(name: string, remoteType: "Event"|"Request", restrictions: {}?, cooldown: number?, func: (Player, any) -> ())
	repeat
		task.wait()
	until Initialized == true
	
	local remote = remoteIndex[name]
	
	if remoteType == 'Event' then
		return remote:registerEvent(func, restrictions, cooldown)
	elseif remoteType == 'Request' then
		return remote:registerRequest(func, restrictions, cooldown)
	else
		warn("RH :: '" .. remoteType .. "' is not a valid remote type.")
	end
end

function module.changeRemoteMethod(name: string, method: string)
	local remote = remoteIndex[name]
	if remote then
		remote._onSignal = method
		print("RH :: Changed " .. remote._instance.Name .. " method to " .. method)
	else
		warn('RH :: Invalid remote')
	end
end

function module.FireClient(remoteName: string, player: Player, data: any)
	if remoteFolderIndex[remoteName] then
		remoteFolderIndex[remoteName]:FireClient(player, data)
		print("RH :: Fired ", player, data)
	else
		warn("RH :: '" .. remoteName .. "' is not a valid remote name.")
	end
end

function module.FireAllClients(remoteName: string, data: any)
	if remoteFolderIndex[remoteName] then
		remoteFolderIndex[remoteName]:FireAllClients(data)
		print("RH :: Fired ", data)
	else
		warn("RH :: '" .. remoteName .. "' is not a valid remote name.")
	end
end

function module.FireClients(remoteName: string, players: {Player}, data: any)
	if remoteFolderIndex[remoteName] then
		for _, player in players do
			remoteFolderIndex[remoteName]:FireClient(player, data)
			print("RH :: Fired ", player, data)
		end
	else
		warn("RH :: '" .. remoteName .. "' is not a valid remote name.")
	end
end

function module.FireAllExcept(remoteName: string, player: Player, data: any)
	if remoteFolderIndex[remoteName] then
		for _, p in Players:GetPlayers() do
			if p ~= player then
				remoteFolderIndex[remoteName]:FireClient(p, data)
				print("RH :: Fired ", p, data)
			end
		end
	else
		warn("RH :: '" .. remoteName .. "' is not a valid remote name.")
	end
end

return module
