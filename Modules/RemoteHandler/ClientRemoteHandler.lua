--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local module = { remoteIndex = {}, remoteConnections = {} }
local connectionMeta = {}

connectionMeta.__index = connectionMeta

--// Meta functions

function connectionMeta:Fire(data: {any})
	self._func(data)
end

function connectionMeta:Destroy()
	module.remoteConnections[self._key] = nil
end

--// Module functions

function module.Init()
	assert(ReplicatedStorage.Remotes, "RH :: Remotes folder not found.")

	for _, remote in ReplicatedStorage.Remotes:GetDescendants() do
		if remote:IsA("RemoteEvent") then
			if module.remoteIndex[remote.Name] then
				warn('CRH :: Duplicated remote :: ', remote.Name)
				continue
			end
			
			module.remoteConnections[remote.Name] = {}
			module.remoteIndex[remote.Name] = {
				_instance = remote,
				_signal = remote.OnClientEvent:Connect(function(data)
					for _, c in module.remoteConnections[remote.Name] do
						c:Fire(data)
					end
				end)
			}
		elseif remote:IsA("RemoteFunction") then
			if module.remoteIndex[remote.Name] then
				warn('CRH :: Duplicated remote :: ', remote.Name)
				continue
			end
			
			module.remoteConnections[remote.Name] = nil
			module.remoteIndex[remote.Name] = {_instance = remote}
			remote.OnClientInvoke = function(data)
				if module.remoteConnections[remote.Name] then
					module.remoteConnections[remote.Name](data)
				end
			end
		end
	end

	module.Initalized = true
end

function module.registerRemote(name: string, remoteType: "Event"|"Request", func: (any), key: string?): boolean
	repeat
		task.wait()
	until module.Initalized == true

	local remote = module.remoteIndex[name]
	if remote then
		if remote:IsA("RemoteEvent") then
			local newConnectionMeta = {}
			newConnectionMeta._key = key or HttpService:GenerateGUID(false)
			newConnectionMeta._func = func

			module.remoteConnections[name][newConnectionMeta._key] = newConnectionMeta

			setmetatable(newConnectionMeta, connectionMeta)
			print('CRH :: New event connection', newConnectionMeta)
			
			return newConnectionMeta
		elseif remote:IsA("RemoteFunction") then
			local newConnectionMeta = {}
			newConnectionMeta._func = func
			
			if module.remoteConnections[name] then
				warn('CRH :: Connection overlapped', name)
			end
				
			module.remoteConnections[name] = newConnectionMeta

			setmetatable(newConnectionMeta, connectionMeta)
			print('CRH :: New request connection', newConnectionMeta)

			return newConnectionMeta
		end
	else
		warn('CRH :: Remote not found', name)
		return nil
	end
end

function module.FireServer(name: string, data: {any}?)
	repeat
		task.wait()
	until module.Initalized == true

	local remote = module.remoteIndex[name]
	if remote and remote:IsA("RemoteEvent") then
		remote:FireServer(data)
	else
		warn('CRH :: Remote not found', name)
	end
end

function module.InvokeServer(name: string, data: {any}?): {any}
	repeat
		task.wait()
	until module.Initalized == true
	
	local remote = module.remoteIndex[name]
	if remote and remote:IsA("RemoteFunction") then
		return remote:InvokeServer(data)
	else
		warn('CRH :: Remote not found', name)
		return nil
	end
end

return module
