SWEP.Base = 'weapon_tttbase'

SWEP.Spawnable = true
SWEP.AutoSpawnable = false
SWEP.AdminSpawnable = true

SWEP.HoldType = 'pistol'

SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false

if SERVER then
	AddCSLuaFile()

	resource.AddFile('materials/vgui/ttt/icon_holydeagle.vmt')
else
	hook.Add('Initialize', 'TTTInitGuardianDeagleLang', function()
		LANG.AddToLanguage('English', 'ttt2_weapon_holydeagle_desc', 'Shoot a player to make him holy, but be careful to shoot only innocent people.')
	end)

	SWEP.PrintName = 'Guardian Deagle'
	SWEP.Author = 'DegeneReaper'

	SWEP.Slot = 7

	SWEP.ViewModelFOV = 54
	SWEP.ViewModelFlip = false

	SWEP.Category = 'Deagle'
	SWEP.Icon = 'vgui/ttt/icon_holydeagle.vtf'
	SWEP.EquipMenuData = {
		type = 'item_weapon',
		desc = 'ttt2_weapon_holydeagle_desc'
	}
end

SWEP.AllowDrop = false
SWEP.notBuyable = true

-- dmg
SWEP.Primary.Delay = 1
SWEP.Primary.Recoil = 6
SWEP.Primary.Automatic = false
SWEP.Primary.NumShots = 1
SWEP.Primary.Cone = 0.00001
SWEP.Primary.Ammo = ''
SWEP.Primary.ClipSize = 1
SWEP.Primary.ClipMax = 1
SWEP.Primary.DefaultClip = 1

-- some other stuff
SWEP.InLoadoutFor = nil
SWEP.IsSilent = false
SWEP.NoSights = false
SWEP.UseHands = true
SWEP.Kind = WEAPON_EXTRA
SWEP.CanBuy = nil
SWEP.notBuyable = true
SWEP.LimitedStock = true
SWEP.globalLimited = true
SWEP.NoRandom = true

-- view / world
SWEP.ViewModel = 'models/weapons/cstrike/c_pist_deagle.mdl'
SWEP.WorldModel = 'models/weapons/w_pist_deagle.mdl'
SWEP.Weight = 5
SWEP.Primary.Sound = Sound('Weapon_Deagle.Single')

SWEP.IronSightsPos = Vector(-6.361, -3.701, 2.15)
SWEP.IronSightsAng = Vector(0, 0, 0)

function BuffTarget(att, path, dmginfo)
	local ent = path.Entity
	if not IsValid(ent) then return end
 
	if SERVER then
	   if ent:IsPlayer() then
			-- If in pre or post round, don't do anything
			if not GAMEMODE:AllowPVP() then return end

			ent:PrintMessage(HUD_PRINTCENTER, 'You have been granted protection by ' .. dmginfo:GetAttacker():Nick() .. '!')
	   end
	end
 end

function SWEP:ShootGuardianBuff()
	local cone = self.Primary.Cone
	local bullet = {}
	bullet.Num       = 1
	bullet.Src       = self.Owner:GetShootPos()
	bullet.Dir       = self.Owner:GetAimVector()
	bullet.Spread    = Vector( cone, cone, 0 )
	bullet.Tracer    = 1
	bullet.Force     = 2
	bullet.Damage    = self.Primary.Damage
	bullet.TracerName = self.Tracer
	bullet.Callback = BuffTarget
 
	self.Owner:FireBullets( bullet )
 end

function SWEP:PrimaryAttack()
	self:SetNextPrimaryFire( CurTime() + self.Primary.Delay )

   if not self:CanPrimaryAttack() then return end

   self:EmitSound( self.Primary.Sound )

   self:SendWeaponAnim( ACT_VM_PRIMARYATTACK )

   self:ShootGuardianBuff()

   self:TakePrimaryAmmo( 1 )

   if IsValid(self.Owner) then
      self.Owner:SetAnimation( PLAYER_ATTACK1 )

      self.Owner:ViewPunch( Angle( math.Rand(-0.2,-0.1) * self.Primary.Recoil, math.Rand(-0.1,0.1) *self.Primary.Recoil, 0 ) )
   end

   if ( (game.SinglePlayer() && SERVER) || CLIENT ) then
      self:SetNWFloat( "LastShootTime", CurTime() )
   end
end

if SERVER then
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
