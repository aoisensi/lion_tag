if LionTag == nil then
	LionTag = class({})
end

function Activate()
	GameRules.AddonTemplate = LionTag()
	GameRules.AddonTemplate:InitGameMode()
end

function LionTag:InitGameMode()
	self.Remaining = {}

	GameRules:SetSameHeroSelectionEnabled(true)

	local mode = GameRules:GetGameModeEntity()
	mode:SetFixedRespawnTime(15.0)
	mode:SetModifyExperienceFilter(Dynamic_Wrap(LionTag, "ModifyExperienceFilter"), self)
	mode:SetTopBarTeamValuesOverride(true)
	self.GameMode = mode

	ListenToGameEvent('npc_spawned', Dynamic_Wrap(LionTag, 'OnNPCSpawned'), self)
	ListenToGameEvent('dota_player_killed', Dynamic_Wrap(LionTag, 'OnPlayerKilled'), self)
	ListenToGameEvent('dota_player_pick_hero', Dynamic_Wrap(LionTag, 'OnGameStart'), self)

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
	hero:SetAbilityPoints(0)

	local dagon = CreateItem('item_dagon_5', nil, nil)
	local phase = CreateItem('item_phase_boots', nil, nil)
	local blink = CreateItem('item_blink', nil, nil)
	hero:AddItem(dagon)
	hero:AddItem(phase)
	hero:AddItem(blink)
end

function LionTag:OnPlayerKilled(keys)
	local team = PlayerResource:GetTeam(keys.PlayerID)
	if self.Remaining[team] == nil then
		return
	end
	self.Remaining[team] = self.Remaining[team] - 1
	self:UpdateTopBar()
	if self.Remaining[team] <= 0 then
		if team == DOTA_TEAM_GOODGUYS then
			team = DOTA_TEAM_BADGUYS
		elseif team == DOTA_TEAM_BADGUYS then
			team = DOTA_TEAM_GOODGUYS
		else
			team = DOTA_TEAM_NEUTRALS
		end
		GameRules:SetGameWinner(team)
	end
end

function LionTag:ModifyExperienceFilter(filterTable)
	filterTable["experience"] = 0
	return true
end

function LionTag:OnGameStart(keys)
	local goodLife = PlayerResource:GetPlayerCountForTeam(DOTA_TEAM_BADGUYS) * 10
	if goodLife == 0 then
		goodLife = 1
	end
	local badLife = PlayerResource:GetPlayerCountForTeam(DOTA_TEAM_GOODGUYS) * 10
	if badLife == 0 then
		badLife = 1
	end
	self.Remaining[DOTA_TEAM_GOODGUYS] = goodLife
	self.Remaining[DOTA_TEAM_BADGUYS] = badLife
	self:UpdateTopBar()
end

function LionTag:UpdateTopBar()
	print(self.Remaining[DOTA_TEAM_GOODGUYS])
	print(self.Remaining[DOTA_TEAM_BADGUYS])
	table.foreach(self.Remaining, 
		function(team, remain)
			self.GameMode:SetTopBarTeamValue(team, remain)
		end
	)
end