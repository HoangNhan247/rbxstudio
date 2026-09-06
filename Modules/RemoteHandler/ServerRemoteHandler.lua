--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local module = { remoteIndex = {}, onCooldown = {}, Initalized = false }

local remoteIndex = module.remoteIndex

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
	if module.onCooldown[p.UserId][self._instance.Name] then
		print(p.Name, ' on cooldown')
	else
		task.spawn(function()
			module.onCooldown[p.UserId][self._instance.Name] = true
			task.wait(self._cooldown or 0)
			module.onCooldown[p.UserId][self._instance.Name] = nil
		end)
	end
	
	for _, connection in self._connections do
		local restrictionHit = false
		
		if connection._restrictions then
			for _, func in connection._restrictions do
				if not func(p, data) then
					warn("RH :: Restrictions validate failed", {self, p, data})
					restrictionHit = true
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

function remoteMeta:Invoke(p: Player, data: any)
	if module.onCooldown[p.UserId][self._instance.Name] then
		print(p.Name, ' on cooldown')
		return { Success = false, Result = 0 }
	else
		task.spawn(function()
			module.onCooldown[p.UserId][self._instance.Name] = true
			task.wait(self._cooldown or 0)
			module.onCooldown[p.UserId][self._instance.Name] = nil
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
		if ( remote:IsA("RemoteEvent") or remote:IsA('RemoteFunction') ) and not remoteIndex[remote.Name] then
			local newRemoteMeta = {}
			
			newRemoteMeta._instance = remote
			newRemoteMeta._id = 0
			
			setmetatable(newRemoteMeta, remoteMeta)
			remoteIndex[remote.Name] = newRemoteMeta
			
			if remote:IsA('RemoteEvent') then
				newRemoteMeta._connections = {}
				newRemoteMeta._signal = remote.OnServerEvent:Connect(function(p, data)
					module.onCooldown[p.UserId] = module.onCooldown[p.UserId] or {}
					newRemoteMeta:Fire(p, data)
				end)
			elseif remote:IsA('RemoteFunction') then
				newRemoteMeta._connection = nil
				newRemoteMeta._restrictions = {}
				
				remote.OnServerInvoke = function(p, data)
					module.onCooldown[p.UserId] = module.onCooldown[p.UserId] or {}
					return newRemoteMeta:Invoke(p, data)
				end
			end
			
			print('New remotte', newRemoteMeta)
		end
	end
	
	module.Initalized = true
end

function module.registerRemote(name: string, remoteType: "Event"|"Request", restrictions: {}?, cooldown: number?, func: (Player, any) -> ())
	repeat
		task.wait()
	until module.Initalized == true
	
	local remote = remoteIndex[name]
	
	if remoteType == 'Event' then
		return remote:registerEvent(func, restrictions, cooldown)
	elseif remoteType == 'Request' then
		return remote:registerRequest(func, restrictions, cooldown)
	else
		warn("RH :: '" .. remoteType .. "' is not a valid remote type.")
	end
end

return module
