this.nem_destroy_goblin_camp_action <- this.inherit("scripts/factions/faction_action", {
	m = {
		Home = null
	},
	function create()
	{
		this.m.ID = "nem_destroy_goblin_camp_action";
		this.m.Cooldown = this.World.getTime().SecondsPerDay * 7;
		this.m.IsStartingOnCooldown = false;
		this.m.IsSettlementsRequired = true;
		this.faction_action.create();
	}
	function setHome( _home)
	{
		this.m.Home = _home;
	}

	function onUpdate( _faction )
	{
		if (!_faction.isReadyForContract())
		{
			return;
		}

		if (_faction.getPlayerRelation() <= 25)
		{
			return;
		}

		if (!this.World.Ambitions.getAmbition("ambition.make_nobles_aware").isDone())
		{
			return;
		}

		if (!this.World.FactionManager.isGreenskinInvasion() && this.Math.rand(1, 100) > 10)
		{
			return;
		}

		local settlements = _faction.getSettlements();
		local goblins = this.World.FactionManager.getFactionOfType(this.Const.FactionType.Goblins).getSettlements();
		local found = false;

		foreach( b in goblins )
		{
			if (b.isLocationType(this.Const.World.LocationType.Unique))
			{
				continue;
			}

			local d = this.m.Home.getTile().getDistanceTo(b.getTile());

			if (d <= 25)
			{
				found = true;
			}
		}
		

		if (!found)
		{
			return;
		}

		this.m.Score = 1;
	}

	function onClear()
	{
	}

	function onExecute( _faction )
	{
		local contract = this.new("scripts/contracts/contracts/nem_destroy_goblin_camp_contract");
		contract.setFaction(_faction.getID());
		contract.setHome(this.m.Home);
		contract.setEmployerID(this.m.Home.getChieftain());
		contract.setOrigin(this.m.Home);
		this.World.Contracts.addContract(contract);
	}

});

