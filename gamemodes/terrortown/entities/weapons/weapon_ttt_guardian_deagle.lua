SWEP.Base = 'weapon_tttbase'

SWEP.Spawnable = true
SWEP.AutoSpawnable = false
SWEP.AdminSpawnable = true

SWEP.HoldType = 'pistol'

SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false

if SERVER then
	AddCSLuaFile()
else
	SWEP.PrintName = 'Guardian Deagle'
	SWEP.Author = 'DegeneReaper'

	SWEP.Slot = 7

	SWEP.ViewModelFOV = 54
	SWEP.ViewModelFlip = false

	SWEP.Category = 'Deagle'
	SWEP.Icon = 'vgui/ttt/icon_deagle.vtf'
	SWEP.EquipMenuData = {
		type = 'item_weapon',
		desc = 'Shoot a player to grant them protection at the cost of your own health.'
	}
end

SWEP.AllowDrop = false
SWEP.notBuyable = true

-- dmg
SWEP.Primary.Damage = 0
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

local function RechargeShot(swep)
	if not swep or not IsValid(swep) then return end
	swep:SetClip1(1)
end

function SWEP:OnDrop()
	self:Remove()
end

-- function SWEP:ShootGuardianBuff()
-- 	local cone = self.Primary.Cone
-- 	local bullet = {}
-- 	bullet.Num       = 1
-- 	bullet.Src       = self.Owner:GetShootPos()
-- 	bullet.Dir       = self.Owner:GetAimVector()
-- 	bullet.Spread    = Vector( cone, cone, 0 )
-- 	bullet.Tracer    = 1
-- 	bullet.Force     = 2
-- 	bullet.Damage    = self.Primary.Damage
-- 	bullet.TracerName = self.Tracer
-- 	bullet.Callback = BuffTarget
 
-- 	self.Owner:FireBullets( bullet )
--  end

function SWEP:PrimaryAttack()
	-- Set up to refill ammo if you miss a target
	if (self:Clip1() > 0) then
		timer.Create('TTT2GuardianDeagleRecharge', 1, 1, function()
			if not self:GetNWBool('ttt2_guardian_deagle_recharge') then
				RechargeShot(self)
			end
		end)
	end

	local BaseClass = baseclass.Get(self.Base)
	BaseClass.PrimaryAttack(self)
end

if SERVER then
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
		if weap:GetClass() == 'weapon_ttt_guardian_deagle'
		and ply:GetBaseRole() ~= ROLE_DETECTIVE	-- Prevent protection from affecting the Detective
		then
			weap:SetNWBool('ttt2_guardian_deagle_recharge', true)
			local healthBonus = GetConVar('ttt_guardian_health_bonus'):GetInt()

			ply:SetNWEntity('ttt2_guardian_protector', attacker)
			ply:SetNWFloat('ttt2_guardian_health_bonus', healthBonus)

			ply:SetHealth(ply:Health() + healthBonus)
			ply:SetMaxHealth(ply:GetMaxHealth() + healthBonus)

			attacker:PrintMessage(HUD_PRINTTALK, '[Guardian] - You are now protecting ' .. ply:Nick())

			dmginfo:SetDamage(0)
			return true
		else return
		end
	end)
end