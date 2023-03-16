::NorthMod.Utils <-{

	function stringSplit(sourceString, delimiter)
	{
		local leftover = sourceString;
		local results = [];
		while(true)
		{
			local index = leftover.find(delimiter);
			if (index == null) {
				results.push(leftover);
				break;
			}
			local leftSide = leftover.slice(0, index);
			results.push(leftSide);
			leftover = leftover.slice(index + delimiter.len());
		}
		return results;
	}

	function stringReplace( sourceString, textToReplace, replacementText )
	{
		local strings = this.stringSplit(sourceString, textToReplace);
		local result = strings[0];
		
		for (local i = 1; i < strings.len(); i++) {
			 result += replacementText + strings[i];
			 
		}
		return result;
	}

	function scorePicker(scores)
	{
		local totalScore = 0;
		for (local i = 0; i < totalScore.len(); i++)
		{
			totalScore += scores[i];
		}
		local r = this.Math.rand(1, totalScore);
		for (local i = 0; i < totalScore.len(); i++) {
			if (score[i] >= totalScore)
			{
				return i;
			}
			totalScore -= score[i];
		}
		return null;
	}


	function guaranteedTalents(bro, talent, number)
	{

		local talents = bro.getTalents();
		if (talents[talent] > 0 && talents[talent] < number )
		{
			talents[talent] = number;
		}
		else if (talents[talent] == 0) {
			local count = 0;
			local min = 10;
			local minTalent = null;
			for (local i = 0; i < talents.len(); i++) {
				if (talents[i] > 0) {
					count++;
					if (talents[i] < min && i != this.Const.Attributes.MeleeDefense) {
						min = talents[i];
						minTalent = i;
					}
				}
				
			}
			if(count < 3) {
				talents[this.Const.Attributes.MeleeSkill] = number;
			} else {
				talents[minTalent] = 0;
				talents[this.Const.Attributes.MeleeSkill] = number;
			}
		}
		
		
		
		bro.m.Attributes = [];
		bro.fillAttributeLevelUpValues(this.Const.XP.MaxLevelWithPerkpoints - 1);
	}
	
	function barbarianNameOnly()
	{
		return ::NorthMod.Const.BarbarianNames[Math.rand(0, ::NorthMod.Const.BarbarianNames.len()-1];
	}
	
	function barbarianNameAndTitle()
	{
		return this.barbarianNameOnly() + " " ::NorthMod.Const.BarbarianTitles[Math.rand(0, ::NorthMod.Const.BarbarianTitles.len()-1];
	}
	
	
	
	
	function logInfo(_msg)
	{
		if (::NorthMod.Const.EnabledLogging)
		{
			logInfo(_msg);
		}
	}
}