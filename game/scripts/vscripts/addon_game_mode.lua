if LionTag == nil then
	LionTag = class({})
end

function Activate()
	GameRules.AddonTemplate = LionTag()
	GameRules.AddonTemplate:InitGameMode()
end

function LionTag:InitGameMode()
	ListenToGameEvent('npc_spawned', Dynamic_Wrap(LionTag, 'OnNPCSpawned'), self)
	ListenToGameEvent('dota_player_killed', Dynamic_Wrap(LionTag, 'OnPlayerKilled'), self)

	-- Remove Spawners
	local spawners = {
		'lane_top_goodguys_melee_spawner',
		'lane_bot_goodguys_melee_spawner',
		'lane_top_badguys_melee_spawner',
		'lane_bot_badguys_melee_spawner'
	}
	table.foreach(spawners,
		function(index, spawner)
			Entities:FindByName(nil, spawner):Kill()
		end
	)
end

function LionTag:OnNPCSpawned(keys)
	local npc = EntIndexToHScript(keys.entindex)

	if npc:IsRealHero() and npc.bFirstSpawned == nil then
		npc.bFirstSpawned = true
		LionTag:OnHeroInGame(npc)
	end
end

function LionTag:OnHeroInGame(hero)
	local dagon = CreateItem('item_dagon_5', nil, nil)
	local phase = CreateItem('item_phase_boots', nil, nil)
	local blink = CreateItem('item_blink', nil, nil)
	hero:AddItem(dagon)
	hero:AddItem(phase)
	hero:AddItem(blink)
end

function LionTag:OnPlayerKilled(keys)
	local team = PlayerResource:GetTeam(keys.PlayerID)
	print(GetTeamHeroKills(DOTA_TEAM_GOODGUYS))
	print(GetTeamHeroKills(DOTA_TEAM_BADGUYS))
	if team == DOTA_TEAM_GOODGUYS then
		team = DOTA_TEAM_BADGUYS
	elseif team == DOTA_TEAM_BADGUYS then
		team = DOTA_TEAM_GOODGUYS
	else
		return
	end
	local kills = GetTeamHeroKills(team)
	if kills >= 49 then
		GameRules:SetGameWinner(team)
	end
end
