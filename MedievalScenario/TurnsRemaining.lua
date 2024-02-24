-- TurnsRemaining
-- Author: ebeach
-- DateCreated: 1/20/2011 9:35:24 AM
--------------------------------------------------------------
local g_ScenarioDone = false;

--Test global save data!

--------------------------------------------------------------
-- Memoized Persistent Properties
--------------------------------------------------------------
-- Try not to use this directly for pulling values!
-- Memoize instead.
g_SaveData = Modding.OpenSaveData();
-------------------------------------------------------------- 
function GetPersistentProperty(name)
	if(g_Properties == nil) then
		g_Properties = {};
	end
	
	if(g_Properties[name] == nil) then
		g_Properties[name] = g_SaveData.GetValue(name);
	end
	
	return g_Properties[name];
end
--------------------------------------------------------------
function SetPersistentProperty(name, value)
	if(g_Properties == nil) then
		g_Properties = {};
	end
	
	g_SaveData.SetValue(name, value);
	g_Properties[name] = value;
end
--------------------------------------------------------------
function SetGenevaLocation(x, y)	
	SetPersistentProperty("GenevaX", x);
	SetPersistentProperty("GenevaY", y);
end
-------------------------------------------------------------- 
function GetGenevaLocation()
	return  GetPersistentProperty("GenevaX"), GetPersistentProperty("GenevaY");
end
--------------------------------------------------------------
function SetWittenbergLocation(x, y)
	SetPersistentProperty("WittenbergX", x);
	SetPersistentProperty("WittenbergY", y);
end
-------------------------------------------------------------- 
function GetWittenbergLocation()
	return GetPersistentProperty("WittenbergX"),  GetPersistentProperty("WittenbergY");
end
--------------------------------------------------------------
function SetZurichLocation(x, y)
	SetPersistentProperty("ZurichX", x);
	SetPersistentProperty("ZurichY", y);
end
-------------------------------------------------------------- 
function GetZurichLocation()
	return GetPersistentProperty("ZurichX"), GetPersistentProperty("ZurichY");
end
--------------------------------------------------------------
function SetVaticanLocation(x, y)
	SetPersistentProperty("VaticanX", x);
	SetPersistentProperty("VaticanY", y);
end
--------------------------------------------------------------
function GetVaticanLocation()
	return GetPersistentProperty("VaticanX"), GetPersistentProperty("VaticanY");
end
--------------------------------------------------------------

--------------------------------------------------------------
ContextPtr:SetUpdate(function()

	if (g_ScenarioDone) then
		ContextPtr:ClearUpdate(); 
		ContextPtr:SetHide( true );
	end

	local iTurnsRemaining = 200 - Game.GetGameTurn();
	local turnsRemainingText = Locale.ConvertTextKey("TXT_KEY_MEDIEVAL_SCENARIO_TURNSREMAINING", iTurnsRemaining);
	Controls.TurnsRemainingLabel:LocalizeAndSetText(turnsRemainingText);
	Controls.Grid:DoAutoSize();
	
end);

---------------------------------------------------------------------
function OnGameCoreUpdateBegin() 
	local iTurnsRemaining = 200 - Game.GetGameTurn();
	if (iTurnsRemaining < 1 and not g_ScenarioDone) then
		
		local iHighestScore = -1;
		local iHighestPlayer = -1;
		for iPlayerLoop = 0, GameDefines.MAX_MAJOR_CIVS-1, 1 do
			local player = Players[iPlayerLoop];
			if (player:IsAlive()) then
				if (player:GetScore() > iHighestScore) then
					iHighestScore = player:GetScore();
					iHighestPlayer = iPlayerLoop;
				end
			end
		end

		print("iHighestScore: " .. iHighestScore);
		print("iHighestPlayer: " .. iHighestPlayer);
		if (iHighestPlayer == 0) then
			Game.SetWinner(Players[Game.GetActivePlayer()]:GetTeam(), GameInfo.Victories["VICTORY_TIME"].ID);
		else
			Game.SetGameState(GameplayGameStateTypes.GAMESTATE_OVER);	
		end
		-- Remove this event listener so it doesn't get called again if the user wants to continue
		GameEvents.GameCoreUpdateBegin.Remove(OnGameCoreUpdateBegin);
		g_ScenarioDone = true;
	end
end
GameEvents.GameCoreUpdateBegin.Add(OnGameCoreUpdateBegin);

---------------------------------------------------------------------
function OnBriefingButton()
	print (Locale.ConvertTextKey("TXT_KEY_MEDIEVAL_SCENARIO_CIV5_DAWN_TEXT"));
    UI.AddPopup( { Type = ButtonPopupTypes.BUTTONPOPUP_TEXT,
                   Data1 = 800,
                   Option1 = true,
                   Text = "TXT_KEY_MEDIEVAL_SCENARIO_CIV5_DAWN_TEXT" } );
end
Controls.BriefingButton:RegisterCallback( Mouse.eLClick, OnBriefingButton );

---------------------------------------------------------------------
function OnEnterCityScreen()
    ContextPtr:SetHide( true );
end
Events.SerialEventEnterCityScreen.Add( OnEnterCityScreen );

---------------------------------------------------------------------
function OnExitCityScreen()

	if (Game:GetGameState() ~= GameplayGameStateTypes.GAMESTATE_EXTENDED) then 
    		ContextPtr:SetHide( false );
	end
end
Events.SerialEventExitCityScreen.Add( OnExitCityScreen );
---------------------------------------------------------------------
GameEvents.PlayerDoTurn.Add(function(iPlayer) 
	local iReformationTurn = GetPersistentProperty("ReformationStart");
	local iTurn = Game.GetGameTurn();
	
	-- Only on first player's turn
	if (iPlayer > 0 or iTurn < 1) then
		return false;
	end

	if (iReformationTurn > -1) then
		if (iReformationTurn == iTurn) then
			StartReformation();
		elseif (GetPersistentProperty("SecondReformer") == iTurn) then
			ReformationPhaseTwo();
		elseif (GetPersistentProperty("ThirdReformer") == iTurn) then
			ReformationPhaseThree();
		end
	else
		if (Game.GetGameTurnYear() > 1514) then
 			SetPersistentProperty("ReformationStart", iTurn + 1);
 			SetPersistentProperty("SecondReformer", iTurn + 4);
 			SetPersistentProperty("ThirdReformer", iTurn + 7);    
		end
	end
	
	ScoreHolyCities();
	
	if (iTurn == 1) then
		BringInMongols();
	elseif (iTurn == 50 or iTurn == 60 or iTurn == 70 or iTurn == 85 or iTurn == 110) then
		ReinforceMongols();
	elseif (iTurn == 150) then
		MongolsPullOut();
	end

	return false;
end);

-------------------------------------------------
-- CityCaptureComplete
-------------------------------------------------
GameEvents.CityCaptureComplete.Add(function(iOldOwner, bIsCapital, iX, iY, iNewOwner, iPop, bConquest)

	local plot = Map.GetPlot(iX, iY);
	local cCity = plot:GetPlotCity();
	local iNewOwner = cCity:GetOwner();
	local civType = Players[iNewOwner]:GetCivilizationType();
	
	local pOrthodoxHolyCity = Game.GetHolyCityForReligion(GameInfoTypes["RELIGION_ORTHODOXY"], -1);
	local pIslamHolyCity = Game.GetHolyCityForReligion(GameInfoTypes["RELIGION_ISLAM"], -1);
	local pChristianityHolyCity = Game.GetHolyCityForReligion(GameInfoTypes["RELIGION_CHRISTIANITY"], -1);
	local pProtestantHolyCity = Game.GetHolyCityForReligion(GameInfoTypes["RELIGION_PROTESTANTISM"], -1);

	local popupInfo = {
		Data1 = 500,
		Type = ButtonPopupTypes.BUTTONPOPUP_TEXT,
	}
			
	if (cCity == pOrthodoxHolyCity) then
		if (civType == GameInfo.Civilizations["CIVILIZATION_BYZANTIUM"].ID or
		    civType == GameInfo.Civilizations["CIVILIZATION_RUSSIA"].ID) then
			Game.SetFounder(GameInfoTypes["RELIGION_ORTHODOXY"], iNewOwner);
		else
			local pNewHolyCity = FindNextOrthodoxHolyCity();
			if (pNewHolyCity == nil) then
				popupInfo.Text = Locale.ConvertTextKey("TXT_KEY_MEDIEVAL_SCENARIO_NO_ORTHODOX_CITIES", pOrthodoxHolyCity:GetName(), pOrthodoxHolyCity:GetName());
				UI.AddPopup(popupInfo);
			else
				Game.SetHolyCity (GameInfoTypes["RELIGION_ORTHODOXY"], pNewHolyCity);
				Game.SetFounder(GameInfoTypes["RELIGION_ORTHODOXY"], pNewHolyCity:GetOwner());
				popupInfo.Text = Locale.ConvertTextKey("TXT_KEY_MEDIEVAL_SCENARIO_NEW_ORTHODOX_HOLY_CITY", pOrthodoxHolyCity:GetName(), pNewHolyCity:GetName());
				UI.AddPopup(popupInfo);			
			end
		end			
	
	elseif (cCity == pIslamHolyCity) then
		if (civType == GameInfo.Civilizations["CIVILIZATION_SONGHAI"].ID or
			civType == GameInfo.Civilizations["CIVILIZATION_OTTOMAN"].ID or
			civType == GameInfo.Civilizations["CIVILIZATION_ARABIA"].ID) then
			Game.SetFounder(GameInfoTypes["RELIGION_ISLAM"], iNewOwner);
		else
			Game.SetFounder(GameInfoTypes["RELIGION_ISLAM"], GetPersistentProperty("MeccaPlayer"));
		end			
	
	elseif (cCity == pChristianityHolyCity) then
		if (MyCurrentReligion(iNewOwner) == 2 and
		    (civType == GameInfo.Civilizations["CIVILIZATION_FRANCE"].ID or
			 civType == GameInfo.Civilizations["CIVILIZATION_CELTS"].ID or
			 civType == GameInfo.Civilizations["CIVILIZATION_ENGLAND"].ID or
			 civType == GameInfo.Civilizations["CIVILIZATION_SPAIN"].ID or
			 civType == GameInfo.Civilizations["CIVILIZATION_NETHERLANDS"].ID or
			 civType == GameInfo.Civilizations["CIVILIZATION_AUSTRIA"].ID or
			 civType == GameInfo.Civilizations["CIVILIZATION_SWEDEN"].ID)) then
			Game.SetFounder(GameInfoTypes["RELIGION_CHRISTIANITY"], iNewOwner);
		else
			Game.SetFounder(GameInfoTypes["RELIGION_CHRISTIANITY"], GetPersistentProperty("VaticanPlayer"));
		end			

	elseif (cCity == pProtestantHolyCity) then
		if (MyCurrentReligion(iNewOwner) == 13 and
		    (civType == GameInfo.Civilizations["CIVILIZATION_FRANCE"].ID or
			 civType == GameInfo.Civilizations["CIVILIZATION_CELTS"].ID or
			 civType == GameInfo.Civilizations["CIVILIZATION_ENGLAND"].ID or
			 civType == GameInfo.Civilizations["CIVILIZATION_SPAIN"].ID or
			 civType == GameInfo.Civilizations["CIVILIZATION_NETHERLANDS"].ID or
			 civType == GameInfo.Civilizations["CIVILIZATION_AUSTRIA"].ID or
			 civType == GameInfo.Civilizations["CIVILIZATION_SWEDEN"].ID)) then
			Game.SetFounder(GameInfoTypes["RELIGION_PROTESTANTISM"], iNewOwner);
		else
			Game.SetFounder(GameInfoTypes["RELIGION_PROTESTANTISM"], GetPersistentProperty("ProtestantHolyCityPlayer"));
		end			

	end
	
	-- VP for capture?
	local eCityReligion = cCity:GetReligiousMajority();
	local eCapturingPlayerReligion = MyCurrentReligion(iNewOwner);
	local player = Players[iNewOwner];
	local pJerusalemPlot = Map.GetPlot(GetPersistentProperty("JerusalemX"), GetPersistentProperty("JerusalemY"));

	if (bConquest and eCityReligion ~= eCapturingPlayerReligion and eCityReligion > 0 and iNewOwner < 22) then
			    
		local iVPReceived = iPop * 25;	

		-- Put up dialog box
		local popupInfo = {
			Data1 = 500,
			Type = ButtonPopupTypes.BUTTONPOPUP_TEXT,
		}

		-- Human player?
		if (cCity:IsHolyCityAnyReligion() or cCity:Plot() == pJerusalemPlot) then
		
			iVPReceived = iVPReceived * 2;
			player:ChangeScoreFromFutureTech(iVPReceived);
			
			if (iPlayer == 0) then
				popupInfo.Text = Locale.ConvertTextKey("TXT_KEY_MEDIEVAL_SCENARIO_VP_HOLY_CITY_CAPTURE_HUMAN", iVPReceived, cCity:GetName(), iPop);
			else
				if (Teams[player:GetTeam()]:IsHasMet(Game.GetActiveTeam())) then
					popupInfo.Text = Locale.ConvertTextKey("TXT_KEY_MEDIEVAL_SCENARIO_VP_HOLY_CITY_CAPTURE", player:GetCivilizationDescriptionKey(), iVPReceived, cCity:GetName(), iPop);
				else
					popupInfo.Text = Locale.ConvertTextKey("TXT_KEY_MEDIEVAL_SCENARIO_VP_HOLY_CITY_CAPTURE", "TXT_KEY_UNMET_PLAYER", iVPReceived, cCity:GetName(), iPop);
				end
			end
		else
		
			player:ChangeScoreFromFutureTech(iVPReceived);

			if (iPlayer == 0) then
				popupInfo.Text = Locale.ConvertTextKey("TXT_KEY_MEDIEVAL_SCENARIO_VP_CITY_CAPTURE_HUMAN", iVPReceived, cCity:GetName(), iPop);
			else
				if (Teams[player:GetTeam()]:IsHasMet(Game.GetActiveTeam())) then
					popupInfo.Text = Locale.ConvertTextKey("TXT_KEY_MEDIEVAL_SCENARIO_VP_CITY_CAPTURE", player:GetCivilizationDescriptionKey(), iVPReceived, cCity:GetName(), iPop);
				else
					popupInfo.Text = Locale.ConvertTextKey("TXT_KEY_MEDIEVAL_SCENARIO_VP_CITY_CAPTURE", "TXT_KEY_UNMET_PLAYER", iVPReceived, cCity:GetName(), iPop);
				end
			end
		end
		UI.AddPopup(popupInfo);
	end
end);
-------------------------------------------------
function FindNextOrthodoxHolyCity()

	local pBestCity = nil;
	local iBestPop = 0;

	for iPlayer = 0, 46, 1 do
		local pPlayer = Players[iPlayer];
		if (pPlayer:IsAlive()) then
			for cityIndex = 0, pPlayer:GetNumCities() - 1, 1 do
    			local pCity = pPlayer:GetCityByID(cityIndex);
    			if (pCity:GetReligiousMajority() == GameInfoTypes["RELIGION_ORTHODOXY"]) then
    				if (pCity:GetPopulation() > iBestPop) then
    					iBestPop = pCity:GetPopulation();
    					pBestCity = pCity;
    				end
    			end
			end
		end
	end 
    return pBestCity;
end
-------------------------------------------------
-- SetAlly
-------------------------------------------------
GameEvents.SetAlly.Add(function(iMinor, iOldAlly, iNewAlly)

	local iMeccaPlayer = GetPersistentProperty("MeccaPlayer");
	local iVaticanPlayer = GetPersistentProperty("VaticanPlayer");
	local iProtestantPlayer = GetPersistentProperty("ProtestantHolyCityPlayer")	
	
	if (iNewAlly == -1) then
		if (iMinor == iMeccaPlayer) then
			Game.SetFounder(GameInfoTypes["RELIGION_ISLAM"], iMeccaPlayer);
		elseif (iMinor == iVaticanPlayer) then
			Game.SetFounder(GameInfoTypes["RELIGION_CHRISTIANITY"], iVaticanPlayer);
		end
		
	else
		local civType = Players[iNewAlly]:GetCivilizationType();
	
		if (iMinor == iMeccaPlayer) then
			if (civType == GameInfo.Civilizations["CIVILIZATION_SONGHAI"].ID or
				civType == GameInfo.Civilizations["CIVILIZATION_OTTOMAN"].ID or
				civType == GameInfo.Civilizations["CIVILIZATION_ARABIA"].ID) then
				Game.SetFounder(GameInfoTypes["RELIGION_ISLAM"], iNewAlly);
			else
				Game.SetFounder(GameInfoTypes["RELIGION_ISLAM"], iMeccaPlayer);
			end			
	
		elseif (iMinor == iVaticanPlayer) then
			if (MyCurrentReligion(iNewAlly) == 2 and
				(civType == GameInfo.Civilizations["CIVILIZATION_FRANCE"].ID or
				 civType == GameInfo.Civilizations["CIVILIZATION_CELTS"].ID or
				 civType == GameInfo.Civilizations["CIVILIZATION_ENGLAND"].ID or
				 civType == GameInfo.Civilizations["CIVILIZATION_SPAIN"].ID or
				 civType == GameInfo.Civilizations["CIVILIZATION_NETHERLANDS"].ID or
				 civType == GameInfo.Civilizations["CIVILIZATION_AUSTRIA"].ID or
				 civType == GameInfo.Civilizations["CIVILIZATION_SWEDEN"].ID)) then
				Game.SetFounder(GameInfoTypes["RELIGION_CHRISTIANITY"], iNewAlly);
			else
				Game.SetFounder(GameInfoTypes["RELIGION_CHRISTIANITY"], iVaticanPlayer);
			end	

		elseif (iMinor == GetPersistentProperty("ProtestantHolyCityPlayer")) then
			if (MyCurrentReligion(iNewAlly) == 13 and
				(civType == GameInfo.Civilizations["CIVILIZATION_FRANCE"].ID or
				 civType == GameInfo.Civilizations["CIVILIZATION_CELTS"].ID or
				 civType == GameInfo.Civilizations["CIVILIZATION_ENGLAND"].ID or
				 civType == GameInfo.Civilizations["CIVILIZATION_SPAIN"].ID or
				 civType == GameInfo.Civilizations["CIVILIZATION_NETHERLANDS"].ID or
				 civType == GameInfo.Civilizations["CIVILIZATION_AUSTRIA"].ID or
				 civType == GameInfo.Civilizations["CIVILIZATION_SWEDEN"].ID)) then
				Game.SetFounder(GameInfoTypes["RELIGION_PROTESTANTISM"], iNewAlly);
			else
				Game.SetFounder(GameInfoTypes["RELIGION_PROTESTANTISM"], iProtestantPlayer);
			end	

		end		
	end

end);
-------------------------------------------------
-- DoResolveVictoryVote
-------------------------------------------------
GameEvents.DoResolveVictoryVote.Add(function(bPreliminaryVote)

	-------------------------
	-- Vatican City
	-------------------------
	local kiVaticanExtraVotes = 1;
	local iTeam = GetVaticanExtraVoteRecipient();
	if (iTeam ~= -1) then
		SetPersistentProperty("VaticanExtraVoteTeam", iTeam); -- So VictoryProgress.lua can display the last team that got extra vote
		Game.ChangeNumVotesForTeam(iTeam, kiVaticanExtraVotes);
	end

	return true;
end)

-- Get the team which receives the extra vote from Vatican City in a HRE election, or no team if there isn't one
function GetVaticanExtraVoteRecipient()
	local iRecipient = -1;

	local iVaticanPlayer = GetPersistentProperty("VaticanPlayer");
	local iVaticanX, iVaticanY = GetVaticanLocation();
	
	if (iVaticanPlayer == nil or iVaticanX == nil or iVaticanY == nil) then
		print("Vatican data not found, no player gets extra vote");
		return iRecipient;
	end
	
	local pVaticanPlayer = Players[iVaticanPlayer];
	local pVaticanPlot = Map.GetPlot(iVaticanX, iVaticanY);
	
	if (pVaticanPlayer == nil or pVaticanPlot == nil) then
		print("Vatican object not found, no player gets extra vote");
		return iRecipient;
	end
	
	if (pVaticanPlot:IsCity()) then
		local iOwner = pVaticanPlot:GetOwner();
		
		-- Is it still independent? If so, its ally gets the extra vote
		if (iOwner == iVaticanPlayer) then
			local iAlly = pVaticanPlayer:GetAlly();
			if (iAlly ~= -1 and Players[iAlly] ~= nil) then
				local pAlly = Players[iAlly];
				iRecipient = pAlly:GetTeam();
			end
		
		-- Has it been conquered (or bought out by Austria)? If so, its controller gets the extra vote
		elseif (iOwner ~= nil and iOwner ~= -1) then
			local pOwner = Players[iOwner];
			if (pOwner ~= nil) then
				iRecipient = pOwner:GetTeam();
			end
		
		else
			print("No player for Vatican City plot found, no player gets extra vote");
		end
	else
		print("Vatican City not found");
	end

	return iRecipient;
end

-------------------------------------------------
-- GetScenarioDiploModifier1
-------------------------------------------------
GameEvents.GetScenarioDiploModifier1.Add(function(ePlayer1, ePlayer2)

	local eReligion1;
	local eReligion2;
	
	eReligion1 = MyCurrentReligion(ePlayer1);
	eReligion2 = MyCurrentReligion(ePlayer2);
	
	if (eReligion1 ~= eReligion2) then
		return 60;
	else
		return 0;
	end
end)

-------------------------------------------------
-- GetFounderBenefitsReligion
-------------------------------------------------
function OnGetFounderBenefitsReligion(ePlayer)

    local bGetsCredit = false;
	local pPlayer = Players[ePlayer];
	local iMyCivsReligion = MyCurrentReligion(ePlayer);
		
	-- Check Jerusalem first
	local iJerusalemX = GetPersistentProperty("JerusalemX");
	local iJerusalemY = GetPersistentProperty("JerusalemY");
	local pJerusalemPlot = Map.GetPlot(iJerusalemX, iJerusalemY);
	if (pJerusalemPlot:IsCity()) then
		if (pJerusalemPlot:GetOwner() == ePlayer) then
			bGetsCredit = true;
		else
			-- In this scenario, being allied with city state that is Holy City is okay
			local eOwner = pJerusalemPlot:GetOwner();
			if (eOwner > -1) then
				if (Players[eOwner]:IsAllies(ePlayer)) then
					bGetsCredit = true;
				end
			end
		end
	else
		print("Jerusalem missing at ",  iJerusalemX, ":", iJerusalemY);		
	end
	-- Now check Holy City for this religion
	if (not bGetsCredit) then

		local pHolyCity = Game.GetHolyCityForReligion(iMyCivsReligion, -1);

		if (pHolyCity ~= nil) then
			if (pHolyCity:GetOwner() == ePlayer) then
				bGetsCredit = true;
			else
				-- In this scenario, being allied with city state that is Holy City is okay
				local eOwner = pHolyCity:GetOwner();
				if (Players[eOwner]:IsAllies(ePlayer)) then
					bGetsCredit = true;
				end
			end
		end
   end
	
	if (bGetsCredit) then
		return iMyCivsReligion;
	else	
	    return -1;
	end
end
---------------------------------------------------------
GameEvents.GetReligionToSpread.Add(function(ePlayer)
	return MyCurrentReligion(ePlayer);
end)
---------------------------------------------------------
function MyCurrentReligion(ePlayer)

	local pPlayer = Players[ePlayer];
 
	-- Start with Catholic as default
	local iMyCivsReligion = 2;
	
	local civType = pPlayer:GetCivilizationType();
	if (civType == GameInfo.Civilizations["CIVILIZATION_BYZANTIUM"].ID or
	    civType == GameInfo.Civilizations["CIVILIZATION_RUSSIA"].ID) then

		iMyCivsReligion = 12;

	elseif (civType == GameInfo.Civilizations["CIVILIZATION_SONGHAI"].ID or
	    	civType == GameInfo.Civilizations["CIVILIZATION_OTTOMAN"].ID or
	    	civType == GameInfo.Civilizations["CIVILIZATION_ARABIA"].ID) then

		iMyCivsReligion = 5;
			
	elseif (civType == GameInfo.Civilizations["CIVILIZATION_FRANCE"].ID or
	    	civType == GameInfo.Civilizations["CIVILIZATION_CELTS"].ID or
	    	civType == GameInfo.Civilizations["CIVILIZATION_ENGLAND"].ID or
	    	civType == GameInfo.Civilizations["CIVILIZATION_SPAIN"].ID or
	    	civType == GameInfo.Civilizations["CIVILIZATION_NETHERLANDS"].ID or
	    	civType == GameInfo.Civilizations["CIVILIZATION_AUSTRIA"].ID or
	    	civType == GameInfo.Civilizations["CIVILIZATION_SWEDEN"].ID) then

		if (civType == GameInfo.Civilizations["CIVILIZATION_FRANCE"].ID) then
			if (GetPersistentProperty("FranceCatholic") == 0) then
				iMyCivsReligion = 13;
			end		
		elseif (civType == GameInfo.Civilizations["CIVILIZATION_CELTS"].ID) then
			if (GetPersistentProperty("CeltsCatholic") == 0) then
				iMyCivsReligion = 13;
			end		
		elseif (civType == GameInfo.Civilizations["CIVILIZATION_ENGLAND"].ID) then
			if (GetPersistentProperty("EnglandCatholic") == 0) then
				iMyCivsReligion = 13;
			end		
		elseif (civType == GameInfo.Civilizations["CIVILIZATION_SPAIN"].ID) then
			if (GetPersistentProperty("SpainCatholic") == 0) then
				iMyCivsReligion = 13;
			end		
		elseif (civType == GameInfo.Civilizations["CIVILIZATION_NETHERLANDS"].ID) then
			if (GetPersistentProperty("NetherlandsCatholic") == 0) then
				iMyCivsReligion = 13;
			end		
		elseif (civType == GameInfo.Civilizations["CIVILIZATION_AUSTRIA"].ID) then
			if (GetPersistentProperty("AustriaCatholic") == 0) then
				iMyCivsReligion = 13;
			end		
		elseif (civType == GameInfo.Civilizations["CIVILIZATION_SWEDEN"].ID) then
			if (GetPersistentProperty("SwedenCatholic") == 0) then
				iMyCivsReligion = 13;
			end		
	    end
	    
	else
		return -1;
			
	end
	
	return iMyCivsReligion;
end
---------------------------------------------------------
GameEvents.UnitSetXY.Add(function(iPlayer, iUnitID, iX, iY) 

 	local plot = Map.GetPlot(iX, iY);
	local player = Players[iPlayer];
	local unit = player:GetUnitByID(iUnitID);
	if (unit == nil or unit:IsDelayedDeath()) then
	    return false;
	end
	local iNumCaravels = GetPersistentProperty("NumCaravels");

	-- Caravel that has reached China?
	if (unit:GetUnitType() == GameInfoTypes["UNIT_CARAVEL"] and iNumCaravels < 5) then

		-- Adjacent to plot owned by China?
		local bAdjacentChina = IsAdjacentToChina (iX, iY);

		if (bAdjacentChina and not player:IsMinorCiv() and not player:IsBarbarian()) then

			-- How many have already been? 
			iNumCaravels = iNumCaravels + 1;
			SetPersistentProperty("NumCaravels", iNumCaravels);

			unit:Kill(true, -1);

			local iVPReceived;

		    -- Grant VP
			iVPReceived = 600 - (iNumCaravels * 100);

		    player:ChangeScoreFromFutureTech(iVPReceived);

			-- Put up dialog box
			local popupInfo = {
				Data1 = 500,
				Type = ButtonPopupTypes.BUTTONPOPUP_TEXT,
			}

			-- Human player?
			if (iPlayer == 0) then
				popupInfo.Text = Locale.ConvertTextKey("TXT_KEY_MEDIEVAL_SCENARIO_CARAVEL", unit:GetName(), iVPReceived, (5 - iNumCaravels));
				UI.AddPopup(popupInfo);
			else
				popupInfo.Text = Locale.ConvertTextKey("TXT_KEY_MEDIEVAL_SCENARIO_OTHER_CARAVEL", player:GetName(), iVPReceived, (5 - iNumCaravels));
				UI.AddPopup(popupInfo);			
			end
		end
	end

	-- Conquistador that has reached China?
	if (unit:GetUnitType() == GameInfoTypes["UNIT_SPANISH_CONQUISTADOR"]) then

		-- Adjacent to plot owned by China?
		local bAdjacentChina = IsAdjacentToChina (iX, iY);
				
		-- How many have already been? 
		local iNumConquistadors = GetPersistentProperty("NumConquistadors");

		if (bAdjacentChina and not player:IsMinorCiv() and not player:IsBarbarian() and iNumConquistadors < 3) then

			local pTeam;
			pTeam = Teams[player:GetTeam()];
			if (pTeam:IsHasTech(GameInfoTypes["TECH_EXPLORATION"])) then
			
				iNumConquistadors = iNumConquistadors + 1;
				SetPersistentProperty("NumConquistadors", iNumConquistadors);

				unit:Kill(true, -1);

				local iGoldReceived;
				local iVPReceived;

				-- Grant gold and VP
				iGoldReceived = 500;
				iVPReceived = 250;

				player:ChangeGold(iGoldReceived);
				player:ChangeScoreFromFutureTech(iVPReceived);

				-- Put up dialog box
				local popupInfo = {
					Data1 = 500,
					Type = ButtonPopupTypes.BUTTONPOPUP_TEXT,
				}

				-- Human player?
				if (iPlayer == 0) then
					popupInfo.Text = Locale.ConvertTextKey("TXT_KEY_MEDIEVAL_SCENARIO_CONQUISTADOR", unit:GetName(), iGoldReceived, iVPReceived);
					UI.AddPopup(popupInfo);
				end
			end
		end
	end

    return true;
end);
---------------------------------------------------------
function IsAdjacentToChina (iX, iY)

	if (iX == 0) then
	    return true;
	end
	
	return false;
end
---------------------------------------------------------
GameEvents.TeamSetHasTech.Add(function(iTeam, iTech, bAdopted) 

	local iTurn = Game.GetGameTurn();

	-- Humanism adopted?
	if (iTech == GameInfoTypes["TECH_ACOUSTICS"] and GetPersistentProperty("ReformationStart") == -1) then
		SetPersistentProperty("ReformationStart", iTurn + 3);
 		SetPersistentProperty("SecondReformer", iTurn + 6);
 		SetPersistentProperty("ThirdReformer", iTurn + 9);
	end
end);
---------------------------------------------------------
GameEvents.CityConvertsReligion.Add(function(iOwner, eReligion, iX, iY)

    -- Only matters if switched to Protestant
	if (eReligion == 13) then
		local pPlayer = Players[iOwner];
		local civType = pPlayer:GetCivilizationType();
		if (civType == GameInfo.Civilizations["CIVILIZATION_FRANCE"].ID or
	    	civType == GameInfo.Civilizations["CIVILIZATION_CELTS"].ID or
	    	civType == GameInfo.Civilizations["CIVILIZATION_ENGLAND"].ID or
	    	civType == GameInfo.Civilizations["CIVILIZATION_SPAIN"].ID or
	    	civType == GameInfo.Civilizations["CIVILIZATION_NETHERLANDS"].ID or
	    	civType == GameInfo.Civilizations["CIVILIZATION_AUSTRIA"].ID or
	    	civType == GameInfo.Civilizations["CIVILIZATION_SWEDEN"].ID) then
	    	
			if (pPlayer:HasReligionInMostCities(eReligion)) then
				local bChangeMade = false;
				if (civType == GameInfo.Civilizations["CIVILIZATION_FRANCE"].ID) then
					if (GetPersistentProperty("FranceCatholic") == 1) then
						SetPersistentProperty("FranceCatholic", 0);
						bChangeMade = true;
					end		
			    elseif (civType == GameInfo.Civilizations["CIVILIZATION_CELTS"].ID) then
					if (GetPersistentProperty("CeltsCatholic") == 1) then
						SetPersistentProperty("CeltsCatholic", 0);
						bChangeMade = true;
					end		
			    elseif (civType == GameInfo.Civilizations["CIVILIZATION_ENGLAND"].ID) then
					if (GetPersistentProperty("EnglandCatholic") == 1) then
						SetPersistentProperty("EnglandCatholic", 0);
						bChangeMade = true;
					end		
			    elseif (civType == GameInfo.Civilizations["CIVILIZATION_SPAIN"].ID) then
					if (GetPersistentProperty("SpainCatholic") == 1) then
						SetPersistentProperty("SpainCatholic", 0);
						bChangeMade = true;
					end		
			    elseif (civType == GameInfo.Civilizations["CIVILIZATION_NETHERLANDS"].ID) then
					if (GetPersistentProperty("NetherlandsCatholic") == 1) then
						SetPersistentProperty("NetherlandsCatholic", 0);
						bChangeMade = true;
					end			    
			    elseif (civType == GameInfo.Civilizations["CIVILIZATION_AUSTRIA"].ID) then
					if (GetPersistentProperty("AustriaCatholic") == 1) then
						SetPersistentProperty("AustriaCatholic", 0);
						bChangeMade = true;
					end			    
				elseif (civType == GameInfo.Civilizations["CIVILIZATION_SWEDEN"].ID) then
					if (GetPersistentProperty("SwedenCatholic") == 1) then
						SetPersistentProperty("SwedenCatholic", 0);
						bChangeMade = true;
					end		
				end
				
				if (bChangeMade) then
					local popupInfo = {
						Data1 = 500,
						Type = ButtonPopupTypes.BUTTONPOPUP_TEXT,
					}
					if (Game.GetActivePlayer() == iOwner) then
						local pProtestantHolyCity = Game.GetHolyCityForReligion(GameInfoTypes["RELIGION_PROTESTANTISM"], -1);
						popupInfo.Text = Locale.ConvertTextKey("TXT_KEY_MEDIEVAL_SCENARIO_YOU_ADOPTED_PROTESTANTISM", pProtestantHolyCity:GetName());					
					else
						popupInfo.Text = Locale.ConvertTextKey("TXT_KEY_MEDIEVAL_SCENARIO_OTHER_ADOPTED_PROTESTANTISM", pPlayer:GetName());
					end
					UI.AddPopup(popupInfo);
				end
			end
	    end
	end
end);
---------------------------------------------------------
function SetupReligions()

	local ePlayer;
	local eReligion;
	local eBelief1;
	local eBelief2;
	local eBelief3;
	local eBelief4;
	local eBelief5;
	local capital;

	local iByzantinePlayer;
	local iVaticanPlayer;
	local iMeccaPlayer;
	local iJerusalemPlayer;

	local pByzantinePlot;
	local pVaticanPlot;
	local pMeccaPlot;
	local pJerusalemPlot;

	local pVaticanCity;
	local pMeccaCity;

	-- Find holy cities
	for iPlayer = 22, 46, 1 do
		local pPlayer = Players[iPlayer];
		if (pPlayer:IsAlive()) then
			local minorType = pPlayer:GetMinorCivType();
			for pCity in pPlayer:Cities() do
				if (pCity == nil) then
					print ("City State setup error");
				elseif (minorType == GameInfo.MinorCivilizations["MINOR_CIV_JERUSALEM"].ID) then
					iJerusalemPlayer = iPlayer;
					pJerusalemPlot = pCity:Plot();
					SetPersistentProperty("JerusalemX", pJerusalemPlot:GetX());
					SetPersistentProperty("JerusalemY", pJerusalemPlot:GetY());
					SetPersistentProperty("JerusalemPlayer", iPlayer);
				elseif (minorType == GameInfo.MinorCivilizations["MINOR_CIV_VATICAN_CITY"].ID) then
					iVaticanPlayer = iPlayer;
					pVaticanPlot = pCity:Plot();
					pVaticanCity = pCity;
					SetPersistentProperty("VaticanPlayer", iPlayer);
					local iBuildingID;
					iBuildingID = GameInfoTypes["BUILDING_UNITED_NATIONS"];
					pVaticanCity:SetNumRealBuilding(iBuildingID, 1);
				elseif (minorType == GameInfo.MinorCivilizations["MINOR_CIV_MECCA"].ID) then
					iMeccaPlayer = iPlayer;
					pMeccaPlot = pCity:Plot();
					pMeccaCity = pCity;
					SetPersistentProperty("MeccaPlayer", iPlayer);
				end
			end
		end
	end

   	-- First pass to set religions
	eReligion = GameInfoTypes["RELIGION_CHRISTIANITY"];
	eBelief1 = GameInfoTypes["BELIEF_PAPAL_PRIMACY"];
	eBelief2 = GameInfoTypes["BELIEF_HOLY_WARRIORS"];
	eBelief3 = GameInfoTypes["BELIEF_CATHEDRALS"];
	eBelief4 = GameInfoTypes["BELIEF_INDULGENCES"];
	eBelief5 = GameInfoTypes["BELIEF_HOLY_ORDER"];
	Game.FoundPantheon(iVaticanPlayer, eBelief1);
	Game.FoundReligion(iVaticanPlayer, eReligion, nil, eBelief2, eBelief3, -1, -1, pVaticanCity);
	Game.EnhanceReligion(iVaticanPlayer, eReligion, eBelief4, eBelief5);

	eReligion = GameInfoTypes["RELIGION_ISLAM"];
	eBelief1 = GameInfoTypes["BELIEF_TITHE"];
	eBelief2 = GameInfoTypes["BELIEF_HAJJ"];
	eBelief3 = GameInfoTypes["BELIEF_MOSQUES"];
	eBelief4 = GameInfoTypes["BELIEF_SALAT"];
	eBelief5 = GameInfoTypes["BELIEF_MISSIONARY_ZEAL"];
	Game.FoundPantheon(iMeccaPlayer, eBelief1);
	Game.FoundReligion(iMeccaPlayer, eReligion, nil, eBelief2, eBelief3, -1, -1, pMeccaCity);
	Game.EnhanceReligion(iMeccaPlayer, eReligion, eBelief4, eBelief5);

	for iPlayer = 0, 11, 1 do
		local pPlayer = Players[iPlayer];
		if (pPlayer:IsAlive()) then
			local civType = pPlayer:GetCivilizationType();
			capital = pPlayer:GetCapitalCity();
			if (capital ~= nil) then
				if (civType == GameInfo.Civilizations["CIVILIZATION_BYZANTIUM"].ID) then
					eReligion = GameInfoTypes["RELIGION_ORTHODOXY"];
					eBelief1 = GameInfoTypes["BELIEF_CHURCH_PROPERTY"];
					eBelief2 = GameInfoTypes["BELIEF_THIRD_ROME"];
					eBelief3 = GameInfoTypes["BELIEF_MONASTERIES"];
					eBelief4 = GameInfoTypes["BELIEF_ICONOGRAPHY"];
					eBelief5 = GameInfoTypes["BELIEF_ITINERANT_PREACHERS"];
					Game.FoundPantheon(iPlayer, eBelief1);
					Game.FoundReligion(iPlayer, eReligion, nil, eBelief2, eBelief3, -1, -1, capital);
					Game.EnhanceReligion(iPlayer, eReligion, eBelief4, eBelief5);
					iByzantinePlayer = iPlayer;
					pByzantinePlot = capital:Plot();
				end
			end
		end
	end
	
	-- Second pass to establish followers
	for iPlayer = 0, 11, 1 do
		local pPlayer = Players[iPlayer];
		if (pPlayer:IsAlive()) then
			local civType = pPlayer:GetCivilizationType();
			capital = pPlayer:GetCapitalCity();
			if (capital ~= nil) then
		
				if (civType == GameInfo.Civilizations["CIVILIZATION_CELTS"].ID) then
					capital:AdoptReligionFully(GameInfoTypes["RELIGION_CHRISTIANITY"]);
				elseif (civType == GameInfo.Civilizations["CIVILIZATION_ENGLAND"].ID) then
					capital:AdoptReligionFully(GameInfoTypes["RELIGION_CHRISTIANITY"]);
				elseif (civType == GameInfo.Civilizations["CIVILIZATION_FRANCE"].ID) then
					capital:AdoptReligionFully(GameInfoTypes["RELIGION_CHRISTIANITY"]);
				elseif (civType == GameInfo.Civilizations["CIVILIZATION_SPAIN"].ID) then
					capital:AdoptReligionFully(GameInfoTypes["RELIGION_CHRISTIANITY"]);
				elseif (civType == GameInfo.Civilizations["CIVILIZATION_NETHERLANDS"].ID) then
					capital:AdoptReligionFully(GameInfoTypes["RELIGION_CHRISTIANITY"]);
				elseif (civType == GameInfo.Civilizations["CIVILIZATION_AUSTRIA"].ID) then
					capital:AdoptReligionFully(GameInfoTypes["RELIGION_CHRISTIANITY"]);
				elseif (civType == GameInfo.Civilizations["CIVILIZATION_SWEDEN"].ID) then
					capital:AdoptReligionFully(GameInfoTypes["RELIGION_CHRISTIANITY"]);
				elseif (civType == GameInfo.Civilizations["CIVILIZATION_RUSSIA"].ID) then
					capital:AdoptReligionFully(GameInfoTypes["RELIGION_ORTHODOXY"]);
				elseif (civType == GameInfo.Civilizations["CIVILIZATION_ARABIA"].ID) then
					capital:AdoptReligionFully(GameInfoTypes["RELIGION_ISLAM"]);
				elseif (civType == GameInfo.Civilizations["CIVILIZATION_OTTOMAN"].ID) then
					capital:AdoptReligionFully(GameInfoTypes["RELIGION_ISLAM"]);
				elseif (civType == GameInfo.Civilizations["CIVILIZATION_SONGHAI"].ID) then
					capital:AdoptReligionFully(GameInfoTypes["RELIGION_ISLAM"]);
				end
			end
		end
	end

	-- And finally for city states
	for iPlayer = 22, 46, 1 do
		local pPlayer = Players[iPlayer];
		if (pPlayer:IsAlive()) then
			local minorType = pPlayer:GetMinorCivType();
    		
    		for pCity in pPlayer:Cities() do
				if (pCity == nil) then
					print ("City State setup error");
				elseif (minorType == GameInfo.MinorCivilizations["MINOR_CIV_WARSAW"].ID) then
					pCity:AdoptReligionFully(GameInfoTypes["RELIGION_CHRISTIANITY"]);
				elseif (minorType == GameInfo.MinorCivilizations["MINOR_CIV_BUDAPEST"].ID) then
					pCity:AdoptReligionFully(GameInfoTypes["RELIGION_CHRISTIANITY"]);
				elseif (minorType == GameInfo.MinorCivilizations["MINOR_CIV_GENEVA"].ID) then
					pCity:AdoptReligionFully(GameInfoTypes["RELIGION_CHRISTIANITY"]);
				elseif (minorType == GameInfo.MinorCivilizations["MINOR_CIV_VENICE"].ID) then
					pCity:AdoptReligionFully(GameInfoTypes["RELIGION_CHRISTIANITY"]);
				elseif (minorType == GameInfo.MinorCivilizations["MINOR_CIV_GENOA"].ID) then
					pCity:AdoptReligionFully(GameInfoTypes["RELIGION_CHRISTIANITY"]);
				elseif (minorType == GameInfo.MinorCivilizations["MINOR_CIV_FLORENCE"].ID) then
					pCity:AdoptReligionFully(GameInfoTypes["RELIGION_CHRISTIANITY"]);
				elseif (minorType == GameInfo.MinorCivilizations["MINOR_CIV_RAGUSA"].ID) then
					pCity:AdoptReligionFully(GameInfoTypes["RELIGION_CHRISTIANITY"]);
				elseif (minorType == GameInfo.MinorCivilizations["MINOR_CIV_BELGRADE"].ID) then
					pCity:AdoptReligionFully(GameInfoTypes["RELIGION_ORTHODOXY"]);
				elseif (minorType == GameInfo.MinorCivilizations["MINOR_CIV_ANTWERP"].ID) then
					pCity:AdoptReligionFully(GameInfoTypes["RELIGION_CHRISTIANITY"]);
				elseif (minorType == GameInfo.MinorCivilizations["MINOR_CIV_JERUSALEM"].ID) then
					pCity:AdoptReligionFully(GameInfoTypes["RELIGION_ISLAM"]);
				elseif (minorType == GameInfo.MinorCivilizations["MINOR_CIV_LISBON"].ID) then
					pCity:AdoptReligionFully(GameInfoTypes["RELIGION_ISLAM"]);
				elseif (minorType == GameInfo.MinorCivilizations["MINOR_CIV_MILAN"].ID) then
					pCity:AdoptReligionFully(GameInfoTypes["RELIGION_CHRISTIANITY"]);
				elseif (minorType == GameInfo.MinorCivilizations["MINOR_CIV_PRAGUE"].ID) then
					pCity:AdoptReligionFully(GameInfoTypes["RELIGION_CHRISTIANITY"]);
				elseif (minorType == GameInfo.MinorCivilizations["MINOR_CIV_VALLETTA"].ID) then
					pCity:AdoptReligionFully(GameInfoTypes["RELIGION_CHRISTIANITY"]);
				elseif (minorType == GameInfo.MinorCivilizations["MINOR_CIV_WITTENBERG"].ID) then
					pCity:AdoptReligionFully(GameInfoTypes["RELIGION_CHRISTIANITY"]);
				elseif (minorType == GameInfo.MinorCivilizations["MINOR_CIV_ZURICH"].ID) then
					pCity:AdoptReligionFully(GameInfoTypes["RELIGION_CHRISTIANITY"]);
				elseif (minorType == GameInfo.MinorCivilizations["MINOR_CIV_TUNIS"].ID) then
					pCity:AdoptReligionFully(GameInfoTypes["RELIGION_ISLAM"]);
				elseif (minorType == GameInfo.MinorCivilizations["MINOR_CIV_COLOGNE"].ID) then
					pCity:AdoptReligionFully(GameInfoTypes["RELIGION_CHRISTIANITY"]);
				elseif (minorType == GameInfo.MinorCivilizations["MINOR_CIV_AUGSBURG"].ID) then
					pCity:AdoptReligionFully(GameInfoTypes["RELIGION_CHRISTIANITY"]);
				elseif (minorType == GameInfo.MinorCivilizations["MINOR_CIV_NAPLES"].ID) then
					pCity:AdoptReligionFully(GameInfoTypes["RELIGION_CHRISTIANITY"]);
				end
			end
		end
	end

	-- Finally make sure everyone has contact with their holy city
	local byzantineTeamID = Players[iByzantinePlayer]:GetTeam();
	local vaticanTeamID = Players[iVaticanPlayer]:GetTeam();
	local meccaTeamID = Players[iMeccaPlayer]:GetTeam();
	local jerusalemTeamID = Players[iJerusalemPlayer]:GetTeam();
	for iPlayer = 0, 11, 1 do
		local pPlayer = Players[iPlayer];
		if (pPlayer:IsAlive()) then
			local civType = pPlayer:GetCivilizationType();
			local iTeam = pPlayer:GetTeam();
			local pTeam = Teams[iTeam];
			if (civType == GameInfo.Civilizations["CIVILIZATION_CELTS"].ID) then
				pTeam:Meet(vaticanTeamID, true);
				RevealPlotAndAdjacent(pVaticanPlot, iTeam);
			elseif (civType == GameInfo.Civilizations["CIVILIZATION_ENGLAND"].ID) then
				pTeam:Meet(vaticanTeamID, true);
				RevealPlotAndAdjacent(pVaticanPlot, iTeam);
			elseif (civType == GameInfo.Civilizations["CIVILIZATION_SPAIN"].ID) then
				pTeam:Meet(vaticanTeamID, true);
				RevealPlotAndAdjacent(pVaticanPlot, iTeam);
			elseif (civType == GameInfo.Civilizations["CIVILIZATION_NETHERLANDS"].ID) then
				pTeam:Meet(vaticanTeamID, true);
				RevealPlotAndAdjacent(pVaticanPlot, iTeam);
			elseif (civType == GameInfo.Civilizations["CIVILIZATION_AUSTRIA"].ID) then
				pTeam:Meet(vaticanTeamID, true);
				RevealPlotAndAdjacent(pVaticanPlot, iTeam);
			elseif (civType == GameInfo.Civilizations["CIVILIZATION_SWEDEN"].ID) then
				pTeam:Meet(vaticanTeamID, true);
				RevealPlotAndAdjacent(pVaticanPlot, iTeam);
			elseif (civType == GameInfo.Civilizations["CIVILIZATION_FRANCE"].ID) then
				pTeam:Meet(vaticanTeamID, true);
				RevealPlotAndAdjacent(pVaticanPlot, iTeam);
			elseif (civType == GameInfo.Civilizations["CIVILIZATION_RUSSIA"].ID) then
				pTeam:Meet(byzantineTeamID, true);
				RevealPlotAndAdjacent(pByzantinePlot, iTeam);
			elseif (civType == GameInfo.Civilizations["CIVILIZATION_SONGHAI"].ID) then
				pTeam:Meet(meccaTeamID, true);
				RevealPlotAndAdjacent(pMeccaPlot, iTeam);
			elseif (civType == GameInfo.Civilizations["CIVILIZATION_ARABIA"].ID) then
				pTeam:Meet(meccaTeamID, true);
				RevealPlotAndAdjacent(pMeccaPlot, iTeam);
			elseif (civType == GameInfo.Civilizations["CIVILIZATION_OTTOMAN"].ID) then
				pTeam:Meet(meccaTeamID, true);
				RevealPlotAndAdjacent(pMeccaPlot, iTeam);
			end

			-- Always reveal Jerusalem
			pTeam:Meet(jerusalemTeamID, true);
			RevealPlotAndAdjacent(pJerusalemPlot, iTeam);
		end
	end
	
	-- Set which civs are Catholic
	SetPersistentProperty("CeltsCatholic", 1);
	SetPersistentProperty("EnglandCatholic", 1);
	SetPersistentProperty("FranceCatholic", 1);
	SetPersistentProperty("SpainCatholic", 1);
	SetPersistentProperty("NetherlandsCatholic", 1);
	SetPersistentProperty("SwedenCatholic", 1);
	SetPersistentProperty("AustriaCatholic", 1);
end

---------------------------------------------------------
function RevealPlotAndAdjacent(pPlot, iTeam)

	print ("Team: ", iTeam, "; Revealing x: ", pPlot:GetX(), ", y: ", pPlot:GetY());

	pPlot:SetRevealed(iTeam, true);

	local numDirections = DirectionTypes.NUM_DIRECTION_TYPES;
	for direction = 0, numDirections - 1, 1 do
		local adjPlot = Map.PlotDirection(pPlot:GetX(), pPlot:GetY(), direction);
		if (adjPlot ~= nil) then
			adjPlot:SetRevealed(iTeam, true);
		end
     end
end
	
---------------------------------------------------------
function AddInitialUnits(iPlayer)
	
	local pPlayer = Players[iPlayer];
	if (pPlayer:IsAlive()) then
		local capital = pPlayer:GetCapitalCity();
		
		print ("AddInitialUnits, iPlayer: ", iPlayer);
	
		-- Historical map
		if (capital ~= nil) then
		
			print ("Have a capital");

			iUnitID = GameInfoTypes["UNIT_WORKER"];
			unit = pPlayer:InitUnit (iUnitID, capital:GetX(), capital:GetY(), UNITAI_WORKER, DirectionTypes.DIRECTION_EAST);
			unit:JumpToNearestValidPlot();

			iUnitID = GameInfoTypes["UNIT_SWORDSMAN"];
			unit = pPlayer:InitUnit (iUnitID, capital:GetX(), capital:GetY(), UNITAI_DEFENSE, DirectionTypes.DIRECTION_EAST);
			unit:JumpToNearestValidPlot();

		-- Random map
		else
			local startPlot = pPlayer:GetStartingPlot();
			local capital = pPlayer:InitCity(startPlot:GetX(), startPlot:GetY());
			
			print ("Establishing capital at (x, y): ", startPlot:GetX(), startPlot:GetY());
			
			capital:SetPopulation(5, true);
			
			local iNumUnits = startPlot:GetNumUnits();
			local pUnit;
			for i = 0, iNumUnits do
				pUnit = startPlot:GetUnit(i);
				if (pUnit ~= nil and pUnit:IsFound()) then
					pUnit:Kill();
				end
			end
						
			local iBuildingID;
			iBuildingID = GameInfoTypes["BUILDING_PALACE"];
			capital:SetNumRealBuilding(iBuildingID, 1);
			iBuildingID = GameInfoTypes["BUILDING_MONUMENT"];
			capital:SetNumRealBuilding(iBuildingID, 1);
			iBuildingID = GameInfoTypes["BUILDING_SHRINE"];
			capital:SetNumRealBuilding(iBuildingID, 1);
			iBuildingID = GameInfoTypes["BUILDING_GRANARY"];
			capital:SetNumRealBuilding(iBuildingID, 1);
			iBuildingID = GameInfoTypes["BUILDING_WALLS"];
			capital:SetNumRealBuilding(iBuildingID, 1);
			if (pPlayer:GetCivilizationType() == GameInfoTypes["CIVILIZATION_RUSSIA"]) then
				iBuildingID = GameInfoTypes["BUILDING_KREPOST"];
			else
				iBuildingID = GameInfoTypes["BUILDING_BARRACKS"];
			end
			capital:SetNumRealBuilding(iBuildingID, 1);
			iBuildingID = GameInfoTypes["BUILDING_LIBRARY"];
			capital:SetNumRealBuilding(iBuildingID, 1);
			if (pPlayer:GetCivilizationType() == GameInfoTypes["CIVILIZATION_ARABIA"]) then
				iBuildingID = GameInfoTypes["BUILDING_BAZAAR"];
			else
				iBuildingID = GameInfoTypes["BUILDING_MARKET"];
			end
			capital:SetNumRealBuilding(iBuildingID, 1);
			if (pPlayer:GetCivilizationType() == GameInfoTypes["CIVILIZATION_SONGHAI"]) then
				iBuildingID = GameInfoTypes["BUILDING_PYRAMID"];
			end
			capital:SetNumRealBuilding(iBuildingID, 1);
		end
	end
end

---------------------------------------------------------
function InitializeCityState(iPlayer)

	local pPlayer = Players[iPlayer];
	local capital = pPlayer:GetCapitalCity();
	local startPlot = pPlayer:GetStartingPlot();

	-- Random map only
	if (pPlayer:IsAlive() and pPlayer:GetNumCities() == 0) then
		
		local cityState = pPlayer:InitCity(startPlot:GetX(), startPlot:GetY());
		cityState:SetPopulation(3, true);
	
		local iBuildingID;
		iBuildingID = GameInfoTypes["BUILDING_MONUMENT"];
		cityState:SetNumRealBuilding(iBuildingID, 1);
		iBuildingID = GameInfoTypes["BUILDING_SHRINE"];
		cityState:SetNumRealBuilding(iBuildingID, 1);
		iBuildingID = GameInfoTypes["BUILDING_GRANARY"];
		cityState:SetNumRealBuilding(iBuildingID, 1);
		iBuildingID = GameInfoTypes["BUILDING_WALLS"];
		cityState:SetNumRealBuilding(iBuildingID, 1);
		
		for pUnit in pPlayer:Units() do
			pUnit:Kill();
		end
	end
	
	if (pPlayer:GetMinorCivType() == GameInfoTypes["MINOR_CIV_WITTENBERG"]) then
		SetWittenbergLocation(startPlot:GetX(), startPlot:GetY());

	elseif (pPlayer:GetMinorCivType() == GameInfoTypes["MINOR_CIV_ZURICH"]) then
		SetZurichLocation(startPlot:GetX(), startPlot:GetY());
			
	elseif (pPlayer:GetMinorCivType() == GameInfoTypes["MINOR_CIV_GENEVA"]) then
		SetGenevaLocation(startPlot:GetX(), startPlot:GetY());
	
	elseif (pPlayer:GetMinorCivType() == GameInfoTypes["MINOR_CIV_VATICAN_CITY"]) then
		SetVaticanLocation(startPlot:GetX(), startPlot:GetY());
	
	end
end

---------------------------------------------------------------------
function ScoreHolyCities()

	local jerusalemX = GetPersistentProperty("JerusalemX");
	local jerusalemY = GetPersistentProperty("JerusalemY");
	local pJerusalem = Map.GetPlot(jerusalemX,jerusalemY):GetPlotCity();
	local iJerusalemPlayer = GetPersistentProperty("JerusalemPlayer");
	local pJerusalemPlayer = Players[iJerusalemPlayer];
	local iJerusalemAlly = pJerusalemPlayer:GetAlly();

	for iPlayerLoop = 0, GameDefines.MAX_MAJOR_CIVS-1, 1 do
		local pPlayer = Players[iPlayerLoop];
		if (pPlayer:IsAlive()) then
	
			local civType = pPlayer:GetCivilizationType();
			if (civType == GameInfo.Civilizations["CIVILIZATION_BYZANTIUM"].ID or
			    civType == GameInfo.Civilizations["CIVILIZATION_RUSSIA"].ID) then

				if (Game.GetFounder(GameInfoTypes["RELIGION_ORTHODOXY"], -1) == iPlayerLoop) then
					pPlayer:ChangeScoreFromFutureTech(10);
				elseif (pJerusalem:GetOwner() == iPlayerLoop or iJerusalemAlly == iPlayerLoop) then
					pPlayer:ChangeScoreFromFutureTech(10);
				end

			elseif (civType == GameInfo.Civilizations["CIVILIZATION_SONGHAI"].ID or
			    	civType == GameInfo.Civilizations["CIVILIZATION_OTTOMAN"].ID or
			    	civType == GameInfo.Civilizations["CIVILIZATION_ARABIA"].ID) then

				if (Game.GetFounder(GameInfoTypes["RELIGION_ISLAM"], -1) == iPlayerLoop) then
					pPlayer:ChangeScoreFromFutureTech(10);
				elseif (pJerusalem:GetOwner() == iPlayerLoop or iJerusalemAlly == iPlayerLoop) then
					pPlayer:ChangeScoreFromFutureTech(10);
				end

			elseif (MyCurrentReligion(iPlayerLoop) == 2 and
					(civType == GameInfo.Civilizations["CIVILIZATION_FRANCE"].ID or
			    	 civType == GameInfo.Civilizations["CIVILIZATION_CELTS"].ID or
			    	 civType == GameInfo.Civilizations["CIVILIZATION_ENGLAND"].ID or
			    	 civType == GameInfo.Civilizations["CIVILIZATION_SPAIN"].ID or
			    	 civType == GameInfo.Civilizations["CIVILIZATION_NETHERLANDS"].ID or
			    	 civType == GameInfo.Civilizations["CIVILIZATION_AUSTRIA"].ID or
			    	 civType == GameInfo.Civilizations["CIVILIZATION_SWEDEN"].ID)) then

				if (Game.GetFounder(GameInfoTypes["RELIGION_CHRISTIANITY"], -1) == iPlayerLoop) then
					pPlayer:ChangeScoreFromFutureTech(10);
				elseif (pJerusalem:GetOwner() == iPlayerLoop or iJerusalemAlly == iPlayerLoop) then
					pPlayer:ChangeScoreFromFutureTech(10);
				end

			elseif (MyCurrentReligion(iPlayerLoop) == 13 and
					(civType == GameInfo.Civilizations["CIVILIZATION_FRANCE"].ID or
			    	 civType == GameInfo.Civilizations["CIVILIZATION_CELTS"].ID or
			    	 civType == GameInfo.Civilizations["CIVILIZATION_ENGLAND"].ID or
			    	 civType == GameInfo.Civilizations["CIVILIZATION_SPAIN"].ID or
			    	 civType == GameInfo.Civilizations["CIVILIZATION_NETHERLANDS"].ID or
			    	 civType == GameInfo.Civilizations["CIVILIZATION_AUSTRIA"].ID or
			    	 civType == GameInfo.Civilizations["CIVILIZATION_SWEDEN"].ID)) then

				if (Game.GetFounder(GameInfoTypes["RELIGION_PROTESTANTISM"], -1) == iPlayerLoop) then
					pPlayer:ChangeScoreFromFutureTech(10);
				elseif (pJerusalem:GetOwner() == iPlayerLoop or iJerusalemAlly == iPlayerLoop) then
					pPlayer:ChangeScoreFromFutureTech(10);
				end
			end									
		end
	end
end

---------------------------------------------------------------------
function BringInMongols()

		FindMongolStartPlot();
		
		local iX = GetPersistentProperty("MongolStartX");
		local iY = GetPersistentProperty("MongolStartY");
		
		local start_plot = Map.GetPlot(iX, iY);
		local pPlayer = Players[12];
		pTeam = Teams[pPlayer:GetTeam()];
		pPlayer:SetStartingPlot(start_plot);

		local capital = pPlayer:InitCity(start_plot:GetX(), start_plot:GetY());
		capital:SetPopulation(5, true);
			
		local iBuildingID;
		iBuildingID = GameInfoTypes["BUILDING_PALACE"];
		capital:SetNumRealBuilding(iBuildingID, 1);
		iBuildingID = GameInfoTypes["BUILDING_MONUMENT"];
		capital:SetNumRealBuilding(iBuildingID, 1);
		iBuildingID = GameInfoTypes["BUILDING_SHRINE"];
		capital:SetNumRealBuilding(iBuildingID, 1);
		iBuildingID = GameInfoTypes["BUILDING_GRANARY"];
		capital:SetNumRealBuilding(iBuildingID, 1);
		iBuildingID = GameInfoTypes["BUILDING_WALLS"];
		capital:SetNumRealBuilding(iBuildingID, 1);
		iBuildingID = GameInfoTypes["BUILDING_BARRACKS"];
		capital:SetNumRealBuilding(iBuildingID, 1);
		iBuildingID = GameInfoTypes["BUILDING_LIBRARY"];
		capital:SetNumRealBuilding(iBuildingID, 1);
		iBuildingID = GameInfoTypes["BUILDING_MARKET"];
		capital:SetNumRealBuilding(iBuildingID, 1);
		
		local iTechIndex = GameInfoTypes["TECH_CHIVALRY"];
		pTeam:SetHasTech(iTechIndex, true);
		
		iUnitID = GameInfoTypes["UNIT_SETTLER"];
		unit = pPlayer:InitUnit (iUnitID, capital:GetX(), capital:GetY(), UNITAI_SETTLE, DirectionTypes.DIRECTION_WEST);
		unit:JumpToNearestValidPlot();

		iUnitID = GameInfoTypes["UNIT_SETTLER"];
		unit = pPlayer:InitUnit (iUnitID, capital:GetX(), capital:GetY(), UNITAI_SETTLE, DirectionTypes.DIRECTION_WEST);
		unit:JumpToNearestValidPlot();

		iUnitID = GameInfoTypes["UNIT_SETTLER"];
		unit = pPlayer:InitUnit (iUnitID, capital:GetX(), capital:GetY(), UNITAI_SETTLE, DirectionTypes.DIRECTION_WEST);
		unit:JumpToNearestValidPlot();

		iUnitID = GameInfoTypes["UNIT_WORKER"];
		unit = pPlayer:InitUnit (iUnitID, capital:GetX(), capital:GetY(), UNITAI_WORKER, DirectionTypes.DIRECTION_WEST);
		unit:JumpToNearestValidPlot();

		iUnitID = GameInfoTypes["UNIT_WORKER"];
		unit = pPlayer:InitUnit (iUnitID, capital:GetX(), capital:GetY(), UNITAI_WORKER, DirectionTypes.DIRECTION_WEST);
		unit:JumpToNearestValidPlot();

		iUnitID = GameInfoTypes["UNIT_WORKER"];
		unit = pPlayer:InitUnit (iUnitID, capital:GetX(), capital:GetY(), UNITAI_WORKER, DirectionTypes.DIRECTION_WEST);
		unit:JumpToNearestValidPlot();

		iUnitID = GameInfoTypes["UNIT_SWORDSMAN"];
		unit = pPlayer:InitUnit (iUnitID, capital:GetX(), capital:GetY(), UNITAI_DEFENSE, DirectionTypes.DIRECTION_WEST);
		unit:JumpToNearestValidPlot();

		iUnitID = GameInfoTypes["UNIT_SWORDSMAN"];
		unit = pPlayer:InitUnit (iUnitID, capital:GetX(), capital:GetY(), UNITAI_DEFENSE, DirectionTypes.DIRECTION_WEST);
		unit:JumpToNearestValidPlot();

		iUnitID = GameInfoTypes["UNIT_SWORDSMAN"];
		unit = pPlayer:InitUnit (iUnitID, capital:GetX(), capital:GetY(), UNITAI_DEFENSE, DirectionTypes.DIRECTION_WEST);
		unit:JumpToNearestValidPlot();
		
		iUnitID = GameInfoTypes["UNIT_MONGOLIAN_KHAN"];
		unit = pPlayer:InitUnit (iUnitID, capital:GetX(), capital:GetY(), UNITAI_GENERAL, DirectionTypes.DIRECTION_WEST);
		unit:JumpToNearestValidPlot();
	
		iUnitID = GameInfoTypes["UNIT_MONGOLIAN_KESHIK"];
		unit = pPlayer:InitUnit (iUnitID, capital:GetX(), capital:GetY(), UNITAI_RANGED, DirectionTypes.DIRECTION_WEST);
		unit:JumpToNearestValidPlot();

		iUnitID = GameInfoTypes["UNIT_MONGOLIAN_KESHIK"];
		unit = pPlayer:InitUnit (iUnitID, capital:GetX(), capital:GetY(), UNITAI_RANGED, DirectionTypes.DIRECTION_WEST);
		unit:JumpToNearestValidPlot();

		iUnitID = GameInfoTypes["UNIT_MONGOLIAN_KESHIK"];
		unit = pPlayer:InitUnit (iUnitID, capital:GetX(), capital:GetY(), UNITAI_RANGED, DirectionTypes.DIRECTION_WEST);
		unit:JumpToNearestValidPlot();

		iUnitID = GameInfoTypes["UNIT_MONGOLIAN_KESHIK"];
		unit = pPlayer:InitUnit (iUnitID, capital:GetX(), capital:GetY(), UNITAI_RANGED, DirectionTypes.DIRECTION_WEST);
		unit:JumpToNearestValidPlot();

		iUnitID = GameInfoTypes["UNIT_MONGOLIAN_KESHIK"];
		unit = pPlayer:InitUnit (iUnitID, capital:GetX(), capital:GetY(), UNITAI_RANGED, DirectionTypes.DIRECTION_WEST);
		unit:JumpToNearestValidPlot();

		iUnitID = GameInfoTypes["UNIT_MONGOLIAN_KESHIK"];
		unit = pPlayer:InitUnit (iUnitID, capital:GetX(), capital:GetY(), UNITAI_RANGED, DirectionTypes.DIRECTION_WEST);
		unit:JumpToNearestValidPlot();	
		
		iUnitID = GameInfoTypes["UNIT_CATAPULT"];
		unit = pPlayer:InitUnit (iUnitID, capital:GetX(), capital:GetY(), UNITAI_RANGED, DirectionTypes.DIRECTION_WEST);
		unit:JumpToNearestValidPlot();
end

---------------------------------------------------------------------
function FindMongolStartPlot()
		
		local bestX = 78;
		local bestY = 53;
		
		if (not AreAllAdjacentUnoccupied(bestX, bestY)) then
		
			-- Go North 10 plots
			for iY = bestY + 1, bestY + 10, 1 do			
				if (AreAllAdjacentUnoccupied(bestX, iY)) then
					SetPersistentProperty("MongolStartX", bestX);
					SetPersistentProperty("MongolStartY", iY);
					return true;
				end
			end
			
			-- Go South 10 plots
			for iY = bestY - 1, bestY - 10, -1 do			
				if (AreAllAdjacentUnoccupied(bestX, iY)) then
					SetPersistentProperty("MongolStartX", bestX);
					SetPersistentProperty("MongolStartY", iY);
					return true;
				end
			end			
			
			-- Go North 20 more plots		
			for iY = bestY + 11, bestY + 30, 1 do			
				if (AreAllAdjacentUnoccupied(bestX, iY)) then
					SetPersistentProperty("MongolStartX", bestX);
					SetPersistentProperty("MongolStartY", iY);
					return true;
				end
			end
					
			-- Go South 20 more plots
			for iY = bestY - 11, bestY -30, -1 do			
				if (AreAllAdjacentUnoccupied(bestX, iY)) then
					SetPersistentProperty("MongolStartX", bestX);
					SetPersistentProperty("MongolStartY", iY);
					return true;
				end
			end	
			
			return false;		
		end
		
		SetPersistentProperty("MongolStartX", bestX);
		SetPersistentProperty("MongolStartY", bestY);
		return true;
end

---------------------------------------------------------------------
function AreAllAdjacentUnoccupied(iX, iY)
		
	local plot = Map.GetPlot(iX,iY);
	if (plot:GetOwner() ~= -1) then
		return false;
	elseif (plot:GetUnit(0) ~= nil) then
		return false;
	elseif (plot:IsWater()) then
		return false;
	end
		
	local numDirections = DirectionTypes.NUM_DIRECTION_TYPES;
	for direction = 0, numDirections - 1, 1 do
		local adjPlot = Map.PlotDirection(iX, iY, direction);
		if (adjPlot ~= nil) then
			if (adjPlot:GetOwner() ~= -1) then
				return false;
			elseif (adjPlot:GetUnit(0) ~= nil) then
				return false;
			elseif (adjPlot:IsWater()) then
				return false;
			end
		else
			return false;
		end
	end
	
	return true;
end

---------------------------------------------------------------------
function ReinforceMongols()

		local pPlayer = Players[12];
		local capital = pPlayer:GetCapitalCity();
		
		iUnitID = GameInfoTypes["UNIT_SWORDSMAN"];
		unit = pPlayer:InitUnit (iUnitID, capital:GetX(), capital:GetY(), UNITAI_DEFENSE, DirectionTypes.DIRECTION_WEST);
		unit:JumpToNearestValidPlot();

		iUnitID = GameInfoTypes["UNIT_SWORDSMAN"];
		unit = pPlayer:InitUnit (iUnitID, capital:GetX(), capital:GetY(), UNITAI_DEFENSE, DirectionTypes.DIRECTION_WEST);
		unit:JumpToNearestValidPlot();
		
		iUnitID = GameInfoTypes["UNIT_MONGOLIAN_KHAN"];
		unit = pPlayer:InitUnit (iUnitID, capital:GetX(), capital:GetY(), UNITAI_GENERAL, DirectionTypes.DIRECTION_WEST);
		unit:JumpToNearestValidPlot();
	
		iUnitID = GameInfoTypes["UNIT_MONGOLIAN_KESHIK"];
		unit = pPlayer:InitUnit (iUnitID, capital:GetX(), capital:GetY(), UNITAI_RANGED, DirectionTypes.DIRECTION_WEST);
		unit:JumpToNearestValidPlot();

		iUnitID = GameInfoTypes["UNIT_MONGOLIAN_KESHIK"];
		unit = pPlayer:InitUnit (iUnitID, capital:GetX(), capital:GetY(), UNITAI_RANGED, DirectionTypes.DIRECTION_WEST);
		unit:JumpToNearestValidPlot();

		iUnitID = GameInfoTypes["UNIT_MONGOLIAN_KESHIK"];
		unit = pPlayer:InitUnit (iUnitID, capital:GetX(), capital:GetY(), UNITAI_RANGED, DirectionTypes.DIRECTION_WEST);
		unit:JumpToNearestValidPlot();

		iUnitID = GameInfoTypes["UNIT_CATAPULT"];
		unit = pPlayer:InitUnit (iUnitID, capital:GetX(), capital:GetY(), UNITAI_RANGED, DirectionTypes.DIRECTION_WEST);
		unit:JumpToNearestValidPlot();

		iUnitID = GameInfoTypes["UNIT_SETTLER"];
		unit = pPlayer:InitUnit (iUnitID, capital:GetX(), capital:GetY(), UNITAI_SETTLE, DirectionTypes.DIRECTION_WEST);
		unit:JumpToNearestValidPlot();
end

---------------------------------------------------------------------
function MongolsPullOut()

end

---------------------------------------------------------------------
function StartReformation()

	local eReligion;
	local eBelief1;
	local eBelief2;
	local eBelief3;
	local eBelief4;
	local eBelief5;
	
	local pBestCity = GetBestCity(GetWittenbergLocation());
	if (pBestCity ~= nil) then
		local iPlayer = pBestCity:GetOwner();
	
		eReligion = GameInfoTypes["RELIGION_PROTESTANTISM"];
		eBelief1 = GameInfoTypes["BELIEF_CHORAL_MUSIC"];
		eBelief2 = GameInfoTypes["BELIEF_WORK_ETHIC"];
		eBelief3 = GameInfoTypes["BELIEF_CLERICAL_MARRIAGE"];
		eBelief4 = GameInfoTypes["BELIEF_MESSIAH"];
		eBelief5 = GameInfoTypes["BELIEF_RELIGIOUS_TEXTS"];
		Game.FoundReligion(iPlayer, eReligion, nil, eBelief1, eBelief2, eBelief3, -1, pBestCity);
		Game.EnhanceReligion(iPlayer, eReligion, eBelief4, eBelief5);
	
		pBestCity:AdoptReligionFully(eReligion);
		ConvertCatholicsNearby(pBestCity);
	
		local popupInfo = {
			Data1 = 500,
			Type = ButtonPopupTypes.BUTTONPOPUP_TEXT,
		}
		popupInfo.Text = Locale.ConvertTextKey("TXT_KEY_MEDIEVAL_SCENARIO_FIRST_REFORMER", pBestCity:GetName());
		UI.AddPopup(popupInfo);
		
		SetPersistentProperty("ProtestantHolyCityPlayer", iPlayer);
	end
end

---------------------------------------------------------------------
function ReformationPhaseTwo()
	local pBestCity = GetBestCity(GetZurichLocation());
	if (pBestCity ~= nil) then
		pBestCity:AdoptReligionFully(GameInfoTypes["RELIGION_PROTESTANTISM"]);
		ConvertCatholicsNearby(pBestCity);
	
		local popupInfo = {
			Data1 = 500,
			Type = ButtonPopupTypes.BUTTONPOPUP_TEXT,
		}

		popupInfo.Text = Locale.ConvertTextKey("TXT_KEY_MEDIEVAL_SCENARIO_SECOND_REFORMER", pBestCity:GetName());
		UI.AddPopup(popupInfo);
	end
end

---------------------------------------------------------------------
function ReformationPhaseThree()
	local pBestCity = GetBestCity(GetGenevaLocation());
	if (pBestCity ~= nil) then
		pBestCity:AdoptReligionFully(GameInfoTypes["RELIGION_PROTESTANTISM"]);
		ConvertCatholicsNearby(pBestCity);
		
		local popupInfo = {
			Data1 = 500,
			Type = ButtonPopupTypes.BUTTONPOPUP_TEXT,
		}

		popupInfo.Text = Locale.ConvertTextKey("TXT_KEY_MEDIEVAL_SCENARIO_THIRD_REFORMER", pBestCity:GetName());
		UI.AddPopup(popupInfo);
	end
end

---------------------------------------------------------------------
function GetBestCity(iX, iY)

	local bUseable = true;
	local pCity = Map.GetPlot(iX, iY):GetPlotCity();
	
	-- Owned by a major?
	if (pCity:GetOwner() < 12) then
		bUseable = false;
	-- Still Catholic?
	elseif (pCity:GetReligiousMajority() ~= GameInfoTypes["RELIGION_CHRISTIANITY"]) then
		bUseable = false;
	end
	
	if (bUseable) then
		return pCity;
	else
		-- Search through the minor players
		
		local zurichX, zurichY = GetZurichLocation();
		local genevaX, genevaY = GetGenevaLocation();
		
		for iPlayer = 22, 46, 1 do
			pPlayer = Players[iPlayer];
			if (pPlayer:IsAlive()) then
				bUseable = true;
				
				print (iPlayer);
				
				pCity = pPlayer:GetCapitalCity();
				if (pCity ~= nil) then
					if (pCity:GetOwner() < 12) then
						bUseable = false;
					elseif (pCity:GetReligiousMajority() ~= GameInfoTypes["RELIGION_CHRISTIANITY"]) then
						bUseable = false;
					-- Not one we'll use later?
					elseif (pCity:GetX() == zurichX and pCity:GetY() == zurichY) then
					    bUseable = false;
					elseif (pCity:GetX() == genevaX and pCity:GetY() == genevaY) then
					    bUseable = false;					    
					end
					if (bUseable) then
						return pCity;
					end
				end
			end
		end
	end
end
---------------------------------------------------------------------
function ConvertCatholicsNearby(pReformerCity)

	for iPlayer = 0, 46, 1 do
		local pPlayer = Players[iPlayer];
		if (pPlayer:IsAlive()) then
			for cityIndex = 0, pPlayer:GetNumCities() - 1, 1 do
    			local pCity = pPlayer:GetCityByID(cityIndex);
    			if (Map.PlotDistance(pReformerCity:GetX(), pReformerCity:GetY(), pCity:GetX(), pCity:GetY()) <= 10) then
					pCity:ConvertPercentFollowers(GameInfoTypes["RELIGION_PROTESTANTISM"], GameInfoTypes["RELIGION_CHRISTIANITY"], 40);
    			end
			end
		end
	end 
end

---------------------------------------------------------------------
function AddUnitsPerDifficulty(iPlayer)

	local iHandicap = Game:GetHandicapType();
	local iUnitID;
	local unit;
	local pPlayer = Players[iPlayer];
	local capital = pPlayer:GetCapitalCity();
	
	if (not pPlayer:IsAlive()) then
		return;
	end
	
    print ("AddUnitsPerDifficulty, iPlayer: ", iPlayer);
    print ("Capital is at (x, y): ", capital:GetX(), capital:GetY());

	-- Human
	if (iPlayer == 0) then
	
		if (iHandicap <= 2) then
			pPlayer:SetJONSCulture(125);
			pPlayer:SetFaith(125);
			pPlayer:SetGold(250)
			iUnitID = GameInfoTypes["UNIT_SETTLER"];
			unit = pPlayer:InitUnit (iUnitID, capital:GetX(), capital:GetY(), UNITAI_SETTLE, DirectionTypes.DIRECTION_EAST);
			unit:JumpToNearestValidPlot();
			iUnitID = GameInfoTypes["UNIT_SETTLER"];
			unit = pPlayer:InitUnit (iUnitID, capital:GetX(), capital:GetY(), UNITAI_SETTLE, DirectionTypes.DIRECTION_EAST);
			unit:JumpToNearestValidPlot();
			iUnitID = GameInfoTypes["UNIT_SWORDSMAN"];
			unit = pPlayer:InitUnit (iUnitID, capital:GetX(), capital:GetY(), UNITAI_DEFENSE, DirectionTypes.DIRECTION_EAST);
			unit:JumpToNearestValidPlot();
			iUnitID = GameInfoTypes["UNIT_SWORDSMAN"];
			unit = pPlayer:InitUnit (iUnitID, capital:GetX(), capital:GetY(), UNITAI_DEFENSE, DirectionTypes.DIRECTION_EAST);
			unit:JumpToNearestValidPlot();
		elseif (iHandicap == 3) then
			pPlayer:SetJONSCulture(125);
			pPlayer:SetFaith(100);
			pPlayer:SetGold(200)
			iUnitID = GameInfoTypes["UNIT_SETTLER"];
			unit = pPlayer:InitUnit (iUnitID, capital:GetX(), capital:GetY(), UNITAI_SETTLE, DirectionTypes.DIRECTION_EAST);
			unit:JumpToNearestValidPlot();
			iUnitID = GameInfoTypes["UNIT_SETTLER"];
			unit = pPlayer:InitUnit (iUnitID, capital:GetX(), capital:GetY(), UNITAI_SETTLE, DirectionTypes.DIRECTION_EAST);
			unit:JumpToNearestValidPlot();
		elseif (iHandicap == 4) then
			pPlayer:SetJONSCulture(125);
			pPlayer:SetFaith(75);
			pPlayer:SetGold(150)
			iUnitID = GameInfoTypes["UNIT_SETTLER"];
			unit = pPlayer:InitUnit (iUnitID, capital:GetX(), capital:GetY(), UNITAI_SETTLE, DirectionTypes.DIRECTION_EAST);
			unit:JumpToNearestValidPlot();
			iUnitID = GameInfoTypes["UNIT_SWORDSMAN"];
			unit = pPlayer:InitUnit (iUnitID, capital:GetX(), capital:GetY(), UNITAI_DEFENSE, DirectionTypes.DIRECTION_EAST);
			unit:JumpToNearestValidPlot();
		elseif (iHandicap == 5) then
			pPlayer:SetJONSCulture(125);
			pPlayer:SetFaith(50);
			pPlayer:SetGold(100)
			iUnitID = GameInfoTypes["UNIT_SETTLER"];
			unit = pPlayer:InitUnit (iUnitID, capital:GetX(), capital:GetY(), UNITAI_SETTLE, DirectionTypes.DIRECTION_EAST);
			unit:JumpToNearestValidPlot();
		elseif (iHandicap == 6) then
			pPlayer:SetJONSCulture(125);
			pPlayer:SetFaith(25);
			pPlayer:SetGold(50)
			iUnitID = GameInfoTypes["UNIT_SWORDSMAN"];
			unit = pPlayer:InitUnit (iUnitID, capital:GetX(), capital:GetY(), UNITAI_DEFENSE, DirectionTypes.DIRECTION_EAST);
			unit:JumpToNearestValidPlot();
		elseif (iHandicap == 7) then
			pPlayer:SetJONSCulture(125);
			pPlayer:SetFaith(15);
			pPlayer:SetGold(30)
		end

	-- AI
	else
		if (iHandicap <= 2) then
			pPlayer:SetJONSCulture(125);
			pPlayer:SetFaith(125);
			pPlayer:SetGold(250)
			iUnitID = GameInfoTypes["UNIT_SETTLER"];
			unit = pPlayer:InitUnit (iUnitID, capital:GetX(), capital:GetY(), UNITAI_SETTLE, DirectionTypes.DIRECTION_EAST);
			unit:JumpToNearestValidPlot();
			iUnitID = GameInfoTypes["UNIT_SETTLER"];
			unit = pPlayer:InitUnit (iUnitID, capital:GetX(), capital:GetY(), UNITAI_SETTLE, DirectionTypes.DIRECTION_EAST);
			unit:JumpToNearestValidPlot();
			iUnitID = GameInfoTypes["UNIT_SWORDSMAN"];
			unit = pPlayer:InitUnit (iUnitID, capital:GetX(), capital:GetY(), UNITAI_DEFENSE, DirectionTypes.DIRECTION_EAST);
			unit:JumpToNearestValidPlot();
			iUnitID = GameInfoTypes["UNIT_SWORDSMAN"];
			unit = pPlayer:InitUnit (iUnitID, capital:GetX(), capital:GetY(), UNITAI_DEFENSE, DirectionTypes.DIRECTION_EAST);
			unit:JumpToNearestValidPlot();
		elseif (iHandicap == 3) then
			pPlayer:SetJONSCulture(125);
			pPlayer:SetFaith(150);
			pPlayer:SetGold(300)
			iUnitID = GameInfoTypes["UNIT_SETTLER"];
			unit = pPlayer:InitUnit (iUnitID, capital:GetX(), capital:GetY(), UNITAI_SETTLE, DirectionTypes.DIRECTION_EAST);
			unit:JumpToNearestValidPlot();
			iUnitID = GameInfoTypes["UNIT_SETTLER"];
			unit = pPlayer:InitUnit (iUnitID, capital:GetX(), capital:GetY(), UNITAI_SETTLE, DirectionTypes.DIRECTION_EAST);
			unit:JumpToNearestValidPlot();
			iUnitID = GameInfoTypes["UNIT_SWORDSMAN"];
			unit = pPlayer:InitUnit (iUnitID, capital:GetX(), capital:GetY(), UNITAI_DEFENSE, DirectionTypes.DIRECTION_EAST);
			unit:JumpToNearestValidPlot();
			iUnitID = GameInfoTypes["UNIT_SWORDSMAN"];
			unit = pPlayer:InitUnit (iUnitID, capital:GetX(), capital:GetY(), UNITAI_DEFENSE, DirectionTypes.DIRECTION_EAST);
			unit:JumpToNearestValidPlot();
			iUnitID = GameInfoTypes["UNIT_COMPOSITE_BOWMAN"];
			unit = pPlayer:InitUnit (iUnitID, capital:GetX(), capital:GetY(), UNITAI_DEFENSE, DirectionTypes.DIRECTION_EAST);
			unit:JumpToNearestValidPlot();
		elseif (iHandicap == 4) then
			pPlayer:SetJONSCulture(125);
			pPlayer:SetFaith(175);
			pPlayer:SetGold(350)
			iUnitID = GameInfoTypes["UNIT_SETTLER"];
			unit = pPlayer:InitUnit (iUnitID, capital:GetX(), capital:GetY(), UNITAI_SETTLE, DirectionTypes.DIRECTION_EAST);
			unit:JumpToNearestValidPlot();
			iUnitID = GameInfoTypes["UNIT_SETTLER"];
			unit = pPlayer:InitUnit (iUnitID, capital:GetX(), capital:GetY(), UNITAI_SETTLE, DirectionTypes.DIRECTION_EAST);
			unit:JumpToNearestValidPlot();
			iUnitID = GameInfoTypes["UNIT_SETTLER"];
			unit = pPlayer:InitUnit (iUnitID, capital:GetX(), capital:GetY(), UNITAI_SETTLE, DirectionTypes.DIRECTION_EAST);
			unit:JumpToNearestValidPlot();
			iUnitID = GameInfoTypes["UNIT_WORKER"];
			unit = pPlayer:InitUnit (iUnitID, capital:GetX(), capital:GetY(), UNITAI_SETTLE, DirectionTypes.DIRECTION_EAST);
			unit:JumpToNearestValidPlot();
			iUnitID = GameInfoTypes["UNIT_SWORDSMAN"];
			unit = pPlayer:InitUnit (iUnitID, capital:GetX(), capital:GetY(), UNITAI_DEFENSE, DirectionTypes.DIRECTION_EAST);
			unit:JumpToNearestValidPlot();
			iUnitID = GameInfoTypes["UNIT_SWORDSMAN"];
			unit = pPlayer:InitUnit (iUnitID, capital:GetX(), capital:GetY(), UNITAI_DEFENSE, DirectionTypes.DIRECTION_EAST);
			unit:JumpToNearestValidPlot();
			iUnitID = GameInfoTypes["UNIT_COMPOSITE_BOWMAN"];
			unit = pPlayer:InitUnit (iUnitID, capital:GetX(), capital:GetY(), UNITAI_DEFENSE, DirectionTypes.DIRECTION_EAST);
			unit:JumpToNearestValidPlot();
		elseif (iHandicap == 5) then
			pPlayer:SetJONSCulture(125);
			pPlayer:SetFaith(200);
			pPlayer:SetGold(400)
			iUnitID = GameInfoTypes["UNIT_SETTLER"];
			unit = pPlayer:InitUnit (iUnitID, capital:GetX(), capital:GetY(), UNITAI_SETTLE, DirectionTypes.DIRECTION_EAST);
			unit:JumpToNearestValidPlot();
			iUnitID = GameInfoTypes["UNIT_SETTLER"];
			unit = pPlayer:InitUnit (iUnitID, capital:GetX(), capital:GetY(), UNITAI_SETTLE, DirectionTypes.DIRECTION_EAST);
			unit:JumpToNearestValidPlot();
			iUnitID = GameInfoTypes["UNIT_SETTLER"];
			unit = pPlayer:InitUnit (iUnitID, capital:GetX(), capital:GetY(), UNITAI_SETTLE, DirectionTypes.DIRECTION_EAST);
			unit:JumpToNearestValidPlot();
			iUnitID = GameInfoTypes["UNIT_WORKER"];
			unit = pPlayer:InitUnit (iUnitID, capital:GetX(), capital:GetY(), UNITAI_SETTLE, DirectionTypes.DIRECTION_EAST);
			unit:JumpToNearestValidPlot();
			iUnitID = GameInfoTypes["UNIT_SWORDSMAN"];
			unit = pPlayer:InitUnit (iUnitID, capital:GetX(), capital:GetY(), UNITAI_DEFENSE, DirectionTypes.DIRECTION_EAST);
			unit:JumpToNearestValidPlot();
			iUnitID = GameInfoTypes["UNIT_SWORDSMAN"];
			unit = pPlayer:InitUnit (iUnitID, capital:GetX(), capital:GetY(), UNITAI_DEFENSE, DirectionTypes.DIRECTION_EAST);
			unit:JumpToNearestValidPlot();
			iUnitID = GameInfoTypes["UNIT_SWORDSMAN"];
			unit = pPlayer:InitUnit (iUnitID, capital:GetX(), capital:GetY(), UNITAI_DEFENSE, DirectionTypes.DIRECTION_EAST);
			unit:JumpToNearestValidPlot();
			iUnitID = GameInfoTypes["UNIT_CATAPULT"];
			unit = pPlayer:InitUnit (iUnitID, capital:GetX(), capital:GetY(), UNITAI_DEFENSE, DirectionTypes.DIRECTION_EAST);
			unit:JumpToNearestValidPlot();
		elseif (iHandicap == 6) then
			pPlayer:SetJONSCulture(125);
			pPlayer:SetFaith(300);
			pPlayer:SetGold(600)
			iUnitID = GameInfoTypes["UNIT_SETTLER"];
			unit = pPlayer:InitUnit (iUnitID, capital:GetX(), capital:GetY(), UNITAI_SETTLE, DirectionTypes.DIRECTION_EAST);
			unit:JumpToNearestValidPlot();
			iUnitID = GameInfoTypes["UNIT_SETTLER"];
			unit = pPlayer:InitUnit (iUnitID, capital:GetX(), capital:GetY(), UNITAI_SETTLE, DirectionTypes.DIRECTION_EAST);
			unit:JumpToNearestValidPlot();
			iUnitID = GameInfoTypes["UNIT_SETTLER"];
			unit = pPlayer:InitUnit (iUnitID, capital:GetX(), capital:GetY(), UNITAI_SETTLE, DirectionTypes.DIRECTION_EAST);
			unit:JumpToNearestValidPlot();
			iUnitID = GameInfoTypes["UNIT_WORKER"];
			unit = pPlayer:InitUnit (iUnitID, capital:GetX(), capital:GetY(), UNITAI_SETTLE, DirectionTypes.DIRECTION_EAST);
			unit:JumpToNearestValidPlot();
			iUnitID = GameInfoTypes["UNIT_WORKER"];
			unit = pPlayer:InitUnit (iUnitID, capital:GetX(), capital:GetY(), UNITAI_SETTLE, DirectionTypes.DIRECTION_EAST);
			unit:JumpToNearestValidPlot();
			iUnitID = GameInfoTypes["UNIT_SWORDSMAN"];
			unit = pPlayer:InitUnit (iUnitID, capital:GetX(), capital:GetY(), UNITAI_DEFENSE, DirectionTypes.DIRECTION_EAST);
			unit:JumpToNearestValidPlot();
			iUnitID = GameInfoTypes["UNIT_SWORDSMAN"];
			unit = pPlayer:InitUnit (iUnitID, capital:GetX(), capital:GetY(), UNITAI_DEFENSE, DirectionTypes.DIRECTION_EAST);
			unit:JumpToNearestValidPlot();
			iUnitID = GameInfoTypes["UNIT_SWORDSMAN"];
			unit = pPlayer:InitUnit (iUnitID, capital:GetX(), capital:GetY(), UNITAI_DEFENSE, DirectionTypes.DIRECTION_EAST);
			unit:JumpToNearestValidPlot();
			iUnitID = GameInfoTypes["UNIT_CATAPULT"];
			unit = pPlayer:InitUnit (iUnitID, capital:GetX(), capital:GetY(), UNITAI_DEFENSE, DirectionTypes.DIRECTION_EAST);
			unit:JumpToNearestValidPlot();
		elseif (iHandicap == 7) then
			pPlayer:SetJONSCulture(125);
			pPlayer:SetFaith(400);
			pPlayer:SetGold(800)
			iUnitID = GameInfoTypes["UNIT_SETTLER"];
			unit = pPlayer:InitUnit (iUnitID, capital:GetX(), capital:GetY(), UNITAI_SETTLE, DirectionTypes.DIRECTION_EAST);
			unit:JumpToNearestValidPlot();
			iUnitID = GameInfoTypes["UNIT_SETTLER"];
			unit = pPlayer:InitUnit (iUnitID, capital:GetX(), capital:GetY(), UNITAI_SETTLE, DirectionTypes.DIRECTION_EAST);
			unit:JumpToNearestValidPlot();
			iUnitID = GameInfoTypes["UNIT_SETTLER"];
			unit = pPlayer:InitUnit (iUnitID, capital:GetX(), capital:GetY(), UNITAI_SETTLE, DirectionTypes.DIRECTION_EAST);
			unit:JumpToNearestValidPlot();
			iUnitID = GameInfoTypes["UNIT_WORKER"];
			unit = pPlayer:InitUnit (iUnitID, capital:GetX(), capital:GetY(), UNITAI_SETTLE, DirectionTypes.DIRECTION_EAST);
			unit:JumpToNearestValidPlot();
			iUnitID = GameInfoTypes["UNIT_WORKER"];
			unit = pPlayer:InitUnit (iUnitID, capital:GetX(), capital:GetY(), UNITAI_SETTLE, DirectionTypes.DIRECTION_EAST);
			unit:JumpToNearestValidPlot();
			iUnitID = GameInfoTypes["UNIT_SWORDSMAN"];
			unit = pPlayer:InitUnit (iUnitID, capital:GetX(), capital:GetY(), UNITAI_DEFENSE, DirectionTypes.DIRECTION_EAST);
			unit:JumpToNearestValidPlot();
			iUnitID = GameInfoTypes["UNIT_SWORDSMAN"];
			unit = pPlayer:InitUnit (iUnitID, capital:GetX(), capital:GetY(), UNITAI_DEFENSE, DirectionTypes.DIRECTION_EAST);
			unit:JumpToNearestValidPlot();
			iUnitID = GameInfoTypes["UNIT_SWORDSMAN"];
			unit = pPlayer:InitUnit (iUnitID, capital:GetX(), capital:GetY(), UNITAI_DEFENSE, DirectionTypes.DIRECTION_EAST);
			unit:JumpToNearestValidPlot();
			iUnitID = GameInfoTypes["UNIT_CATAPULT"];
			unit = pPlayer:InitUnit (iUnitID, capital:GetX(), capital:GetY(), UNITAI_DEFENSE, DirectionTypes.DIRECTION_EAST);
			unit:JumpToNearestValidPlot();
			iUnitID = GameInfoTypes["UNIT_COMPOSITE_BOWMAN"];
			unit = pPlayer:InitUnit (iUnitID, capital:GetX(), capital:GetY(), UNITAI_DEFENSE, DirectionTypes.DIRECTION_EAST);
			unit:JumpToNearestValidPlot();
		end
	end
end

---------------------------------------------------------------------
local iValue = GetPersistentProperty("ScenarioInited");

if (iValue == nil) then

	SetPersistentProperty("ScenarioInited", 1);
	
	SetPersistentProperty("NumCaravels", 0);
	SetPersistentProperty("NumConquistadors", 0);
	SetPersistentProperty("ReformationStart", -1);
	
	print ("In Initial Initialization");

	Map.ChangeAIMapHint(4);

	for iPlayer = 0, 11, 1 do
		AddInitialUnits(iPlayer);
		AddUnitsPerDifficulty(iPlayer);
	end

	for iPlayer = 22, 46, 1 do
		InitializeCityState(iPlayer);
	end

	-- Remove Mongol units		
	local pPlayer = Players[12];
	for pUnit in pPlayer:Units() do
		pUnit:Kill();
	end


	SetupReligions();
	
	Game.SetStartYear(1095);

	Game.SetVictoryValid(0,true);
	Game.SetVictoryValid(1,false);
	Game.SetVictoryValid(2,true);
	Game.SetVictoryValid(3,false);
	Game.SetVictoryValid(4,true);

	Game.SetUnitedNationsCountdown(50);
	
	GameEvents.GetFounderBenefitsReligion.Add(OnGetFounderBenefitsReligion);	
	
	BringInMongols();
end