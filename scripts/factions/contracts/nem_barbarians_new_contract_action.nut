this.nem_barbarians_new_contract_action <- this.inherit("scripts/factions/faction_action", {
	m = {
        ContractActions = [],
		Home = null
    },
	function create()
	{
		this.m.ID = "nem_barbarians_new_contract_action";
		this.m.Cooldown = this.World.getTime().SecondsPerDay * 5;
		this.m.IsStartingOnCooldown = false;
		this.m.IsSettlementsRequired = true;
		this.faction_action.create();
		
		foreach(a in this.availableActions())
		{
			local card = this.new(a);
			card.setFaction(this.m.Faction);
			this.m.ContractActions.push(card);
		}
	}
	
	function setHome( _home)
	{
		this.m.Home = _home;
		foreach(c in this.m.ContractActions)
		{
			c.setHome(_home);
		}
	}

	function onUpdate( _faction )
	{
		this.m.Score = 0;
		
		if (!this.World.Flags.get("NorthExpansionActive"))
		{
			return;
		}
		
		if (this.World.Flags.get("NorthExpansionCivilLevel") >= 3)
		{
			return;
		}

		foreach(contractAction in this.m.ContractActions)
		{
			contractAction.update();
			if (contractAction.getScore() > 0) {
				this.m.Score = 1;
			}
		}
		
	}

	function onClear()
	{
	}

	function onExecute( _faction )
	{
		local scores = [];
		foreach(contractAction in this.m.ContractActions)
		{
			scores.push(contractAction.getScore());
		}
		
		local i = ::NorthMod.Utils.scorePicker(scores);
		if (i == null) {
			return;
		}
		this.m.ContractActions[i].execute();
	}
	
	function availableActions() {
		return [
			//contracts to convert
			
			// "scripts/factions/contracts/free_greenskin_prisoners_action",
			// "scripts/factions/contracts/find_artifact_action",
			// "scripts/factions/contracts/root_out_undead_action",
			// "scripts/factions/contracts/privateering_action", //barbarianize
			// "scripts/factions/contracts/investigate_cemetery_action",
			
			//converted
			"scripts/factions/contracts/nem_raid_location_action",
			"scripts/factions/contracts/nem_barbarian_king_action",
			"scripts/factions/contracts/nem_drive_away_bandits_action", 
			"scripts/factions/contracts/nem_drive_away_barbarians_action",
			"scripts/factions/contracts/nem_hunting_alps_action",
			"scripts/factions/contracts/nem_hunting_hexen_action", 
			"scripts/factions/contracts/nem_hunting_lindwurms_action",
			"scripts/factions/contracts/nem_hunting_schrats_action", 
			"scripts/factions/contracts/nem_hunting_unholds_action", 
			"scripts/factions/contracts/nem_hunting_webknechts_action",
			"scripts/factions/contracts/nem_obtain_item_action",
			"scripts/factions/contracts/nem_raid_caravan_action",
			"scripts/factions/contracts/nem_return_item_action",
			"scripts/factions/contracts/nem_roaming_beasts_action",
			
	
			"scripts/factions/contracts/nem_defend_settlement_greenskins_action",
			"scripts/factions/contracts/nem_destroy_orc_camp_action",
			"scripts/factions/contracts/nem_destroy_goblin_camp_action",
			"scripts/factions/contracts/nem_confront_warlord_action",
			"scripts/factions/contracts/nem_defend_settlement_bandits_action",
			
	
		];
	}

});
