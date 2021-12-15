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

	-- Negate damage when protected to the Guardian
	hook.Add('PlayerTakeDamage', 'TTT2GuardianSacrificeHealth', function(ent, inflictor, attacker, amount, dmginfo)
		if ent:IsPlayer()
		and ent:IsValid()
		and ent:Alive()
		and ent:GetNWEntity('ttt2_guardian_protector') ~= NULL	-- If not NULL (fallback value if not set with SetNWEntity)
		and ent:GetNWFloat('ttt2_guardian_health_bonus') > 0	-- If the player still has their health bonus
		then
			local healthBonus = ent:GetNWFloat('ttt2_guardian_health_bonus')
			local dmgDiff = healthBonus - amount

			-- Set the remaining health bonus
			ent:SetNWFloat('ttt2_guardian_health_bonus', dmgDiff)

			-- If there is no remaining bonus health left, remove the Guardian's protection
			if dmgDiff <= 0 then
				-- Do the remaining damage after the health bonus is gone
				dmginfo:SetDamage(math.abs(dmgDiff))

				-- Do damage to the Guardian up until the health bonus is gone
				-- If bonus reaches 0 or less, whatever healthBonus that the player had is the only amount of damage we want to do to the Guardian
				-- Example: 50 healthBonus - 60 dmg = -10 dmgDiff, but we ignore all damage to the Guardian after the healthBonus reaches 0
				ent:GetNWEntity('ttt2_guardian_protector'):TakeDamage(healthBonus * 0.75)

				-- Remove the Guardian's Protection
				ent:SetNWEntity('ttt2_guardian_protector', NULL)
				ent:SetNWFloat('ttt2_guardian_health_bonus', 0.0)
			else
				-- Do no damage if there is still some health bonus left
				dmginfo:SetDamage(0)

				-- Deal the damage to the Guardian instead of the player
				ent:GetNWEntity('ttt2_guardian_protector'):TakeDamage(amount * 0.75)
			end
		end
	end)

	-- Handle Guardian Deagle hitting target
	hook.Add('ScalePlayerDamage', 'TTT2GuardianDeagleHit', function(ply, hitgroup, dmginfo)
		local attacker = dmginfo:GetAttacker()

		-- Validations
		if GetRoundState() ~= ROUND_ACTIVE or not attacker or not IsValid(attacker)
			or not attacker:IsPlayer() or not IsValid(attacker:GetActiveWeapon()) then return end

		-- Only execute if hitting player
		if not ply or not ply:IsPlayer() then return end

		local weap = attacker:GetActiveWeapon()

		-- No damage if using Guardian Deagle and add protection to the hit player
		if weap:GetClass() == 'weapon_ttt_guardian_deagle' then
			ply:SetNWEntity('ttt2_guardian_protector', attacker)
			ply:SetNWFloat('ttt2_guardian_health_bonus', 100.0)

			attacker:PrintMessage(HUD_PRINTTALK, '[Guardian] - You are now protecting ' .. ply:Nick())

			dmginfo:SetDamage(0)
			return true
		else return
		end
	end)
end
