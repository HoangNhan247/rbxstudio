--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local module = { remoteIndex = {} }

local remoteIndex = module.remoteIndex

local remoteMeta = {}
local connectionMeta = {}

remoteMeta.__index = remoteMeta
connectionMeta.__index = connectionMeta

--// Meta functions

function remoteMeta:Fire(data: any)	
	for _, connection in self._connections do
		if connection._restrictions then
			for _, func in connection._restrictions do
				if not func(data) then
					warn("RH :: Restrictions validate triggered", {self, data})
				end
			end
		end
				
		local success, err = pcall(function()
			connection._func(data)
		end)
		
		if not success then
			warn("RH :: Error while firing ", {self, connection, data})
		end
	end
end

function remoteMeta:Reset()
	self._connections = {}
	self._id = 0
	warn('RH :: ' .. self._instance.Name .. ' reseted.')
end

function remoteMeta:Destroy()
	remoteIndex[self._instance.Name] = nil
	
	self._connections = {}
	self._signal:Disconnect()
	self._signal = nil
	self._instance = nil
	self._id = nil
	self._cooldown = nil
	self._func = nil
	self._restrictions = nil
	
	warn('RH :: ' .. self._instance.Name .. ' destroyed.')
end

--// Module functions

function module.Init()
	assert(ReplicatedStorage.Remotes, "RH :: Remotes folder not found.")
	
	for _, remote in ReplicatedStorage.Remotes:GetDescendants() do
		if remote:IsA("RemoteEvent") then
			
			if remoteIndex[remote.Name] then
				warn('CRH :: Duplicated remote :: ', remote.Name)
				continue
			end
			
			local newRemoteMeta = {}
			
			newRemoteMeta._instance = remote
			newRemoteMeta._id = 0
			
			setmetatable(newRemoteMeta, remoteMeta)
			remoteIndex[remote.Name] = newRemoteMeta
			
			newRemoteMeta._connections = {}
			newRemoteMeta._signal = remote.OnClientEvent:Connect(function(data)
				newRemoteMeta:Fire(data)
			end)
			
			print('CRH :: New event', newRemoteMeta)
		end
	end
	
	module.Initalized = true
end

function module.registerEvent(name: string, restrictions: {}?, func: (Player, any) -> ())
	repeat
		task.wait()
	until module.Initalized == true
	
	local remote = remoteIndex[name]
	
	if remote then
		local newConnectionMeta = {}

		newConnectionMeta._func = func
		newConnectionMeta._id = remote._id
		newConnectionMeta._remote = remote._instance
		newConnectionMeta._restrictions = restrictions

		remote._id += 1
		remote._connections[tostring(newConnectionMeta._id)] = newConnectionMeta

		setmetatable(newConnectionMeta, connectionMeta)
		print('New event connection', newConnectionMeta)
		return newConnectionMeta
	end
end

--// Restrictions

module.Restrictions = {
	-- Only allows data with correct types
	typeChecking = function(t: {[string]: string})
		return function (p: Player, data: {any})
			for i, v in data do
				if not t[i] then
					warn('RR :: Unknown argument', i, t, data)
				elseif typeof(v) ~= t[i] then
					warn('RR :: Type checking failed', t, data)
					return false
				end
			end

			return true
		end
	end,

	-- Only allows RIGHT AMOUNT of data with correct types
	typeStrict = function(t: {[string]: string})
		return function (p: Player, data: {any})
			for i, v in data do
				if ( not t[i] ) or ( typeof(v) ~= t[i] ) then
					warn('RR :: Type stricted', t, data)
					return false
				end

				t[i] = nil
			end

			if t ~= {} then
				warn('RR :: Type missing', t, data)
				return false
			end

			return true
		end
	end,

	forceData = function(t: {[string]: string})
		return function (p: Player, data: {any})
			for i, v in t do
				if not data[i] or data[i] ~= t[i] then
					return false
				end
			end

			return true
		end
	end,
}

return module
