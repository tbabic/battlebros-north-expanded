this.nem_defend_settlement_barbarians_contract <- this.inherit("scripts/contracts/barbarian_contract", {
	m = {
		Reward = 0,
		Kidnapper = null
	},
	function create()
	{
		this.contract.create();
		this.m.Type = "contract.nem_defend_settlement_barbarians";
		this.m.Name = "Defend Settlement";
		this.m.TimeOut = this.Time.getVirtualTimeF() + this.World.getTime().SecondsPerDay * 5.0;
		this.m.MakeAllSpawnsResetOrdersOnContractEnd = false;
		this.m.MakeAllSpawnsAttackableByAIOnceDiscovered = true;
	}

	function onImportIntro()
	{
		this.importSettlementIntro();
	}

	function start()
	{
		this.m.Payment.Pool = 700 * this.getPaymentMult() * this.Math.pow(this.getDifficultyMult(), this.Const.World.Assets.ContractRewardPOW) * this.getReputationToPaymentMult();

		if (this.Math.rand(1, 100) <= 33)
		{
			this.m.Payment.Completion = 0.75;
			this.m.Payment.Advance = 0.25;
		}
		else
		{
			this.m.Payment.Completion = 1.0;
		}

		this.contract.start();
	}

	function createStates()
	{
		this.m.States.push({
			ID = "Offer",
			function start()
			{
				this.Contract.m.BulletpointsObjectives = [
					"Defend %townname% from raiding parties"
				];

				if (this.Math.rand(1, 100) <= this.Const.Contracts.Settings.IntroChance)
				{
					this.Contract.setScreen("Intro");
				}
				else
				{
					this.Contract.setScreen("Task");
				}
			}

			function end()
			{
				this.World.Assets.addMoney(this.Contract.m.Payment.getInAdvance());
				this.Contract.addGuests();
				local r = this.Math.rand(1, 100);

				if (r <= 20)
				{
					this.Flags.set("IsKidnapping", true);
				}
				else if (r <= 40)
				{
					if (this.Contract.getDifficultyMult() >= 0.95)
					{
						this.Flags.set("IsMilitia", true);
					}
				}
				

				local number = 1;

				if (this.Contract.getDifficultyMult() >= 0.95)
				{
					number = number + this.Math.rand(0, 1);
				}

				if (this.Contract.getDifficultyMult() >= 1.1)
				{
					number = number + 1;
				}

			

				for( local i = 0; i != number; i = ++i )
				{
					local nearest = ::NorthMod.Utils.nearestBarbarianNeighbour(this.m.Home);
					local nearest_base = nearest.settlement;
					local party = f.spawnEntity(nearest_base.getTile(), "Raiders", false, this.Const.World.Spawn.Barbarians, this.Math.rand(80, 110) * this.Contract.getDifficultyMult() * this.Contract.getScaledDifficultyMult());				
					this.Contract.m.UnitsSpawned.push(party.getID());

					party.setAttackableByAI(false);
					local c = party.getController();
					c.getBehavior(this.Const.World.AI.Behavior.ID.Attack).setEnabled(false);
					c.getBehavior(this.Const.World.AI.Behavior.ID.Flee).setEnabled(false);
					local t = this.Math.rand(0, targets.len() - 1);

					if (i > 0)
					{
						local wait = this.new("scripts/ai/world/orders/wait_order");
						wait.setTime(4.0 * i);
						c.addOrder(wait);
					}

					local move = this.new("scripts/ai/world/orders/move_order");
					move.setDestination(this.Contract.m.Home.getTile());
					c.addOrder(move);
					local raid = this.new("scripts/ai/world/orders/nem_raid_order");
					raid.setTime(40.0);
					raid.setTargetLocation(this.Contract.m.Home);
					c.addOrder(raid);
				}

				this.Contract.m.Home.setLastSpawnTimeToNow();
				this.Contract.setScreen("Overview");
				this.World.Contracts.setActiveContract(this.Contract);
			}

		});
		this.m.States.push({
			ID = "Running",
			function start()
			{
				this.Contract.m.Home.getSprite("selection").Visible = true;
				this.World.FactionManager.getFaction(this.Contract.getFaction()).setActive(false);
			}

			function update()
			{
				if (this.Flags.get("IsMilitia") && !this.Flags.get("IsMilitiaDialogShown"))
				{
					this.Flags.set("IsMilitiaDialogShown", true);
					this.Contract.setScreen("Militia1");
					this.World.Contracts.showActiveContract();
				}
				
				if (this.Contract.m.UnitsSpawned.len() > 0 && this.Flags.get("IsEnemyHereDialogShown"))
				{
					foreach( id in this.Contract.m.UnitsSpawned )
					{
						local p = this.World.getEntityByID(id);
						if (p != null && p.isAlive() && !p.getController().hasOrders())
						{
							this.Flags.set("IsRaided", true);
							break;
						}
					}
				}
				
				if (this.Contract.m.UnitsSpawned.len() == 0)
				{
					if (this.Flags.get("HadCombat"))
					{
						this.Contract.setScreen("ItsOver");
						this.World.Contracts.showActiveContract();
					}
					else 
					{
						this.Contract.setScreen("ItsOverDidNothing");
						this.World.Contracts.showActiveContract();
					}
					this.Contract.setState("Return");
					return;
				}
				
				if (this.Contract.m.UnitsSpawned.len() > 0 && !this.Flags.get("IsEnemyHereDialogShown"))
				{
					local isEnemyHere = false;

					foreach( id in this.Contract.m.UnitsSpawned )
					{
						local p = this.World.getEntityByID(id);

						if (p != null && p.isAlive() && p.getDistanceTo(this.Contract.m.Home) <= 700.0)
						{
							isEnemyHere = true;
							break;
						}
					}
					
					if (isEnemyHere)
					{
						this.Flags.set("IsEnemyHereDialogShown", true);
						this.Contract.setScreen("DefaultAttack");
						this.World.Contracts.showActiveContract();
					}
					return;
				}
				
				
				
				if (this.Contract.m.UnitsSpawned.len() == 1 && this.Flags.get("IsKidnapping") && !this.Flags.get("IsKidnappingInProgress") && this.Flags.get("IsRaided"))
				{
					local p = this.World.getEntityByID(this.Contract.m.UnitsSpawned[0]);

					if (p != null && p.isAlive() && !p.isHiddenToPlayer() && !p.getController().hasOrders())
					{
						local c = p.getController();
						c.getBehavior(this.Const.World.AI.Behavior.ID.Attack).setEnabled(true);
						c.getBehavior(this.Const.World.AI.Behavior.ID.Flee).setEnabled(true);
						this.Contract.m.Kidnapper = this.WeakTableRef(p);
						this.Flags.set("IsKidnappingInProgress", true);
						this.Flags.set("KidnappingTooLate", this.Time.getVirtualTimeF() + 60.0);
						this.Contract.setScreen("Kidnapping1");
						this.World.Contracts.showActiveContract();
						this.Contract.setState("Kidnapping");
					}
				}
				
				
			}

			function onRetreatedFromCombat( _combatID )
			{
				this.Flags.set("HadCombat", true);
			}

			function onCombatVictory( _combatID )
			{
				this.Flags.set("HadCombat", true);
			}

		});
		this.m.States.push({
			ID = "Kidnapping",
			function start()
			{
				this.Contract.m.BulletpointsObjectives = [
					"Rescue prisoners being hauled away",
					"Return to " + this.Contract.m.Home.getName()
				];
				this.Contract.m.Home.getSprite("selection").Visible = false;
				this.World.FactionManager.getFaction(this.Contract.getFaction()).setActive(false);

				if (this.Contract.m.Kidnapper != null && !this.Contract.m.Kidnapper.isNull())
				{
					this.Contract.m.Kidnapper.getSprite("selection").Visible = true;
				}
			}

			function update()
			{
				if (this.Contract.m.Kidnapper == null || this.Contract.m.Kidnapper.isNull() || !this.Contract.m.Kidnapper.isAlive())
				{
					if (this.Time.getVirtualTimeF() - this.World.Events.getLastBattleTime() <= 5.0)
					{
						this.Flags.set("IsKidnapping", false);
						this.Contract.setScreen("Kidnapping2");
					}
					else
					{
						this.Contract.setScreen("Kidnapping3");
					}

					this.World.Contracts.showActiveContract();
					this.Contract.setState("Return");
				}
				else if (this.Contract.m.Kidnapper.isHiddenToPlayer() && this.Time.getVirtualTimeF() > this.Flags.get("KidnappingTooLate"))
				{
					this.Contract.setScreen("Kidnapping3");
					this.World.Contracts.showActiveContract();
					this.Contract.setState("Return");
				}
			}

			function onRetreatedFromCombat( _combatID )
			{
				this.Flags.set("HadCombat", true);
			}

			function onCombatVictory( _combatID )
			{
				this.Flags.set("HadCombat", true);
			}

		});
		this.m.States.push({
			ID = "Return",
			function start()
			{
				this.Contract.m.BulletpointsObjectives = [
					"Return to " + this.Contract.m.Home.getName()
				];
				this.Contract.m.Home.getSprite("selection").Visible = true;
				this.World.FactionManager.getFaction(this.Contract.getFaction()).setActive(true);

				if (this.Contract.m.Kidnapper != null && !this.Contract.m.Kidnapper.isNull())
				{
					this.Contract.m.Kidnapper.getSprite("selection").Visible = false;
				}
			}

			function update()
			{
				if (this.Contract.isPlayerAt(this.Contract.m.Home))
				{
					
					
					if (this.Flags.get("IsKidnapping") && this.Flags.get("IsKidnappingInProgress"))
					{
						this.Contract.setScreen("Failure2");
					}
					else if (this.Flags.get("IsKidnappingInProgress"))
					{
						this.Contract.setScreen("Failure1");
					}
					else if(this.Flags.get("IsRaided"))
					{
						this.Contract.setScreen("Failure1");
					}
					else
					{
						this.Contract.setScreen("Success1");
					}
					
					this.World.Contracts.showActiveContract();
				}
			}

		});
	}

	function createScreens()
	{
		this.importScreens(::NorthMod.Const.Contracts.NegotiationDefault);
		this.importScreens(::NorthMod.Const.Contracts.Overview);
		this.m.Screens.push({
			ID = "Task",
			Title = "Negotiations",
			ext = "[img]gfx/ui/events/event_20.png[/img]{%employer%\'s looking out the window. He waves you to join him.%SPEECH_ON%Look at those people.%SPEECH_OFF%There\'s a throng of people below, wailing about this or that.%SPEECH_ON%Raiders have been roaming these parts for awhile now and people believe that they are about to attack us in great numbers.%SPEECH_OFF%The man throws the curtains closed and goes to light a candle. He speaks over it, his breath flicking the flame.%SPEECH_ON%We need you to protect us, warrior. If you can stop these raiders, you\'ll be paid handsomely. Are you interested?%SPEECH_OFF% | A few clansmen are roaming outside the halls of the room. You can hear their shouting and it is of a nervous tone. %employer% pours a drink and sips it with a shaking hand.%SPEECH_ON%I\'ll just be clear with you, warrior. We have many, many reports that raiders are about to attack this camp. If you want to know, those reports came by way of dead women and children. Clearly, we\'ve no reason to doubt the seriousness of these reports. So, the question is, will you protect us?%SPEECH_OFF% | %employer%\'s looking at some papers on his desk. You take a seat and ask what it is he wants.%SPEECH_ON%Hello, warrior. We have a problem I think you will... excel at taking care of.%SPEECH_OFF%You ask him to be straight with you and he jumps right to the point.%SPEECH_ON%Raiders have burned down some jurts and hovels just outside camp. News is that they are preparing a much larger, gustier attack. I need you here to stop them. Do you think you can handle this task?%SPEECH_OFF% | %employer%\'s got two papers in hand. There are faces sketched onto them.%SPEECH_ON%We caught these two the other day. Hanged \'em, burned the remains.%SPEECH_OFF%You shrug.%SPEECH_ON%Congratulations?%SPEECH_OFF%The man is not very amused.%SPEECH_ON%Now we\'ve gotten word that their raider friends are coming to exact revenge on us! And, yes, we need your help to fight them off. Are you interested?%SPEECH_OFF% | You settle into %employer%\'s room, taking a seat, rubbing your hands along the wooden frame. It\'s a good oak. A once-tree worth sitting in.%SPEECH_ON%Glad you\'re comfortable, warrior, but I sure as hell ain\'t. We have many, many warnings that a large group of raiders are about to attack our camp. We\'re quite short on defense, but not short on crowns. Obviously, that\'s where you come in. Are you interested?%SPEECH_OFF% | %employer% slams a cup against the wall. It scatters, turning and pinwheeling, flecks of wine dotting your cheek.%SPEECH_ON%Vagabonds! Raiders! Marauders! It never ends!%SPEECH_OFF%He absently hands you a napkin.%SPEECH_ON%Now I\'m getting news that a large group of these thugs are coming to burn this camp to the ground! Well, I\'ve gotten something in store for them: you. What do you say, warrior? Will you defend us?%SPEECH_OFF% | A few grieving women can be hear wailing just outside %employer%\'s room. He turns to you.%SPEECH_ON%Hear that? That\'s what happens when raiders come here. They steal, they rape, and they murder.%SPEECH_OFF%You nod. It is, after all, the way of the raider.%SPEECH_ON%Now some folk in the hinterland say the thugs are preparing for a massive assault on our camp. You must do something to help us, warrior. Heh, of course I say \'must\'. What I really mean is that we\'ll pay you to help us...%SPEECH_OFF%}",
			Image = "",
			List = [],
			ShowEmployer = true,
			ShowDifficulty = true,
			Options = [
				{
					Text = "{What is %townname% prepared to pay for their safety? | This should be worth a good amount of crowns to you, right?}",
					function getResult()
					{
						return "Negotiation";
					}

				},
				{
					Text = "{I\'m afraid you\'re on your own. | We have more important matters to settle. | I wish you luck, but we\'ll not be part of this.}",
					function getResult()
					{
						if (this.Math.rand(1, 100) <= 60)
						{
							this.World.Contracts.removeContract(this.Contract);
							return 0;
						}
						else
						{
							return "Plea";
						}
					}

				}
			],
			function start()
			{
			}

		});
		this.m.Screens.push({
			ID = "Plea",
			Title = "Negotiations",
			Text = "[img]gfx/ui/events/event_43.png[/img]{When you leave %employer%, you come outside to find a woman standing there with a mob of her spawn running around and between her legs and a babe sucking her teat.%SPEECH_ON%Warrior, please, you mustn\'t leave us like this! This camp needs you! The children need you!%SPEECH_OFF%She pauses, then lowers the other side of her shirt, revealing a rather salacious and seductive temptation.%SPEECH_ON%I need you...%SPEECH_OFF%You hold a hand up, both to stop her and wipe your suddenly sweaty brow. Maybe helping this pair, uh, poor people out wouldn\'t be so bad after all? | Getting ready to leave %townname%, a small puppy runs up to you barking and licking your boots. An even smaller child is in chase, practically on the coattails of its literal tail. The kid falls to the mutt and wraps his arms around its nappy fur.%SPEECH_ON%Oh {Marley | Yeller | Jo-Jo}, I love you so much!%SPEECH_OFF%An image of raiders slaughtering the child and his pet runs across your mind. You\'ve better things to do than play saviour and protectos against common raiders, but the dog just keeps licking the boy\'s face and the kid just seems so happy.%SPEECH_ON%Haha! We\'re going to live forever and ever, aren\'t we? Forever and ever!%SPEECH_OFF%Goddammit. | A man walks up to you as you leave %employer%\'s abode.%SPEECH_ON%I heard you turn chieftain\'s offer down. It\'s a shame, that\'s all I wanted to say. I thought there were plenty of good men in this world, but I suppose I was wrong on that. Godspeed on your journey, and I do hope you pray for us in your travels.%SPEECH_OFF%}",Image = "",
			List = [],
			ShowEmployer = false,
			ShowDifficulty = true,
			Options = [
				{
					Text = "{Damn, we can\'t leave these people to die. | Fine, fine, we won\'t leave %townname%. Let\'s talk payment, at least.}",
					function getResult()
					{
						return "Negotiation";
					}

				},
				{
					Text = "{I\'m sure you\'ll pull through. Make way. | I won\'t risk the %companyname% to save some starved villagers.}",
					function getResult()
					{
						this.World.Contracts.removeContract(this.Contract);
						return 0;
					}

				}
			],
			function start()
			{
			}

		});
		this.m.Screens.push({
			ID = "DefaultAttack",
			Title = "Near %townname%",
			Text = "[img]gfx/ui/events/event_07.png[/img]The raiders are in sight! Prepare for battle and protect the camp!",
			Image = "",
			List = [],
			Options = [
				{
					Text = "To arms!",
					function getResult()
					{
						return 0;
					}

				}
			]
		});
		this.m.Screens.push({
			ID = "ItsOver",
			Title = "Near %townname%",
			Text = "[img]gfx/ui/events/event_22.png[/img]{The fighting is over and the men idle in a welcome respite. %employer% will be waiting for you back in camp. | With the battle over, you survey the corpses littered across the field. It is a gruesome sight, yet for some reason it spurs you with energy. The ghastly hills of dead only remind you of the vitality you\'ve yet to yield to this horrid world. People like %employer% should come and see it, but he won\'t, so you\'ll have to go and see him instead. | Flesh and bone scattered across the field, hardly discernible from one owner to the next. Black buzzards cycle overhead, halos of chevron shadows rippling over the dead, the birds waiting for the mourners to clear out. %randombrother% comes to your side and asks if they should start the return trip to %employer%. You leave the sight of the battlefield behind and nod. | A peaceful sort of ruin is made of the dead. Like it was their natural state, stiffened and at a permanent loss, and their whole living was but a fleeting fit of an accident finally come to an end. %randombrother% comes up and asks if you\'re alright. You\'re not sure, to be honest, and simply answer that it is time to go see %employer%. | Misshapen men and crooked corpses litter the ground for battle gives the dead no sovereignty over how one comes to a final rest. The bodiless heads look at most peace, for in battle no man or beast has time to truly hack a neck away, it only comes by the quickest and sharpest of blade swings. A part of you hopes to go with such instant finality, but another part hopes you get the chance to take your killer down with you.\n\n %randombrother% comes to your side and asks for orders. You turn away from the field and tell the %companyname% to get ready to return to %employer%.}",
			Image = "",
			List = [],
			Options = [
				{
					Text = "We head back to the %townname%!",
					function getResult()
					{
						return 0;
					}

				}
			]
		});
		this.m.Screens.push({
			ID = "ItsOverDidNothing",
			Title = "Near %townname%",
			Text = "[img]gfx/ui/events/event_30.png[/img]Smoke fills the air, smoke and the caustic smell of burning wood, burning livelihoods. %townname%\'s folk put all their hopes into hiring the %companyname%, a fatal mistake.",
			Image = "",
			List = [],
			Options = [
				{
					Text = "That didn\'t go as planned...",
					function getResult()
					{
						return 0;
					}

				}
			]
		});
		this.m.Screens.push({
			ID = "Militia1",
			Title = "At %townname%",
			Text = "[img]gfx/ui/events/event_80.png[/img]{While preparing to defend %townname%, the local clansmen have come to your side. They submit to your orders, only asking that you allow them to defend their home with your men. | It appears the local clansmen have joined the battle! A ragtag group of men, but they\'ll be useful nonetheless. | %townname%\'s clansmen have joined the fight! Although a shoddy band of poorly armed men, they are eager to defend home and hovel. They submit to your command, trusting that you will lead them to victory in battle. | You\'re not alone in this fight! %townname%\'s clansmen have joined you. They\'re eager to fight and ask to stand by your warriors in battle.}",
			Image = "",
			List = [],
			Options = [
				{
					Text = "Fall in line, you\'ll be under my command.",
					function getResult()
					{
						local roster = this.World.getGuestRoster();
						
						for( local i = 0; i < 4; i++ )
						{
							local militia = roster.create("scripts/entity/tactical/humans/barbarian_thrall_guest");
							militia.setFaction(1);
							militia.assignRandomEquipment();
						}
						
						this.Contract.positionGuests();
						
						return 0;
					}

				},
				{
					Text = "Go hide somewhere and stay out of our way.",
					function getResult()
					{
						return 0;
					}

				}
			]
		});
		this.m.Screens.push({
			ID = "MilitiaVolunteer",
			Title = "Near %townname%",
			Text = "[img]gfx/ui/events/event_80.png[/img]{The fighting over, one of the clansmen that helped in the defense comes to you personally, bending low and offering his sword.%SPEECH_ON%My time here is at an end. But the prowess of the %companyname% is truly an amazing sight. If you would permit it, chief, I would love to fight alongside you and your warriors.%SPEECH_OFF% }",
			Image = "",
			List = [],
			Options = [
				{
					Text = "Welcome to the %companyname%!",
					function getResult()
					{
						return 0;
					}

				},
				{
					Text = "This is no place for you.",
					function getResult()
					{
						return 0;
					}

				}
			]
		});
		this.m.Screens.push({
			ID = "Kidnapping1",
			Title = "Near %townname%",
			Text = "[img]gfx/ui/events/event_30.png[/img]{While keeping watch for the raiders, a clansman comes up telling you that a group of the thugs attacked nearby, taking off with a group of hostages. You shake your head in disbelief. How were they able to sneak in and do this? The layman shakes his head, too.%SPEECH_ON%I thought y\'all were supposed to help us. Why didn\'t you do anything?%SPEECH_OFF%You ask if the raiders have gone far. The clansman shakes his head. Looks like you still have a shot to get them back. | A man wearing rags and carrying a broken pitchfork sprints up to your men. He drops and wails at your feet.%SPEECH_ON%The raiders attacked! Where were you? They killed people... burned some... and... and they took some prisoner! Please, go save them!%SPEECH_OFF%You eye %randombrother% and nod.%SPEECH_ON%Get the men ready. We need to chase these thugs down before they escape entirely.%SPEECH_OFF% | You have your eyes peeled to the horizons, looking for any sight or sound of vagabond or vagathief. Suddenly, %randombrother% comes to you with a woman by his side. She tells a story that the raiders have already attacked, killing a great number of clansmen and those they didn\'t kill they made off with. The warrior nods.%SPEECH_ON%Looks like they snuck past us, chief.%SPEECH_OFF%You\'ve only one choice now - go get those people back! | Stationing yourself close to %townname%, you anticipate the raiders\' attack. You thought this would be easy, but the sudden arrival of a crazed layman says otherwise. The clansman explains that the marauders have already ambushed the outskirts. They slaughtered everyone they could, then made off with a few men, women, and children. The man, either drunk or in shock, slurs his pleas.%SPEECH_ON%Get... get them back, would ya?%SPEECH_OFF% | Keeping watch, a few angry clansmen take the roads, storming toward you in a swirl of mob anger.%SPEECH_ON%I thought we were paying you to protect us! Where were you!%SPEECH_OFF%They are covered in blood. Some are half-clothed. A woman hangs a breast, too angry to care about the indecency. You ask the group what it is they are talking about. A man, clutching a cane close to his chest, explains that the raiders and thugs had already attacked, taking to a nearby hamlet. They slaughtered everything in sight then, with their bloodlust satiated, took as many prisoners as they could.\n\nYou nod.%SPEECH_ON%We\'ll get them back.%SPEECH_OFF%}",
			Image = "",
			List = [],
			Options = [
				{
					Text = "Let\'s get them!",
					function getResult()
					{
						return 0;
					}

				}
			]
		});
		this.m.Screens.push({
			ID = "Kidnapping2",
			Title = "After the battle...",
			Text = "[img]gfx/ui/events/event_22.png[/img]{Sheathing your sword, you order %randombrother% to go free the prisoners. A litany of bewildered clansmen are freed from leather leashes, chains, and dog cages. They thank you for your timely arrival, and for the violence you brought to the raiders. | The raiders are slaughtered to a man. You set your men out to go rescue every clansman and woman they can find. Each one comes together, hugging and crying, mad with happiness that they have survived this horrifying ordeal. | After killing the last raider around, you tell the men to go around freeing the hostages the vagabonds had taken. Each one comes to you in turn, some kissing your hand, others your feet. You only tell them to get back to %townname% as you will do yourself.}",
			Image = "",
			List = [],
			Options = [
				{
					Text = "Looks like this is over.",
					function getResult()
					{
						return 0;
					}

				}
			]
		});
		this.m.Screens.push({
			ID = "Kidnapping3",
			Title = "Near %townname%",
			Text = "[img]gfx/ui/events/event_53.png[/img]{Unfortunately, the raiders got away with the hostages. May the gods be with those sorry souls now. | You couldn\'t do it - you couldn\'t save those poor folk. Now only the gods know what will happen to them. | Sadly, the marauders got away with their human cargo in tow. Those poor folks will have to fend for themselves now. The stories you hear, however, tell you they will not fare well at all. | The raiders got away, their prisoners alongside with them. You\'ve no idea what will happen to those people now, but you know it isn\'t good. Slavery. Torture. Death. You\'re not sure which is the worst.}",
			Image = "",
			List = [],
			Options = [
				{
					Text = "{They won\'t like that in %townname%... | Maybe they can be bought back...}",
					function getResult()
					{
						return 0;
					}

				}
			]
		});
		this.m.Screens.push({
			ID = "Success1",
			Title = "On your return...",
			Text = "[img]gfx/ui/events/event_04.png[/img]{You return to %employer% looking rightfully smug.%SPEECH_ON%Work\'s done.%SPEECH_OFF%He nods, tipping a goblet of wine while not necessarily offering it.%SPEECH_ON%Yes. We are eternally grateful for your help, as well as... monetarily grateful.%SPEECH_OFF%The man gestures toward the corner of the room. You see a satchel of crowns there.%SPEECH_ON%%reward% crowns, just as we had agreed. Thanks again, warrior.%SPEECH_OFF% | %employer% welcomes your return with a goblet of wine.%SPEECH_ON%Drink up, warrior, you\'ve earned it.%SPEECH_OFF%It tastes... particular. Haughty, if that could be a flavor. Your employer swings around his desk, taking a gleefully happy seat.%SPEECH_ON%You managed to protect us just as you had promised! I am most impressed.%SPEECH_OFF%He nods, tipping his goblet toward a wooden chest.%SPEECH_ON%MOST impressed.%SPEECH_OFF%You open the chest to find a bevy of golden crowns. | %employer% welcomes you into his room.%SPEECH_ON%I watched from my window, you know? Saw it all. Well, most of it. The good parts, I suppose.%SPEECH_OFF%You raise an eyebrow.%SPEECH_ON%Oh, don\'t give me that look. I don\'t feel bad for enjoying what I saw. We\'re alive, right? Us, the good guys.%SPEECH_OFF%The other eyebrow goes up.%SPEECH_ON%Well... anyway, your payment, as promised.%SPEECH_OFF%The man hands over a chest of %reward% crowns. | When you return to %employer% you find his room has almost been packed up, everything ready to move and go. You raise a bit of humorous concern.%SPEECH_ON%Getting ready to go somewhere?%SPEECH_OFF%The man\'s settled down into his chair.%SPEECH_ON%I had my doubts, warrior. Can you blame me? For what it\'s worth, you shouldn\'t need doubt my ability to pay.%SPEECH_OFF%He sways a hand across his desk. On the corner is a satchel, lumpy and bulbous with coins.%SPEECH_ON%%reward% crowns, as promised.%SPEECH_OFF% | %employer% raises from his chair when you enter. He bows, somewhat incredulously, but also earnestly. He tips his head toward the window where the din of happy clanfolk murmurs.%SPEECH_ON%You hear that? You\'ve earned that, warrior. The people here love you now.%SPEECH_OFF%You nod, but the love of the common man is not what brought you here.%SPEECH_ON%What else have I earned?%SPEECH_OFF%%employer% smiles.%SPEECH_ON%A man on point. I bet that\'s what gives you your... edge. Of course, you\'ve also earned this.%SPEECH_OFF%He heaves a wooden chest onto his desk and unlatches it. The shine of gold crowns warms your heart. | %employer%\'s staring out his window when you enter. He\'s almost in a dreamstate, head bent low to his hand. You interrupt his thoughts.%SPEECH_ON%Thinking of me?%SPEECH_OFF%The man chuckles and playfully clutches his chest.%SPEECH_ON%You are truly the man of my dreams, warrior.%SPEECH_OFF%He crosses the room and takes a chest from the bookshelf. He unlatches it as he sets it on the table. A glorious pile of gold crowns stare you in the face. %employer% grins.%SPEECH_ON%Now who is dreaming?%SPEECH_OFF% | %employer%\'s at his desk when you enter.%SPEECH_ON%I saw a good deal of it. The killing, the dying.%SPEECH_OFF%You take a seat.%SPEECH_ON%Hope you enjoyed the show. Viewing\'s ain\'t free, though.%SPEECH_OFF%The man nods, taking a satchel and handing it over.%SPEECH_ON%I\'d pay for an encore, but I\'m not sure %townname% wants that.%SPEECH_OFF%}",
			Image = "",
			Characters = [],
			List = [],
			ShowEmployer = true,
			Options = [
				{
					Text = "{The %companyname% will make good use of this. | Payment for a hard day\'s work.}",
					function getResult()
					{
						this.World.Assets.addBusinessReputation(this.Const.World.Assets.ReputationOnContractSuccess);
						this.World.Assets.addMoney(this.Contract.m.Payment.getOnCompletion());
						this.World.FactionManager.getFaction(this.Contract.getFaction()).addPlayerRelation(this.Const.World.Assets.RelationCivilianContractSuccess, "Defended the camp against raiders");
						this.World.Contracts.finishActiveContract();
						return 0;
					}

				}
			],
			function start()
			{
				this.Contract.m.Reward = this.Contract.m.Payment.getOnCompletion();
				this.List.push({
					id = 10,
					icon = "ui/icons/asset_money.png",
					text = "You gain [color=" + this.Const.UI.Color.PositiveEventValue + "]" + this.Contract.m.Reward + "[/color] Crowns"
				});
			}

		});
		this.m.Screens.push({
			ID = "Failure1",
			Title = "On your return...",
			Text = "[img]gfx/ui/events/event_30.png[/img]{When you enter %employer%\'s room, he tells you to close the door behind you. Just as the latch clicks, the man slams you with a stream of obscenities which you couldn\'t hope to keep track of. Calming down, his voice - and language - return to some level of normalcy.%SPEECH_ON%Every bit of our camp was raided. What is it, exactly, did you think I was paying you for? Get out of here.%SPEECH_OFF% | %employer%\'s slamming back goblets of wine when you enter. There\'s the din of angry clansmen squalling outside his window.%SPEECH_ON%Hear that? They\'ll have my head if I pay you, warrior. You had one job, one job! Protect this camp. And you couldn\'t do it. So now you could do one thing right and it comes free: get the hell out of my sight.%SPEECH_OFF% | %employer% clasps his hands over his desk.%SPEECH_ON%What is it, exactly, are you expecting to get here? I\'m surprised you returned to me at all. Half the camp is on fire and the other half is already ash. I didn\'t hire you to produce smoke and desolation, warrior. Get the hell out of here.%SPEECH_OFF% | When you return to %employer%, he\'s holding a mug of ale. His hand his shaking. His face is red.%SPEECH_ON%It\'s taking everything in me to not throw this in your face right now.%SPEECH_OFF%Just in case, the man finishes the drink in one big gulp. He slams it on his desk.%SPEECH_ON%We expected you to protect us. Instead, the raiders swarmed us like they were taking a goddam leisure trip! \'m not in the business of giving marauders a good time, warrior. Get the farkin\' hell out of here!%SPEECH_OFF%}",
			Image = "",
			List = [],
			ShowEmployer = true,
			Options = [
				{
					Text = "{Damn this peasantfolk! | We should have asked for more payment in advance... | Damnit!}",
					function getResult()
					{
						this.World.Assets.addBusinessReputation(this.Const.World.Assets.ReputationOnContractFail);
						this.World.FactionManager.getFaction(this.Contract.getFaction()).addPlayerRelation(this.Const.World.Assets.RelationCivilianContractFail, "Failed to defend the camp against raiders");
						this.World.Contracts.finishActiveContract(true);
						return 0;
					}

				}
			],
			function start()
			{
				this.Contract.addSituation(this.new("scripts/entity/world/settlements/situations/raided_situation"), 3, this.Contract.m.Home, this.List);
			}

		});
		this.m.Screens.push({
			ID = "Failure2",
			Title = "On your return...",
			Text = "[img]gfx/ui/events/event_30.png[/img]{When you enter %employer%\'s room, he tells you to close the door behind you. Just as the latch clicks, the man slams you with a stream of obscenities which you couldn\'t hope to keep track of. Calming down, his voice - and language - return to some level of normalcy.%SPEECH_ON%Every bit of our camp is raided. People were even taken to the old gods know what ends! What is it, exactly, did you think I was paying you for? Get out of here.%SPEECH_OFF% | %employer%\'s slamming back goblets of wine when you enter. There\'s the din of angry clansmen squalling outside his window.%SPEECH_ON%Hear that? They\'ll have my head if I pay you, warrior. You had one job, one job! Protect this camp. And you couldn\'t do it. Hell, you couldn\'t even save those poor folk that got kidnapped! So now you could do one thing and it comes free: get the hell out of my sight.%SPEECH_OFF% | %employer% clasps his hands over his desk.%SPEECH_ON%What is it, exactly, are you expecting to get here? I\'m surprised you returned to me at all. Half the camp is on fire and the other half is already ash. Survivors tell me that their family members were even kidnapped! Do you know what happens to those taken by raiders? I didn\'t hire you to produce smoke and desolation, warrior. Get the hell out of here.%SPEECH_OFF% | When you return to %employer%, he\'s holding a mug of ale. His hand his shaking. His face is red.%SPEECH_ON%It\'s taking everything in me to not throw this in your face right now.%SPEECH_OFF%Just in case his rage gets the best of him, the man finishes the drink in one big gulp. He slams it on his desk.%SPEECH_ON%We expected you protect us. Instead, the raiders swarmed us like they were taking a goddam leisure trip! I\'m not in the business of giving marauders a good time, warrior. Get the farkin\' hell out of here!%SPEECH_OFF% | %employer% laughs when you step into his room.%SPEECH_ON%Our camp is completely raided. The people of %townname% are in an uproar, at least those alive to be angry in the first place, that is. And what\'s more? You let a few of our folk get taken by these monsters!%SPEECH_OFF%The man shakes his head and points his hand to the door.%SPEECH_ON%I don\'t know what you expected me to pay you for, but it wasn\'t this.%SPEECH_OFF%}",
			Image = "",
			List = [],
			ShowEmployer = true,
			Options = [
				{
					Text = "{Damn this peasantfolk! | We should have asked for more payment in advance... | Damnit!}",
					function getResult()
					{
						this.World.Assets.addBusinessReputation(this.Const.World.Assets.ReputationOnContractFail);
						this.World.FactionManager.getFaction(this.Contract.getFaction()).addPlayerRelation(this.Const.World.Assets.RelationCivilianContractFail, "Failed to defend the camp against raiders");
						this.World.Contracts.finishActiveContract(true);
						return 0;
					}

				}
			],
			function start()
			{
				this.Contract.addSituation(this.new("scripts/entity/world/settlements/situations/raided_situation"), 3, this.Contract.m.Home, this.List);
			}

		});
	}

	function onPrepareVariables( _vars )
	{
		_vars.push([
			"reward",
			this.m.Reward
		]);
	}

	function onHomeSet()
	{
		if (this.m.SituationID == 0)
		{
			local s = this.new("scripts/entity/world/settlements/situations/raided_situation");
			s.setValidForDays(4);
			this.m.SituationID = this.m.Home.addSituation(s);
		}
	}

	function onClear()
	{
		if (this.m.IsActive)
		{
			this.World.FactionManager.getFaction(this.getFaction()).setActive(true);
			this.m.Home.getSprite("selection").Visible = false;

			if (this.m.Kidnapper != null && !this.m.Kidnapper.isNull())
			{
				this.m.Kidnapper.getSprite("selection").Visible = false;
			}

			this.World.getGuestRoster().clear();
		}
	}

	function onIsValid()
	{
		return true;
	}

	function onSerialize( _out )
	{
		this.m.Flags.set("KidnapperID", this.m.Kidnapper != null && !this.m.Kidnapper.isNull() ? this.m.Kidnapper.getID() : 0);
		this.contract.onSerialize(_out);
	}

	function onDeserialize( _in )
	{
		this.contract.onDeserialize(_in);
		this.m.Kidnapper = this.WeakTableRef(this.World.getEntityByID(this.m.Flags.get("KidnapperID")));
	}

});

