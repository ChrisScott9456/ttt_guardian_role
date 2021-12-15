if SERVER then
	AddCSLuaFile()
	resource.AddFile("materials/vgui/ttt/dynamic/roles/icon_guard.vmt")
end

function ROLE:PreInitialize()
	self.color = Color(151, 252, 237, 255)

	self.abbr = "guard"
	self.survivebonus = 1                   	-- points for surviving longer
	self.preventFindCredits = true	        	-- can't take credits from bodies
	self.preventKillCredits = true          	-- does not get awarded credits for kills
	self.preventWin = false                  	-- can win
	self.score.killsMultiplier = 2          	-- gets points for killing enemies of their team
	self.score.teamKillsMultiplier = -8     	-- loses points for killing teammates

	self.defaultTeam = TEAM_INNOCENT 			-- starts on Innocent Team
	self.defaultEquipment = SPECIAL_EQUIPMENT

	self.conVarData = {
		pct = 0.17, 							-- necessary: percentage of getting this role selected (per player)
		maximum = 1, 							-- maximum amount of roles in a round
		minPlayers = 6, 						-- minimum amount of players until this role is able to get selected
		credits = 0, 							-- the starting credits of a specific role
		togglable = true, 						-- option to toggle a role for a client if possible (F1 menu)
		random = 20,							-- what percentage chance the role will show up each round
		shopFallback = SHOP_DISABLED			-- the fallback shop for the role to use
	}
end

function ROLE:Initialize()
	roles.SetBaseRole(self, ROLE_INNOCENT)
end

if SERVER then
	-- Give Loadout on respawn and rolechange
	function ROLE:GiveRoleLoadout(ply, isRoleChange)
		ply:GiveEquipmentWeapon("weapon_ttt_guardian_deagle")
	end

	-- Remove Loadout on death and rolechange
	function ROLE:RemoveRoleLoadout(ply, isRoleChange)
		ply:StripWeapon("weapon_ttt_guardian_deagle")
	end

	
	
	-- -- Set the killer's entity on the victim for the Avenger to target
	-- hook.Add('TTT2PostPlayerDeath', 'TTT2AvengerSetCorpseKiller', function(victim, _, attacker)
	-- 	victim:SetNWEntity('ttt2_avenger_killer', attacker)
	-- end)

	-- -- Give the Avenger their target
	-- hook.Add('TTTCanSearchCorpse', 'TTT2AvengerCorpseTarget', function(idPlayer, rag, isCovert, isLongRange)
	-- 	local victim = player.GetBySteamID64(rag.sid64)
	-- 	local killer = victim:GetNWEntity('ttt2_avenger_killer')

	-- 	-- If the identifying player is an Avenger, give them a target
	-- 	if idPlayer:GetSubRole() == ROLE_AVENGER
	-- 	and not idPlayer:GetNWBool('ttt2_avenger_converted') then -- If the Avenger hasn't been converted yet
	-- 		if victim ~= killer 				-- Cannot be a suicide
	-- 		and IsValid(killer)					-- Killer must be valid
	-- 		and killer:Alive() 					-- Target must be alive
	-- 		and idPlayer ~= killer 				-- Target can't be the Avenger
	-- 		and victim:GetTeam() ~= TEAM_NONE 	-- Target should not be of TEAM_NONE, otherwise the Avenger won't convert to anything
	-- 		then
	-- 			idPlayer:PrintMessage(HUD_PRINTTALK, '[Avenger] - Target acquired: ' .. killer:GetName())

	-- 			-- Set the Avenger's team to convert to and target
	-- 			idPlayer:SetNWEntity('ttt2_avenger_convert_team', victim:GetTeam())
	-- 			idPlayer:SetNWEntity('ttt2_avenger_target', killer)
	-- 		else
	-- 			idPlayer:PrintMessage(HUD_PRINTTALK, '[Avenger] - Cannot avenge this victim')
	-- 		end
			
	-- 		return true
	-- 	end
	-- end)

	-- -- If the Avenger's target dies, remove the target and convert if the Avenger was the killer
	-- hook.Add('TTT2PostPlayerDeath', 'TTT2AvengerConvertTeam', function(victim, _, attacker)
	-- 	local avenger = GetAvengerByTarget(victim)

	-- 	-- If the victim was the target of an Avenger
	-- 	if avenger != nil then
	-- 		-- Remove the Avenger's target if they die
	-- 		avenger:SetNWEntity('ttt2_avenger_target', nil)

	-- 		-- If the player that killed the victim was the Avenger, convert team to person being avenged
	-- 		if attacker == avenger then
	-- 			avenger:SetNWBool('ttt2_avenger_converted', true)
	-- 			avenger:UpdateTeam(avenger:GetNWEntity('ttt2_avenger_convert_team'))
	-- 			avenger:RemoveEquipmentItem("item_ttt_radar") -- Remove death radar
	-- 		end

	-- 	else return
	-- 	end
	-- end)
end
