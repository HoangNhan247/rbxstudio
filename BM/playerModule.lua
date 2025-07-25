--[[ Services ]]
local Players = game:GetService("Players")

--[[ Vars ]]
local module = {}

--//TODO Reset all players character
function module.resetPlayer(plr: Player, forAll: boolean)
	if plr and not forAll then
		plr:LoadCharacter()
	elseif forAll then
		for _, plr in pairs(Players:GetPlayers()) do
			plr:LoadCharacter()
		end
	end
end

--//TODO Security
function module:kick(plr: Player, reason: string)
	if reason then
		plr:Kick([[
		
			You have been kicked from the game
			
			Reason: ]].. reason)
	else
		plr:Kick([[
		
			You have been kicked from the game
		
		]])
	end
end

return module
