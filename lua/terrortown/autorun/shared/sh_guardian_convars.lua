CreateConVar("ttt_guardian_health_bonus", 100, {FCVAR_NOTIFY, FCVAR_ARCHIVE})
CreateConVar('ttt_guardian_dmg_percentage', 100, {FCVAR_NOTIFY, FCVAR_ARCHIVE})

hook.Add("TTTUlxDynamicRCVars", "ttt2_ulx_dynamic_guardian_convars", function(tbl)
	tbl[ROLE_GUARDIAN] = tbl[ROLE_GUARDIAN] or {}

	table.insert(tbl[ROLE_GUARDIAN], {
		cvar = "ttt_guardian_health_bonus",
		slider = true,
		min = 0,
		max = 100,
		decimal = 0,
		desc = "ttt_guardian_health_bonus (def. 100)"
	})

	table.insert(tbl[ROLE_GUARDIAN], {
		cvar = "ttt_guardian_dmg_percentage",
		slider = true,
		min = 0,
		max = 100,
		decimal = 0,
		desc = "ttt_guardian_dmg_percentage (def. 100)"
	})
end)