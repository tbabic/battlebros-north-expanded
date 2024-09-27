this.wolfmaster_trait <- this.inherit("scripts/skills/traits/character_trait", {
	m = {},
	function create()
	{
		this.character_trait.create();
		this.m.ID = "trait.wolfmaster";
		this.m.Name = "Wolfmaster";
		this.m.Icon = "ui/traits/trait_icon_wolfmaster.png";
		this.m.Description = "This character has a trusted direwolf as a companion.";
		this.m.Type = this.m.Type;
		this.m.Titles = [];
		this.m.Excluded = [];
	}

	function getTooltip()
	{
		return [
			{
				id = 1,
				type = "title",
				text = this.getName()
			},
			{
				id = 2,
				type = "description",
				text = this.getDescription()
			},
			{
				id = 10,
				type = "text",
				icon = "ui/icons/special.png",
				text = "This character can equip and train a direwolf to use in battle."
			},
			{
				id = 11,
				type = "text",
				icon = "ui/icons/melee_skill.png",
				text = "While adjacent to his wolf, character gains [color=" + this.Const.UI.Color.PositiveValue + "]+5[/color] Melee Skill"
			},
			{
				id = 12,
				type = "text",
				icon = "ui/icons/melee_defense.png",
				text = "While adjacent to his wolf, character gains [color=" + this.Const.UI.Color.PositiveValue + "]+5[/color] Melee Defense"
			}
			{
				id = 13,
				type = "text",
				icon = "ui/icons/bravery.png",
				text = "While adjacent to his wolf, character gains [color=" + this.Const.UI.Color.PositiveValue + "]+5[/color] Resolve"
			}
			
		];
	}

	function onAdded()
	{
		local actor = this.getContainer().getActor();
		actor.getFlags().set("NorthExpansionWolfmaster", true);
	}
	
	function onRemoved()
	{
		local actor = this.getContainer().getActor();
		actor.getFlags().set("NorthExpansionWolfmaster", false);
		//TODO:
		//this.getContainer().removeByID("effects.wolfmaster");
	}
	
	function onCombatStarted()
	{
		//TODO: wolfmaster effect that gives both wolf and character the bonus to hit and defense
		//TODO: wolfrotation effect
		//this.getContainer().add(this.new("scripts/skills/effects/wolfmaster_effect"));
		
	}
	
	function checkConditions()
	{
		local actor = this.getContainer().getActor();
		if (!actor.isPlacedOnMap())
		{
			return false;
		}
		
		local accessory = actor.getItems().getItemAtSlot(this.Const.ItemSlot.Accessory);
		if (accessory == null || accessory.getID() != "accessory.direwolf")
		{
			return false;
		}
		if (!accessory.isUnleashed())
		{
			return false;
		}
		local ally = accessory.m.Entity;
		if (ally.m.IsDying || !ally.m.IsAlive) return false;
		
		local myTile = actor.getTile();
		local allyDistance = ally.getTile().getDistanceTo(myTile);
		logInfo("ally: " + ally.getName() + " dist:"  + allyDistance);
		ally.getSkills().update();
		if (ally.getSkills().hasSkill("effects.wolfmaster_bonus") && allyDistance == 1)
		{
			return true;
		}
		return false;
	}

	function processBonus( _properties )
	{
		if(this.checkConditions())
		{
			logInfo("wolfmaster active");
			_properties.MeleeSkill += 5;
			_properties.MeleeDefense += 5;
			_properties.Bravery +=5;
		}
		
	}

	function onUpdate( _properties )
	{
		this.processBonus(_properties);
	}

});

