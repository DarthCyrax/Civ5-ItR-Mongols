-------------------------------------------------------------------------------
--	FILE:	 Europe_Scenario.lua
--	AUTHOR:  Bob Thomas (Sirian)
--	PURPOSE: Regional map script - Generates a random map similar to Europe and
--	         the Mediterranean basin -- for use with the Europe Scenario.
-------------------------------------------------------------------------------
--	Copyright (c) 2012 Firaxis Games, Inc. All rights reserved.
-------------------------------------------------------------------------------

include("MapGenerator");
include("MultilayeredFractal");
include("TerrainGenerator");
include("FeatureGenerator");
include("MapmakerUtilities");

-----------------------------------------------------
-- Global Variables
-----------------------------------------------------
if(Players ~= nil) then

	function FindFirstPlayerIDWithCivType(civType)	
		local civ = GameInfo.Civilizations[civType];
		if(civ ~= nil) then
			local civId = civ.ID;
			
			for playerId = 0, GameDefines.MAX_CIV_PLAYERS-1, 1 do
				local player = Players[playerId];
				if(player ~= nil and player:GetCivilizationType() == civId) then
					return playerId;
				end
			end
			
			print("BIG ERROR: Cannot find Player using Civilization Type - " .. civ.Type);
		else
			print("BIG ERROR: Cannot find Civilization Type - " .. tostring(civType));
		end
	end
	
	Spain_PlayerID = FindFirstPlayerIDWithCivType("CIVILIZATION_SPAIN");
	France_PlayerID = FindFirstPlayerIDWithCivType("CIVILIZATION_FRANCE");
	England_PlayerID = FindFirstPlayerIDWithCivType("CIVILIZATION_ENGLAND");
	Austria_PlayerID = FindFirstPlayerIDWithCivType("CIVILIZATION_AUSTRIA");
	Ottomans_PlayerID = FindFirstPlayerIDWithCivType("CIVILIZATION_OTTOMAN");
	Russia_PlayerID = FindFirstPlayerIDWithCivType("CIVILIZATION_RUSSIA");
	Sweden_PlayerID = FindFirstPlayerIDWithCivType("CIVILIZATION_SWEDEN");
	Arabia_PlayerID = FindFirstPlayerIDWithCivType("CIVILIZATION_ARABIA");
	Netherlands_PlayerID = FindFirstPlayerIDWithCivType("CIVILIZATION_NETHERLANDS");
	Celts_PlayerID = FindFirstPlayerIDWithCivType("CIVILIZATION_CELTS");
	Songhai_PlayerID = FindFirstPlayerIDWithCivType("CIVILIZATION_SONGHAI");
	Byzantium_PlayerID = FindFirstPlayerIDWithCivType("CIVILIZATION_BYZANTIUM");
	
	print("PlayerIDs by Civilization");
	print("Spain: " .. tostring(Spain_PlayerID));
	print("France: " .. tostring(France_PlayerID));
	print("England: " .. tostring(England_PlayerID));
	print("Austria: " .. tostring(Austria_PlayerID));
	print("Ottomans: " .. tostring(Ottomans_PlayerID));
	print("Russia: " .. tostring(Russia_PlayerID));
	print("Sweden: " .. tostring(Sweden_PlayerID));
	print("Arabia: " .. tostring(Arabia_PlayerID));
	print("Netherlands: " .. tostring(Netherlands_PlayerID));
	print("Celts: " .. tostring(Celts_PlayerID));
	print("Songhai: " .. tostring(Songhai_PlayerID));
	print("Byzantium: " .. tostring(Byzantium_PlayerID));
end

-------------------------------------------------------------------------------
function GetMapScriptInfo()
	local world_age, temperature, rainfall, sea_level, resources = GetCoreMapOptions()
	return {
		Name = "TXT_KEY_MAP_EUROPE_SCENARIO",
		Description = "TXT_KEY_MAP_EUROPE_SCENARIO_HELP",
		IsAdvancedMap = false,
		IconIndex = 1,
	}
end
-------------------------------------------------------------------------------

------------------------------------------------------------------------------
function GetMapInitData(worldSize)
	local world = GameInfo.Worlds[worldSize];
	if(world ~= nil) then
	return {
		Width = 80,
		Height = 64,
		WrapX = false,
	};      
     end
end
------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------
function MultilayeredFractal:GeneratePlotsByRegion()
	-- Sirian's MultilayeredFractal controlling function.
	-- You -MUST- customize this function for each script using MultilayeredFractal.
	--
	-- This implementation is specific to Mediterranean.
	local iW, iH = Map.GetGridSize();
	-- Initiate plot table, fill all data slots with type PLOT_LAND
	table.fill(self.wholeworldPlotTypes, PlotTypes.PLOT_LAND, iW * iH);
	-- Change western edge and northwest corner to water.
	local west_edge = {};
	--
	local variance = 0;
	local max_variance = math.floor(iW * 0.04);
	--
	local iX, iY = 2, 1;
	while iX <= math.ceil(iW * 0.08) do
		west_edge[iY] = iX;
		west_edge[iY + 1] = iX;
		iY = iY + 2;
		iX = iX + 1;
	end
	for y = iY, math.floor(iH * 0.47) do
		west_edge[y] = math.ceil(iW * 0.08) - 1 + Map.Rand(4, "Roughen coastline - Mediterranean LUA");
	end
	local startX = math.ceil(iW * 0.08);
	local startY = math.ceil(iH * 0.47);
	local endX = math.ceil(iW * 0.7);
	local endY = iH;
	local dx = endX - startX;
	local dy = endY - startY
	local slope = 0;
	if dy ~= 0 then
		slope = dx / dy;
	end
	local x = startX;
	for y = startY, endY do
		x = x + slope;
		west_edge[y] = math.floor(x) + Map.Rand(3, "Roughen coastline - Mediterranean LUA");
	end
	for y = 0, iH - 1 do
		local edge_index = y + 1;
		local edge = west_edge[edge_index];
		for x = 0, edge do
			local i = y * iW + x + 1;
			self.wholeworldPlotTypes[i] = PlotTypes.PLOT_OCEAN;
		end
	end

	-- Add water channel from Atlantic in to Mediterranean Sea
	for x = 0, math.floor(iW * 0.205) do
		local i = math.floor(iH * 0.225) * iW + x + 1;
		self.wholeworldPlotTypes[i] = PlotTypes.PLOT_OCEAN;
	end
	local startX = math.floor(iW * 0.205);
	local startY = math.floor(iH * 0.225);
	local endX = math.ceil(iW * 0.31);
	local endY = math.floor(iH * 0.295);
	local dx = endX - startX;
	local dy = endY - startY;
	local slope = 0;
	if dx ~= 0 then
		slope = dy / dx;
	end
	local y = startY;
	for x = startX, endX do
		y = y + slope;
		local i = math.floor(y) * iW + x + 1;
		self.wholeworldPlotTypes[i] = PlotTypes.PLOT_OCEAN;
		self.wholeworldPlotTypes[i + 1] = PlotTypes.PLOT_OCEAN;
	end

	-- Add layers of seas to similate the Mediterranean

	local args = {};
	args.iWaterPercent = 78;
	args.iRegionWidth = math.ceil(iW * 0.23);
	args.iRegionHeight = math.ceil(iH * 0.13);
	args.iRegionWestX = math.floor(iW * 0.035);
	args.iRegionSouthY = math.floor(iH * 0.155);
	args.iRegionGrain = 1;
	args.iRegionHillsGrain = 4;
	args.iRegionPlotFlags = self.iRoundFlags;
	args.iRegionFracXExp = 6;
	args.iRegionFracYExp = 5;
	args.iRiftGrain = Map.Rand(3, "Rift Grain - Mediterranean LUA");
	--args.bShift;

	self:GenerateWaterLayer(args)

	local args = {};
	args.iWaterPercent = 80;
	args.iRegionWidth = math.ceil(iW * 0.23);
	args.iRegionHeight = math.ceil(iH * 0.13);
	args.iRegionWestX = math.floor(iW * 0.035);
	args.iRegionSouthY = math.floor(iH * 0.155);
	args.iRegionGrain = 2;
	args.iRegionHillsGrain = 4;
	args.iRegionPlotFlags = self.iRoundFlags;
	args.iRegionFracXExp = 6;
	args.iRegionFracYExp = 5;
	args.iRiftGrain = Map.Rand(3, "Rift Grain - Mediterranean LUA");
	--args.bShift;

	self:GenerateWaterLayer(args)

	local args = {};
	args.iWaterPercent = 78;
	args.iRegionWidth = math.ceil(iW * 0.12);
	args.iRegionHeight = math.ceil(iH * 0.12);
	args.iRegionWestX = math.floor(iW * 0.2);
	args.iRegionSouthY = math.floor(iH * 0.23);
	args.iRegionGrain = 2;
	args.iRegionHillsGrain = 4;
	args.iRegionPlotFlags = self.iRoundFlags;
	args.iRegionFracXExp = 5;
	args.iRegionFracYExp = 5;
	args.iRiftGrain = Map.Rand(3, "Rift Grain - Mediterranean LUA");
	--args.bShift;

	self:GenerateWaterLayer(args)

	local args = {};
	args.iWaterPercent = 65;
	args.iRegionWidth = math.ceil(iW * 0.30);
	args.iRegionHeight = math.ceil(iH * 0.27);
	args.iRegionWestX = math.floor(iW * 0.275);
	args.iRegionSouthY = math.floor(iH * 0.215);
	args.iRegionGrain = 2;
	args.iRegionHillsGrain = 4;
	args.iRegionPlotFlags = self.iRoundFlags;
	args.iRegionFracXExp = 5;
	args.iRegionFracYExp = 5;
	args.iRiftGrain = Map.Rand(3, "Rift Grain - Mediterranean LUA");
	--args.bShift;
	
	self:GenerateWaterLayer(args)

	local args = {};
	args.iWaterPercent = 75;
	args.iRegionWidth = math.ceil(iW * 0.36);
	args.iRegionHeight = math.ceil(iH * 0.2);
	args.iRegionWestX = math.floor(iW * 0.215);
	args.iRegionSouthY = math.floor(iH * 0.2);
	args.iRegionGrain = 2;
	args.iRegionHillsGrain = 4;
	args.iRegionPlotFlags = self.iRoundFlags;
	args.iRegionFracXExp = 6;
	args.iRegionFracYExp = 5;
	args.iRiftGrain = Map.Rand(3, "Rift Grain - Mediterranean LUA");
	--args.bShift;
	
	self:GenerateWaterLayer(args)

	local args = {};
	args.iWaterPercent = 83;
	args.iRegionWidth = math.ceil(iW * 0.36);
	args.iRegionHeight = math.ceil(iH * 0.27);
	args.iRegionWestX = math.floor(iW * 0.215);
	args.iRegionSouthY = math.floor(iH * 0.215);
	args.iRegionGrain = 1;
	args.iRegionHillsGrain = 4;
	args.iRegionPlotFlags = self.iRoundFlags;
	args.iRegionFracXExp = 6;
	args.iRegionFracYExp = 5;
	args.iRiftGrain = Map.Rand(3, "Rift Grain - Mediterranean LUA");
	--args.bShift;
	
	self:GenerateWaterLayer(args)

	local args = {};
	args.iWaterPercent = 60;
	args.iRegionWidth = math.ceil(iW * 0.48);
	args.iRegionHeight = math.ceil(iH * 0.23);
	args.iRegionWestX = math.floor(iW * 0.415);
	args.iRegionSouthY = math.floor(iH * 0.08);
	args.iRegionGrain = 2;
	args.iRegionHillsGrain = 4;
	args.iRegionPlotFlags = self.iRoundFlags;
	args.iRegionFracXExp = 6;
	args.iRegionFracYExp = 5;
	--args.iRiftGrain = -1;
	--args.bShift;
	
	self:GenerateWaterLayer(args)

	local args = {};
	args.iWaterPercent = 72;
	args.iRegionWidth = math.ceil(iW * 0.48);
	args.iRegionHeight = math.ceil(iH * 0.23);
	args.iRegionWestX = math.floor(iW * 0.415);
	args.iRegionSouthY = math.floor(iH * 0.08);
	args.iRegionGrain = 2;
	args.iRegionHillsGrain = 4;
	args.iRegionPlotFlags = self.iRoundFlags;
	args.iRegionFracXExp = 6;
	args.iRegionFracYExp = 5;
	--args.iRiftGrain = -1;
	--args.bShift;
	
	self:GenerateWaterLayer(args)


	-- Simulate the Black Sea
	local args = {};
	args.iWaterPercent = 63;
	args.iRegionWidth = math.ceil(iW * 0.29);
	args.iRegionHeight = math.ceil(iH * 0.20);
	args.iRegionWestX = math.floor(iW * 0.68);
	args.iRegionSouthY = math.floor(iH * 0.375);
	args.iRegionGrain = 1;
	args.iRegionHillsGrain = 4;
	args.iRegionPlotFlags = self.iRoundFlags;
	args.iRegionFracXExp = 6;
	args.iRegionFracYExp = 5;
	--args.iRiftGrain = -1;
	--args.bShift;
	
	self:GenerateWaterLayer(args)

	local args = {};
	args.iWaterPercent = 70;
	args.iRegionWidth = math.ceil(iW * 0.29);
	args.iRegionHeight = math.ceil(iH * 0.20);
	args.iRegionWestX = math.floor(iW * 0.68);
	args.iRegionSouthY = math.floor(iH * 0.375);
	args.iRegionGrain = 1;
	args.iRegionHillsGrain = 4;
	args.iRegionPlotFlags = self.iRoundFlags;
	args.iRegionFracXExp = 6;
	args.iRegionFracYExp = 5;
	--args.iRiftGrain = -1;
	--args.bShift;
	
	self:GenerateWaterLayer(args)


	-- Generate British Isles		
	local args = {};
	args.iWaterPercent = 57;
	args.iRegionWidth = math.ceil(iW * 0.19);
	args.iRegionHeight = math.ceil(iH * 0.27);
	args.iRegionWestX = math.floor(iW * 0.055);
	args.iRegionSouthY = math.floor(iH * 0.61);
	args.iRegionGrain = 1 + Map.Rand(2, "Continental Grain - Mediterranean LUA");
	args.iRegionHillsGrain = 4;
	args.iRegionPlotFlags = self.iRoundFlags;
	args.iRegionFracXExp = 6;
	args.iRegionFracYExp = 5;
	--args.iRiftGrain = Map.Rand(3, "Rift Grain - Mediterranean LUA");
	--args.bShift
	
	self:GenerateFractalLayerWithoutHills(args)

	-- British Isles second layer, for the scenario version only, because we are cramming a second civ in there.		
	local args = {};
	args.iWaterPercent = 77;
	args.iRegionWidth = 19;
	args.iRegionHeight = math.ceil(iH * 0.35);
	args.iRegionWestX = 2;
	args.iRegionSouthY = math.floor(iH * 0.58);
	args.iRegionGrain = 1 + Map.Rand(2, "Continental Grain - Mediterranean LUA");
	args.iRegionHillsGrain = 4;
	args.iRegionPlotFlags = self.iRoundFlags;
	args.iRegionFracXExp = 6;
	args.iRegionFracYExp = 5;
	--args.iRiftGrain = Map.Rand(3, "Rift Grain - Mediterranean LUA");
	--args.bShift
	
	self:GenerateFractalLayerWithoutHills(args)


	-- Generate Scandinavia		
	local args = {};
	args.iWaterPercent = 55;
	args.iRegionWidth = math.ceil(iW * 0.37);
	args.iRegionHeight = math.ceil(iH * 0.25);
	args.iRegionWestX = math.floor(iW * 0.275);
	args.iRegionSouthY = (iH - 1) - args.iRegionHeight;
	args.iRegionGrain = 1;
	args.iRegionHillsGrain = 4;
	args.iRegionPlotFlags = self.iRoundFlags;
	args.iRegionFracXExp = 6;
	args.iRegionFracYExp = 5;
	--args.iRiftGrain = Map.Rand(3, "Rift Grain - Mediterranean LUA");
	--args.bShift
	
	self:GenerateFractalLayerWithoutHills(args)
	
	local args = {};
	args.iWaterPercent = 55;
	args.iRegionWidth = math.ceil(iW * 0.37);
	args.iRegionHeight = math.ceil(iH * 0.25);
	args.iRegionWestX = math.floor(iW * 0.275);
	args.iRegionSouthY = (iH - 1) - args.iRegionHeight;
	args.iRegionGrain = 1;
	args.iRegionHillsGrain = 4;
	args.iRegionPlotFlags = self.iRoundFlags;
	args.iRegionFracXExp = 6;
	args.iRegionFracYExp = 5;
	--args.iRiftGrain = Map.Rand(3, "Rift Grain - Mediterranean LUA");
	--args.bShift
	
	self:GenerateFractalLayerWithoutHills(args)
	
	local args = {};
	args.iWaterPercent = 60;
	args.iRegionWidth = math.ceil(iW * 0.37);
	args.iRegionHeight = math.ceil(iH * 0.25);
	args.iRegionWestX = math.floor(iW * 0.275);
	args.iRegionSouthY = (iH - 1) - args.iRegionHeight;
	args.iRegionGrain = 2;
	args.iRegionHillsGrain = 4;
	args.iRegionPlotFlags = self.iRoundFlags;
	args.iRegionFracXExp = 6;
	args.iRegionFracYExp = 5;
	--args.iRiftGrain = Map.Rand(3, "Rift Grain - Mediterranean LUA");
	--args.bShift
	
	self:GenerateFractalLayerWithoutHills(args)
	
	-- The real Scandinavia continues north of the Arctic circle. We want our simulated one to do so as well.
	-- But the layers tend to leave the top row all water, so this will try to address that.
	for x = math.floor(iW * 0.29), math.floor(iW * 0.62) do
		local y = iH - 2;
		local i = y * iW + x + 1;
		if self.wholeworldPlotTypes[i] == PlotTypes.PLOT_LAND then
			self.wholeworldPlotTypes[i + iW] = PlotTypes.PLOT_LAND;
		end
	end
	for x = math.floor(iW * 0.29), math.floor(iW * 0.62) do
		local y = iH - 1;
		local i = y * iW + x + 1;
		if self.wholeworldPlotTypes[i] == PlotTypes.PLOT_OCEAN then
			if self.wholeworldPlotTypes[i + 1] == PlotTypes.PLOT_LAND and self.wholeworldPlotTypes[i - 1] == PlotTypes.PLOT_LAND then
				self.wholeworldPlotTypes[i] = PlotTypes.PLOT_LAND;
			end
		end
	end

	-- Simulate the Baltic Sea
	local args = {};
	args.iWaterPercent = 70;
	args.iRegionWidth = math.ceil(iW * 0.25);
	args.iRegionHeight = math.ceil(iH * 0.27);
	args.iRegionWestX = math.floor(iW * 0.37);
	args.iRegionSouthY = math.floor(iH * 0.65);
	args.iRegionGrain = 2;
	args.iRegionHillsGrain = 4;
	args.iRegionPlotFlags = self.iRoundFlags;
	args.iRegionFracXExp = 6;
	args.iRegionFracYExp = 5;
	--args.iRiftGrain = -1;
	--args.bShift;
	
	self:GenerateWaterLayer(args)


	-- Land and water are set. Apply hills and mountains.
	self:ApplyTectonics()

	-- Plot Type generation completed. Return global plot array.
	return self.wholeworldPlotTypes
end
------------------------------------------------------------------------------
function GeneratePlotTypes()
	print("Setting Plot Types (Lua Europe) ...");

	local layered_world = MultilayeredFractal.Create();
	local plotsEur = layered_world:GeneratePlotsByRegion();
	
	SetPlotTypes(plotsEur);

	GenerateCoasts();
end
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Europe uses a custom terrain generation.
------------------------------------------------------------------------------
function GenerateTerrain()
	print("Generating Terrain (Lua Europe) ...");
	Map.RecalculateAreas();
	
	local iW, iH = Map.GetGridSize();
	local terrainTypes = {};
	local iFlags = {};
	local grainvalues = {
		[GameInfo.Worlds.WORLDSIZE_DUEL.ID] = 3,
		[GameInfo.Worlds.WORLDSIZE_TINY.ID] = 3,
		[GameInfo.Worlds.WORLDSIZE_SMALL.ID] = 3,
		[GameInfo.Worlds.WORLDSIZE_STANDARD.ID] = 4,
		[GameInfo.Worlds.WORLDSIZE_LARGE.ID] = 4,
		[GameInfo.Worlds.WORLDSIZE_HUGE.ID] = 4
		}
	local grain_amount = grainvalues[Map.GetWorldSize()];

	local fDesertLine = 0.185;
	local fIceLine = 0.92;
	local fTundraLine = 0.75;
	local fGrassLine = 0.25;

	local iSnowPercent = 85;
	local iTundraPercent = 85;
	local iGrassPercent = 60;

	local snow_frac = Fractal.Create(iW, iH, grain_amount + 1, iFlags, -1, -1);
	local tundra_frac = Fractal.Create(iW, iH, grain_amount + 1, iFlags, -1, -1);
	local grass_frac = Fractal.Create(iW, iH, grain_amount, iFlags, -1, -1);
	local variation = Fractal.Create(iW, iH, grain_amount + 1, iFlags, -1, -1);

	local iSnowTop = snow_frac:GetHeight(iSnowPercent);
	local iTundraTop = tundra_frac:GetHeight(iTundraPercent);
	local iGrassTop = grass_frac:GetHeight(iGrassPercent);

	local terrainDesert	= GameInfoTypes["TERRAIN_DESERT"];
	local terrainPlains	= GameInfoTypes["TERRAIN_PLAINS"];
	local terrainGrass	= GameInfoTypes["TERRAIN_GRASS"];	
	local terrainTundra	= GameInfoTypes["TERRAIN_TUNDRA"];	
	local terrainSnow	= GameInfoTypes["TERRAIN_SNOW"];	

	-- Main loop, generate the terrain plot by plot.
	for x = 0, iW - 1 do
		for y = 0, iH - 1 do
			local i = y * iW + x; -- C++ Plot indices, starting at 0.
			local plot = Map.GetPlot(x, y);
			local terrainVal;

			-- Handle water plots
			if plot:IsWater() then
				terrainVal = plot:GetTerrainType();

			-- Handle land plots; begin with checking if plot is coastal.
			else
				-- Set latitude at plot
				local lat = y / iH; -- 0.0 = south
				lat = lat + (128 - variation:GetHeight(x, y))/(255.0 * 5.0);
				if lat < 0 then
					lat = 0;
				elseif lat > 1 then
					lat = 1;
				end

				-- Check all adjacent plots to see if any of those are salt water.
				local adjacent_water_count = 0;
				local directions = { DirectionTypes.DIRECTION_NORTHEAST,
				                     DirectionTypes.DIRECTION_EAST,
    				                 DirectionTypes.DIRECTION_SOUTHEAST,
            	    			     DirectionTypes.DIRECTION_SOUTHWEST,
			    	                 DirectionTypes.DIRECTION_WEST,
    			    	             DirectionTypes.DIRECTION_NORTHWEST };
				-- 
				for loop, current_direction in ipairs(directions) do
					local testPlot = Map.PlotDirection(x, y, current_direction);
					if testPlot ~= nil then
						local type = testPlot:GetPlotType()
						if type == PlotTypes.PLOT_OCEAN then -- Adjacent plot is water! Check if ocean or lake.
							-- Have to do a manual check of area size, because lakes have not yet been defined as such.
							local testAreaID = testPlot:GetArea()
							local testArea = Map.GetArea(testAreaID)
							local testArea_size = testArea:GetNumTiles()
							if testArea_size >= 10 then
								adjacent_water_count = adjacent_water_count + 1;
							end
						end
					end
				end
				
				-- Check count of adjacent saltwater tiles. If none, the plot is inland. If not none, the plot is coastal 
				-- and will be turned in to grassland, except in the far north, where only some of the tiles are turned to grass.
				if adjacent_water_count > 0 then
					-- Coastal Plot
					if lat < 0.785 then -- Make it grass.
						terrainVal = terrainGrass;
					else -- Far north, roll dice to see if we make it grass. (More chance, the more adjacent tiles are water.)
						local diceroll = 1 + Map.Rand(6, "Subarctic coastland, grass die roll - Mediterranean LUA");
						if diceroll <= adjacent_water_count then -- Make this tile grass.
							terrainVal = terrainGrass;
						else
							terrainVal = terrainTundra;
						end
					end
				elseif lat <= fDesertLine then
					terrainVal = terrainDesert;
				elseif lat >= fIceLine then
					local val = snow_frac:GetHeight(x, y);
					if val >= iSnowTop then
						terrainVal = terrainTundra;
					else
						terrainVal = terrainSnow;
					end
				elseif lat >= fTundraLine then
					local val = tundra_frac:GetHeight(x, y);
					if val >= iTundraTop then
						terrainVal = terrainPlains;
					else
						terrainVal = terrainTundra;
					end
				elseif lat >= fGrassLine then
					local val = grass_frac:GetHeight(x, y);
					if val >= iGrassTop then
						terrainVal = terrainPlains;
					else
						terrainVal = terrainGrass;
					end
				else
					terrainVal = terrainPlains;
				end
			end
			
			-- Input result of this plot to terrain types array
			terrainTypes[i] = terrainVal;
		end
	end
	
	SetTerrainTypes(terrainTypes);	
end
------------------------------------------------------------------------------

------------------------------------------------------------------------------
function GetRiverValueAtPlot(plot)
	local numPlots = PlotTypes.NUM_PLOT_TYPES;
	local sum = (numPlots - plot:GetPlotType()) * 20;
	local numDirections = DirectionTypes.NUM_DIRECTION_TYPES;
	for direction = 0, numDirections - 1, 1 do
		local adjacentPlot = Map.PlotDirection(plot:GetX(), plot:GetY(), direction);
		if (adjacentPlot ~= nil) then
			sum = sum + (numPlots - adjacentPlot:GetPlotType());
		else
			sum = 0
		end
	end
	sum = sum + Map.Rand(10, "River Rand");
	return sum;
end
------------------------------------------------------------------------------
function DoRiver(startPlot, thisFlowDirection, originalFlowDirection, riverID)
	-- Customizing to handle problems in top row of the map. Only this aspect has been altered.

	local iW, iH = Map.GetGridSize()
	thisFlowDirection = thisFlowDirection or FlowDirectionTypes.NO_FLOWDIRECTION;
	originalFlowDirection = originalFlowDirection or FlowDirectionTypes.NO_FLOWDIRECTION;

	-- pStartPlot = the plot at whose SE corner the river is starting
	if (riverID == nil) then
		riverID = nextRiverID;
		nextRiverID = nextRiverID + 1;
	end

	local otherRiverID = _rivers[startPlot]
	if (otherRiverID ~= nil and otherRiverID ~= riverID and originalFlowDirection == FlowDirectionTypes.NO_FLOWDIRECTION) then
		return; -- Another river already exists here; can't branch off of an existing river!
	end

	local riverPlot;
	
	local bestFlowDirection = FlowDirectionTypes.NO_FLOWDIRECTION;
	if (thisFlowDirection == FlowDirectionTypes.FLOWDIRECTION_NORTH) then
	
		riverPlot = startPlot;
		local adjacentPlot = Map.PlotDirection(riverPlot:GetX(), riverPlot:GetY(), DirectionTypes.DIRECTION_EAST);
		if ( adjacentPlot == nil or riverPlot:IsWOfRiver() or riverPlot:IsWater() or adjacentPlot:IsWater() ) then
			return;
		end

		_rivers[riverPlot] = riverID;
		riverPlot:SetWOfRiver(true, thisFlowDirection);
		riverPlot = Map.PlotDirection(riverPlot:GetX(), riverPlot:GetY(), DirectionTypes.DIRECTION_NORTHEAST);
		
	elseif (thisFlowDirection == FlowDirectionTypes.FLOWDIRECTION_NORTHEAST) then
	
		riverPlot = startPlot;
		local adjacentPlot = Map.PlotDirection(riverPlot:GetX(), riverPlot:GetY(), DirectionTypes.DIRECTION_SOUTHEAST);
		if ( adjacentPlot == nil or riverPlot:IsNWOfRiver() or riverPlot:IsWater() or adjacentPlot:IsWater() ) then
			return;
		end

		_rivers[riverPlot] = riverID;
		riverPlot:SetNWOfRiver(true, thisFlowDirection);
		-- riverPlot does not change
	
	elseif (thisFlowDirection == FlowDirectionTypes.FLOWDIRECTION_SOUTHEAST) then
	
		riverPlot = Map.PlotDirection(startPlot:GetX(), startPlot:GetY(), DirectionTypes.DIRECTION_EAST);
		if (riverPlot == nil) then
			return;
		end
		
		local adjacentPlot = Map.PlotDirection(riverPlot:GetX(), riverPlot:GetY(), DirectionTypes.DIRECTION_SOUTHWEST);
		if (adjacentPlot == nil or riverPlot:IsNEOfRiver() or riverPlot:IsWater() or adjacentPlot:IsWater()) then
			return;
		end

		_rivers[riverPlot] = riverID;
		riverPlot:SetNEOfRiver(true, thisFlowDirection);
		-- riverPlot does not change
	
	elseif (thisFlowDirection == FlowDirectionTypes.FLOWDIRECTION_SOUTH) then
	
		riverPlot = Map.PlotDirection(startPlot:GetX(), startPlot:GetY(), DirectionTypes.DIRECTION_SOUTHWEST);
		if (riverPlot == nil) then
			return;
		end
		
		local adjacentPlot = Map.PlotDirection(riverPlot:GetX(), riverPlot:GetY(), DirectionTypes.DIRECTION_EAST);
		if (adjacentPlot == nil or riverPlot:IsWOfRiver() or riverPlot:IsWater() or adjacentPlot:IsWater()) then
			return;
		end
		
		_rivers[riverPlot] = riverID;
		riverPlot:SetWOfRiver(true, thisFlowDirection);
		-- riverPlot does not change
	
	elseif (thisFlowDirection == FlowDirectionTypes.FLOWDIRECTION_SOUTHWEST) then

		riverPlot = startPlot;
		local adjacentPlot = Map.PlotDirection(riverPlot:GetX(), riverPlot:GetY(), DirectionTypes.DIRECTION_SOUTHEAST);
		if (adjacentPlot == nil or riverPlot:IsNWOfRiver() or riverPlot:IsWater() or adjacentPlot:IsWater()) then
			return;
		end
		
		_rivers[riverPlot] = riverID;
		riverPlot:SetNWOfRiver(true, thisFlowDirection);
		-- riverPlot does not change

	elseif (thisFlowDirection == FlowDirectionTypes.FLOWDIRECTION_NORTHWEST) then
		
		riverPlot = startPlot;
		local adjacentPlot = Map.PlotDirection(riverPlot:GetX(), riverPlot:GetY(), DirectionTypes.DIRECTION_SOUTHWEST);
		
		if ( adjacentPlot == nil or riverPlot:IsNEOfRiver() or riverPlot:IsWater() or adjacentPlot:IsWater()) then
			return;
		end

		_rivers[riverPlot] = riverID;
		riverPlot:SetNEOfRiver(true, thisFlowDirection);
		riverPlot = Map.PlotDirection(riverPlot:GetX(), riverPlot:GetY(), DirectionTypes.DIRECTION_WEST);

	else
		-- River is starting here, set the direction in the next step
		riverPlot = startPlot;		
	end

	if (riverPlot == nil or riverPlot:IsWater()) then
		-- The river has flowed off the edge of the map or into the ocean. All is well.
		return; 
	end

	-- Storing X,Y positions as locals to prevent redundant function calls.
	local riverPlotX = riverPlot:GetX();
	local riverPlotY = riverPlot:GetY();
	
	-- Table of methods used to determine the adjacent plot.
	local adjacentPlotFunctions = {
		[FlowDirectionTypes.FLOWDIRECTION_NORTH] = function() 
			return Map.PlotDirection(riverPlotX, riverPlotY, DirectionTypes.DIRECTION_NORTHWEST); 
		end,
		
		[FlowDirectionTypes.FLOWDIRECTION_NORTHEAST] = function() 
			return Map.PlotDirection(riverPlotX, riverPlotY, DirectionTypes.DIRECTION_NORTHEAST);
		end,
		
		[FlowDirectionTypes.FLOWDIRECTION_SOUTHEAST] = function() 
			return Map.PlotDirection(riverPlotX, riverPlotY, DirectionTypes.DIRECTION_EAST);
		end,
		
		[FlowDirectionTypes.FLOWDIRECTION_SOUTH] = function() 
			return Map.PlotDirection(riverPlotX, riverPlotY, DirectionTypes.DIRECTION_SOUTHWEST);
		end,
		
		[FlowDirectionTypes.FLOWDIRECTION_SOUTHWEST] = function() 
			return Map.PlotDirection(riverPlotX, riverPlotY, DirectionTypes.DIRECTION_WEST);
		end,
		
		[FlowDirectionTypes.FLOWDIRECTION_NORTHWEST] = function() 
			return Map.PlotDirection(riverPlotX, riverPlotY, DirectionTypes.DIRECTION_NORTHWEST);
		end	
	}
	
	if(bestFlowDirection == FlowDirectionTypes.NO_FLOWDIRECTION) then

		-- Attempt to calculate the best flow direction.
		local bestValue = math.huge;
		for flowDirection, getAdjacentPlot in pairs(adjacentPlotFunctions) do
			
			if (GetOppositeFlowDirection(flowDirection) ~= originalFlowDirection) then
				
				if (thisFlowDirection == FlowDirectionTypes.NO_FLOWDIRECTION or
					flowDirection == TurnRightFlowDirections[thisFlowDirection] or 
					flowDirection == TurnLeftFlowDirections[thisFlowDirection]) then
				
					local adjacentPlot = getAdjacentPlot();
					
					if (adjacentPlot ~= nil) then
					
						local value = GetRiverValueAtPlot(adjacentPlot);
						if (flowDirection == originalFlowDirection) then
							value = (value * 3) / 4;
						end
						
						if (value < bestValue) then
							bestValue = value;
							bestFlowDirection = flowDirection;
						end

					-- Custom addition for Highlands, to fix river problems in top row of the map. Any other all-land map may need similar special casing.
					elseif adjacentPlot == nil and riverPlotY == iH - 1 then -- Top row of map, needs special handling
						if flowDirection == FlowDirectionTypes.FLOWDIRECTION_NORTH or
						   flowDirection == FlowDirectionTypes.FLOWDIRECTION_NORTHWEST or
						   flowDirection == FlowDirectionTypes.FLOWDIRECTION_NORTHEAST then
							
							local value = Map.Rand(5, "River Rand");
							if (flowDirection == originalFlowDirection) then
								value = (value * 3) / 4;
							end
							if (value < bestValue) then
								bestValue = value;
								bestFlowDirection = flowDirection;
							end
						end

					-- Custom addition for Highlands, to fix river problems in left column of the map. Any other all-land map may need similar special casing.
					elseif adjacentPlot == nil and riverPlotX == 0 then -- Left column of map, needs special handling
						if flowDirection == FlowDirectionTypes.FLOWDIRECTION_NORTH or
						   flowDirection == FlowDirectionTypes.FLOWDIRECTION_SOUTH or
						   flowDirection == FlowDirectionTypes.FLOWDIRECTION_NORTHWEST or
						   flowDirection == FlowDirectionTypes.FLOWDIRECTION_SOUTHWEST then
							
							local value = Map.Rand(5, "River Rand");
							if (flowDirection == originalFlowDirection) then
								value = (value * 3) / 4;
							end
							if (value < bestValue) then
								bestValue = value;
								bestFlowDirection = flowDirection;
							end
						end
					end
				end
			end
		end
		
		-- Try a second pass allowing the river to "flow backwards".
		if(bestFlowDirection == FlowDirectionTypes.NO_FLOWDIRECTION) then
		
			local bestValue = math.huge;
			for flowDirection, getAdjacentPlot in pairs(adjacentPlotFunctions) do
			
				if (thisFlowDirection == FlowDirectionTypes.NO_FLOWDIRECTION or
					flowDirection == TurnRightFlowDirections[thisFlowDirection] or 
					flowDirection == TurnLeftFlowDirections[thisFlowDirection]) then
				
					local adjacentPlot = getAdjacentPlot();
					
					if (adjacentPlot ~= nil) then
						
						local value = GetRiverValueAtPlot(adjacentPlot);
						if (value < bestValue) then
							bestValue = value;
							bestFlowDirection = flowDirection;
						end
					end	
				end
			end
		end
	end
	
	--Recursively generate river.
	if (bestFlowDirection ~= FlowDirectionTypes.NO_FLOWDIRECTION) then
		if  (originalFlowDirection == FlowDirectionTypes.NO_FLOWDIRECTION) then
			originalFlowDirection = bestFlowDirection;
		end
		
		DoRiver(riverPlot, bestFlowDirection, originalFlowDirection, riverID);
	end
end
------------------------------------------------------------------------------

------------------------------------------------------------------------------
function FeatureGenerator:AddIceAtPlot(plot, iX, iY, lat)
	-- Do nothing. No ice to be placed.
end
------------------------------------------------------------------------------
function FeatureGenerator:AddJunglesAtPlot(plot, iX, iY, lat)
	-- Do nothing. No jungle to be placed.
end
------------------------------------------------------------------------------
function FeatureGenerator:AddAtolls()
	-- Do nothing. No atolls to be placed.
end
------------------------------------------------------------------------------
function AddFeatures()
	print("Adding Features (Lua Europe) ...");
	local featuregen = FeatureGenerator.Create();

	featuregen:AddFeatures(false);
end
------------------------------------------------------------------------------

------------------------------------------------------------------------------
function AssignStartingPlots:__CustomInit()
	-- This function included to provide a quick and easy override for changing 
	-- any initial settings. Add your customized version to the map script.
	self.DivideBritain = AssignStartingPlots.DivideBritain;
	self.CanBeGibraltar = AssignStartingPlots.CanBeGibraltar;
	self.CanBeMtSinai = AssignStartingPlots.CanBeMtSinai;
	self.gibraltar_list, self.sinai_list = {}, {};
end	
------------------------------------------------------------------------------
function AssignStartingPlots:DivideBritain(iNumDivisions, fertility_table, rectangle_data_table)
	local iNumDivides = 0;
	local iSubdivisions = 0;
	local bPrimeGreaterThanThree = false;
	local firstSubdivisions = 0;
	local laterSubdivisions = 0;

	-- If this rectangle is not to be divided, break recursion and record the data.
	if (iNumDivisions == 1) then -- This area is to be defined as a Region.
		-- Expand rectangle table to include an eighth field for average fertility per plot.
		local fAverageFertility = rectangle_data_table[6] / rectangle_data_table[7]; -- fertilityCount/plotCount
		table.insert(rectangle_data_table, fAverageFertility);
		-- Insert this record in to the instance data for start placement regions for this game.
		-- (This is the crux of the entire regional definition process, determining an actual region.)
		table.insert(self.regionData, rectangle_data_table);
		--[[
		local iNumberOfThisRegion = table.maxn(self.regionData);
		print("-");
		print("---------------------------------------------");
		print("Defined location of Start Region #", iNumberOfThisRegion);
		print("---------------------------------------------");
		print("-");
		]]--
		return

	--[[ Divide this rectangle into iNumDivisions worth of subdivisions, then send each
	     subdivision back through this function in a recursive loop. ]]--
	else
		-- See if region is taller or wider.
		local iWidth = rectangle_data_table[3];
		local iHeight = rectangle_data_table[4];
		local bTaller = false;
		--print("*** DIVIDING BRITAIN in to unequal parts ***");

		-- If the number of divisions is 2 or 3, no further subdivision is required.
		iNumDivides = 2;
		iSubdivisions = 1;

		-- Now process the division via one of the three methods.
		-- All methods involve recursion, to obtain the best manner of subdividing each rectangle involved.
		--print("DivideIntoRegions: Divide in to Halves selected.");
		local results = self:ChopIntoTwoRegions(fertility_table, rectangle_data_table, bTaller, 38.5); -- CUSTOM, give Celtic region less land!
		local first_section_fertility_table = results[1];
		local first_section_data_table = results[2];
		local second_section_fertility_table = results[3];
		local second_section_data_table = results[4];
		--
		self:DivideIntoRegions(iSubdivisions, first_section_fertility_table, first_section_data_table)
		self:DivideIntoRegions(iSubdivisions, second_section_fertility_table, second_section_data_table)
	end
end
------------------------------------------------------------------------------
function AssignStartingPlots:GenerateRegions(args)
	-- Custom method for Europe Scenario. All regions defined by hand.
	print("Map Generation - Dividing the map in to Regions");
	local args = args or {};
	local iW, iH = Map.GetGridSize();
	self.method = 4;
	self.resource_setting = args.resources or 2; -- Each map script has to pass in parameter for Resource setting chosen by user.

	-- Determine number of civilizations and city states present in this game.
	self.iNumCivs, self.iNumCityStates, self.player_ID_list, self.bTeamGame, self.teams_with_major_civs, self.number_civs_per_team = GetPlayerAndTeamInfo()
	self.iNumCityStatesUnassigned = self.iNumCityStates;
	print("-"); print("***************************************");
	print("* Regional Definitions Begin *"); print("-");
	print("- Number of Civs: ", self.iNumCivs);
	print("- Number of CS: ", self.iNumCityStates); print("-");
	
	-- British Isles.
	self.inhabited_WestX = 2;
	self.inhabited_SouthY = math.floor(iH * 0.58);
	self.inhabited_Width = 20;
	self.inhabited_Height = math.ceil(iH * 0.35);
	local fert_table, fertCount, plotCount = self:MeasureStartPlacementFertilityInRectangle(self.inhabited_WestX, 
	                                         self.inhabited_SouthY, self.inhabited_Width, self.inhabited_Height)
	local rect_table = {self.inhabited_WestX, self.inhabited_SouthY, self.inhabited_Width, 
	                    self.inhabited_Height, -1, fertCount, plotCount}; -- AreaID -1 means ignore area IDs.
	self:DivideBritain(2, fert_table, rect_table)
	--print("- British Isles defined as Regions 1 and 2.");

	-- Morocco and Tunisia.
	self.inhabited_WestX = 3;
	self.inhabited_SouthY = 0;
	self.inhabited_Width = 38;
	self.inhabited_Height = 15;
	local fert_table, fertCount, plotCount = self:MeasureStartPlacementFertilityInRectangle(self.inhabited_WestX, 
	                                         self.inhabited_SouthY, self.inhabited_Width, self.inhabited_Height)
	local rect_table = {self.inhabited_WestX, self.inhabited_SouthY, self.inhabited_Width, 
	                    self.inhabited_Height, -1, fertCount, plotCount};
	self:DivideIntoRegions(1, fert_table, rect_table)
	--print("- Morocco and Tunisia defined as Region 3.");

	-- Egypt and Judea.
	self.inhabited_WestX = 56;
	self.inhabited_SouthY = 0;
	self.inhabited_Width = 24;
	self.inhabited_Height = 15;
	local fert_table, fertCount, plotCount = self:MeasureStartPlacementFertilityInRectangle(self.inhabited_WestX, 
	                                         self.inhabited_SouthY, self.inhabited_Width, self.inhabited_Height)
	local rect_table = {self.inhabited_WestX, self.inhabited_SouthY, self.inhabited_Width, 
	                    self.inhabited_Height, -1, fertCount, plotCount};
	self:DivideIntoRegions(1, fert_table, rect_table)
	--print("- Egypt and Judea defined as Region 4.");

	-- Turkey.
	self.inhabited_WestX = 60;
	self.inhabited_SouthY = 17;
	self.inhabited_Width = 20;
	self.inhabited_Height = 18;
	local fert_table, fertCount, plotCount = self:MeasureStartPlacementFertilityInRectangle(self.inhabited_WestX, 
	                                         self.inhabited_SouthY, self.inhabited_Width, self.inhabited_Height)
	local rect_table = {self.inhabited_WestX, self.inhabited_SouthY, self.inhabited_Width, 
	                    self.inhabited_Height, -1, fertCount, plotCount};
	self:DivideIntoRegions(1, fert_table, rect_table)
	--print("- Turkey defined as Region 5.");

	-- Balkans.
	self.inhabited_WestX = 42;
	self.inhabited_SouthY = 15;
	self.inhabited_Width = 18;
	self.inhabited_Height = 15;
	local fert_table, fertCount, plotCount = self:MeasureStartPlacementFertilityInRectangle(self.inhabited_WestX, 
	                                         self.inhabited_SouthY, self.inhabited_Width, self.inhabited_Height)
	local rect_table = {self.inhabited_WestX, self.inhabited_SouthY, self.inhabited_Width, 
	                    self.inhabited_Height, -1, fertCount, plotCount};
	self:DivideIntoRegions(1, fert_table, rect_table)
	--print("- Balkans defined as Region 6.");

	-- Spain.
	self.inhabited_WestX = 6;
	self.inhabited_SouthY = 16;
	self.inhabited_Width = 15;
	self.inhabited_Height = 9;
	local fert_table, fertCount, plotCount = self:MeasureStartPlacementFertilityInRectangle(self.inhabited_WestX, 
	                                         self.inhabited_SouthY, self.inhabited_Width, self.inhabited_Height)
	local rect_table = {self.inhabited_WestX, self.inhabited_SouthY, self.inhabited_Width, 
	                    self.inhabited_Height, -1, fertCount, plotCount};
	self:DivideIntoRegions(1, fert_table, rect_table)
	--print("- Spain defined as Region 7.");

	-- 
	self.inhabited_WestX = 6;
	self.inhabited_SouthY = 25;
	self.inhabited_Width = 13;
	self.inhabited_Height = 12;
	local fert_table, fertCount, plotCount = self:MeasureStartPlacementFertilityInRectangle(self.inhabited_WestX, 
	                                         self.inhabited_SouthY, self.inhabited_Width, self.inhabited_Height)
	local rect_table = {self.inhabited_WestX, self.inhabited_SouthY, self.inhabited_Width, 
	                    self.inhabited_Height, -1, fertCount, plotCount};
	self:DivideIntoRegions(1, fert_table, rect_table)
	--print("- France defined as Region 8.");

	-- Netherlands.
	self.inhabited_WestX = 19;
	self.inhabited_SouthY = 30;
	self.inhabited_Width = 9;
	self.inhabited_Height = 13;
	local fert_table, fertCount, plotCount = self:MeasureStartPlacementFertilityInRectangle(self.inhabited_WestX, 
	                                         self.inhabited_SouthY, self.inhabited_Width, self.inhabited_Height)
	local rect_table = {self.inhabited_WestX, self.inhabited_SouthY, self.inhabited_Width, 
	                    self.inhabited_Height, -1, fertCount, plotCount};
	self:DivideIntoRegions(1, fert_table, rect_table)
	--print("- Netherlands defined as Region 9.");

	-- Central Europe.
	self.inhabited_WestX = 35;
	self.inhabited_SouthY = 26;
	self.inhabited_Width = 24;
	self.inhabited_Height = 22;
	local fert_table, fertCount, plotCount = self:MeasureStartPlacementFertilityInRectangle(self.inhabited_WestX, 
	                                         self.inhabited_SouthY, self.inhabited_Width, self.inhabited_Height)
	local rect_table = {self.inhabited_WestX, self.inhabited_SouthY, self.inhabited_Width, 
	                    self.inhabited_Height, -1, fertCount, plotCount};
	self:DivideIntoRegions(1, fert_table, rect_table)
	--print("- Central Europe defined as Region 10.");

	-- Scandinavia.
	self.inhabited_WestX = 23;
	self.inhabited_SouthY = 50;
	self.inhabited_Width = 20;
	self.inhabited_Height = 14;
	local fert_table, fertCount, plotCount = self:MeasureStartPlacementFertilityInRectangle(self.inhabited_WestX, 
	                                         self.inhabited_SouthY, self.inhabited_Width, self.inhabited_Height)
	local rect_table = {self.inhabited_WestX, self.inhabited_SouthY, self.inhabited_Width, 
	                    self.inhabited_Height, -1, fertCount, plotCount};
	self:DivideIntoRegions(1, fert_table, rect_table)
	--print("- Scandinavia defined as Region 11.");

	-- Russia.
	self.inhabited_WestX = 51;
	self.inhabited_SouthY = 39;
	self.inhabited_Width = 29;
	self.inhabited_Height = 25;
	local fert_table, fertCount, plotCount = self:MeasureStartPlacementFertilityInRectangle(self.inhabited_WestX, 
	                                         self.inhabited_SouthY, self.inhabited_Width, self.inhabited_Height)
	local rect_table = {self.inhabited_WestX, self.inhabited_SouthY, self.inhabited_Width, 
	                    self.inhabited_Height, -1, fertCount, plotCount};
	self:DivideIntoRegions(1, fert_table, rect_table)
	--print("- Russia defined as Region 12.");

end
------------------------------------------------------------------------------
function AssignStartingPlots:PlaceImpactAndRipples(x, y)
	-- Custom for Europe Scenario, reducing City State min distance from 7 to 6.
	local iW, iH = Map.GetGridSize();
	local wrapX = Map:IsWrapX();
	local wrapY = Map:IsWrapY();
	local impact_value = 99;
	local ripple_values = {97, 95, 92, 89, 69, 57, 24, 15};
	local odd = self.firstRingYIsOdd;
	local even = self.firstRingYIsEven;
	local nextX, nextY, plot_adjustments;
	-- Start points need to impact the resource layers, so let's handle that first.
	self:PlaceResourceImpact(x, y, 1, 0) -- Strategic layer, at impact site only.
	self:PlaceResourceImpact(x, y, 2, 3) -- Luxury layer, set all plots within this civ start as off limits.
	self:PlaceResourceImpact(x, y, 3, 3) -- Bonus layer
	self:PlaceResourceImpact(x, y, 4, 3) -- Fish layer
	self:PlaceResourceImpact(x, y, 6, 4) -- Natural Wonders layer, set a minimum distance of 5 plots (4 ripples) away.
	-- Now the main data layer, for start points themselves, and the City State data layer.
	-- Place Impact!
	local impactPlotIndex = y * iW + x + 1;
	self.distanceData[impactPlotIndex] = impact_value;
	self.playerCollisionData[impactPlotIndex] = true;
	self.cityStateData[impactPlotIndex] = 1;
	-- Place Ripples
	for ripple_radius, ripple_value in ipairs(ripple_values) do
		-- Moving clockwise around the ring, the first direction to travel will be Northeast.
		-- This matches the direction-based data in the odd and even tables. Each
		-- subsequent change in direction will correctly match with these tables, too.
		--
		-- Locate the plot within this ripple ring that is due West of the Impact Plot.
		local currentX = x - ripple_radius;
		local currentY = y;
		-- Now loop through the six directions, moving ripple_radius number of times
		-- per direction. At each plot in the ring, add the ripple_value for that ring 
		-- to the plot's entry in the distance data table.
		for direction_index = 1, 6 do
			for plot_to_handle = 1, ripple_radius do
				-- Must account for hex factor.
			 	if currentY / 2 > math.floor(currentY / 2) then -- Current Y is odd. Use odd table.
					plot_adjustments = odd[direction_index];
				else -- Current Y is even. Use plot adjustments from even table.
					plot_adjustments = even[direction_index];
				end
				-- Identify the next plot in the ring.
				nextX = currentX + plot_adjustments[1];
				nextY = currentY + plot_adjustments[2];
				-- Make sure the plot exists
				if wrapX == false and (nextX < 0 or nextX >= iW) then -- X is out of bounds.
					-- Do not add ripple data to this plot.
				elseif wrapY == false and (nextY < 0 or nextY >= iH) then -- Y is out of bounds.
					-- Do not add ripple data to this plot.
				else -- Plot is in bounds, process it.
					-- Handle any world wrap.
					local realX = nextX;
					local realY = nextY;
					if wrapX then
						realX = realX % iW;
					end
					if wrapY then
						realY = realY % iH;
					end
					-- Record ripple data for this plot.
					local ringPlotIndex = realY * iW + realX + 1;
					if self.distanceData[ringPlotIndex] > 0 then -- This plot is already in range of at least one other civ!
						-- First choose the greater of the two, existing value or current ripple.
						local stronger_value = math.max(self.distanceData[ringPlotIndex], ripple_value);
						-- Now increase it by 1.2x to reflect that multiple civs are in range of this plot.
						local overlap_value = math.min(97, math.floor(stronger_value * 1.2));
						self.distanceData[ringPlotIndex] = overlap_value;
					else
						self.distanceData[ringPlotIndex] = ripple_value;
					end
					-- Now impact the City State layer if appropriate.
					if ripple_radius <= 5 then
						self.cityStateData[ringPlotIndex] = 1;
					end
				end
				currentX, currentY = nextX, nextY;
			end
		end
	end
end
------------------------------------------------------------------------------
function AssignStartingPlots:BalanceAndAssign()

	-- Normalize each start plot location.
	local iNumStarts = table.maxn(self.startingPlots);
	for region_number = 1, iNumStarts do
		self:NormalizeStartLocation(region_number)
	end
	--PrintContentsOfTable(self.startingPlots)
	--print("-"); print("+++ Readout of Civ Placements +++");

	-- England
	local region_number = 2;
	local x = self.startingPlots[region_number][1];
	local y = self.startingPlots[region_number][2];
	local start_plot = Map.GetPlot(x, y)
	local player = Players[England_PlayerID];
	player:SetStartingPlot(start_plot)
	--print("England being placed in plot " .. x .. ", " .. y .. ".");

	-- Celts
	local region_number = 1;
	local x = self.startingPlots[region_number][1];
	local y = self.startingPlots[region_number][2];
	local start_plot = Map.GetPlot(x, y)
	local player = Players[Celts_PlayerID];
	player:SetStartingPlot(start_plot)
	--print("Celts being placed in plot " .. x .. ", " .. y .. ".");

	-- Arabia
	local region_number = 3;
	local x = self.startingPlots[region_number][1];
	local y = self.startingPlots[region_number][2];
	local start_plot = Map.GetPlot(x, y)
	local player = Players[Arabia_PlayerID];
	player:SetStartingPlot(start_plot)
	--print("Arabia being placed in plot " .. x .. ", " .. y .. ".");

	-- Songhai
	local region_number = 4;
	local x = self.startingPlots[region_number][1];
	local y = self.startingPlots[region_number][2];
	local start_plot = Map.GetPlot(x, y)
	local player = Players[Songhai_PlayerID];
	player:SetStartingPlot(start_plot)
	--print("Songhai being placed in plot " .. x .. ", " .. y .. ".");

	-- Ottomans
	local region_number = 5;
	local x = self.startingPlots[region_number][1];
	local y = self.startingPlots[region_number][2];
	local start_plot = Map.GetPlot(x, y)
	local player = Players[Ottomans_PlayerID];
	player:SetStartingPlot(start_plot)
	--print("Ottomans being placed in plot " .. x .. ", " .. y .. ".");

	-- Byzantium
	local region_number = 6;
	local x = self.startingPlots[region_number][1];
	local y = self.startingPlots[region_number][2];
	local start_plot = Map.GetPlot(x, y)
	local player = Players[Byzantium_PlayerID];
	player:SetStartingPlot(start_plot)
	--print("Byzantium being placed in plot " .. x .. ", " .. y .. ".");

	-- Spain
	local region_number = 7;
	local x = self.startingPlots[region_number][1];
	local y = self.startingPlots[region_number][2];
	local start_plot = Map.GetPlot(x, y)
	local player = Players[Spain_PlayerID];
	player:SetStartingPlot(start_plot)
	--print("Spain being placed in plot " .. x .. ", " .. y .. ".");

	-- France
	local region_number = 8;
	local x = self.startingPlots[region_number][1];
	local y = self.startingPlots[region_number][2];
	local start_plot = Map.GetPlot(x, y)
	local player = Players[France_PlayerID];
	player:SetStartingPlot(start_plot)
	--print("France being placed in plot " .. x .. ", " .. y .. ".");

	-- Netherlands
	local region_number = 9;
	local x = self.startingPlots[region_number][1];
	local y = self.startingPlots[region_number][2];
	local start_plot = Map.GetPlot(x, y)
	local player = Players[Netherlands_PlayerID];
	player:SetStartingPlot(start_plot)
	--print("Netherlands being placed in plot " .. x .. ", " .. y .. ".");

	-- Austria
	local region_number = 10;
	local x = self.startingPlots[region_number][1];
	local y = self.startingPlots[region_number][2];
	local start_plot = Map.GetPlot(x, y)
	local player = Players[Austria_PlayerID];
	player:SetStartingPlot(start_plot)
	--print("Austria being placed in plot " .. x .. ", " .. y .. ".");

	-- Sweden
	local region_number = 11;
	local x = self.startingPlots[region_number][1];
	local y = self.startingPlots[region_number][2];
	local start_plot = Map.GetPlot(x, y)
	local player = Players[Sweden_PlayerID];
	player:SetStartingPlot(start_plot)
	--print("Sweden being placed in plot " .. x .. ", " .. y .. ".");

	-- Russia
	local region_number = 12;
	local x = self.startingPlots[region_number][1];
	local y = self.startingPlots[region_number][2];
	local start_plot = Map.GetPlot(x, y)
	local player = Players[Russia_PlayerID];
	player:SetStartingPlot(start_plot)
	--print("Russia being placed in plot " .. x .. ", " .. y .. ".");
	
end
------------------------------------------------------------------------------
function AssignStartingPlots:ExaminePlotForNaturalWondersEligibility(x, y)
	-- This function checks only for eligibility requirements applicable to all 
	-- Natural Wonders. If a candidate plot passes all such checks, we will move
	-- on to checking it against specific needs for each particular NW.
	local iW, iH = Map.GetGridSize();
	local plotIndex = iW * y + x + 1;
	-- Check for collision with player starts
	if self.naturalWondersData[plotIndex] > 0 then
		return false
	end
	-- Custom for Europe.
	if not (((x >= iW * 0.1 and x <= iW * 0.3) and (y >= iH * 0.15 and y <= iH * 0.35)) or (x >= iW * 0.9 and y <= iH * 0.15)) then
		return false
	end
	-- Check for River and Lake
	local plot = Map.GetPlot(x, y);
	if plot:IsRiver() or plot:IsLake() then
		return false
	end
	-- Check for Snow
	local terrainType = plot:GetTerrainType();
	if terrainType == TerrainTypes.TERRAIN_SNOW then
		return false
	end
	-- Check for Feature Ice
	local featureType = plot:GetFeatureType();
	if featureType == FeatureTypes.FEATURE_ICE then
		return false
	end
	return true
end
------------------------------------------------------------------------------
function AssignStartingPlots:ExamineCandidatePlotForNaturalWondersEligibility(x, y)
	-- This function checks only for eligibility requirements applicable to all 
	-- Natural Wonders. If a candidate plot passes all such checks, we will move
	-- on to checking it against specific needs for each particular NW.
	if self:ExaminePlotForNaturalWondersEligibility(x, y) == false then
		return false
	end
	local iW, iH = Map.GetGridSize();
	-- Now loop through adjacent plots. Using Map.PlotDirection() in combination with
	-- direction types, an alternate first-ring hex adjustment method, instead of the
	-- odd/even tables used elsewhere in this file, which often have to process more rings.
	for loop, direction in ipairs(self.direction_types) do
		local adjPlot = Map.PlotDirection(x, y, direction)
		if adjPlot == nil then
			return false
		else
			local adjX = adjPlot:GetX();
			local adjY = adjPlot:GetY();
			if self:ExaminePlotForNaturalWondersEligibility(adjX, adjY) == false then
				return false
			end
		end
	end
	return true
end
------------------------------------------------------------------------------
function AssignStartingPlots:CanBeGibraltar(x, y)
	-- Checks a candidate plot for eligibility to be Rock of Gibraltar.
	local plot = Map.GetPlot(x, y);
	-- Checking center plot, which must be in the water or on the coast.
	local iW, iH = Map.GetGridSize();
	local plotIndex = y * iW + x + 1;
	if self.plotDataIsCoastal[plotIndex] == false and plot:IsWater() == false then
		return
	end
	-- Now process the surrounding plots. Desert is not tolerable. We don't want too many mountains or plains.
	-- We are looking for a site that does not have unwanted traits but does have jungles or hills.
	local iNumLand, iNumCoast = 0, 0;
	for loop, direction in ipairs(self.direction_types) do
		local adjPlot = Map.PlotDirection(x, y, direction)
		local plotType = adjPlot:GetPlotType();
		local terrainType = adjPlot:GetTerrainType()
		local featureType = adjPlot:GetFeatureType()
		if terrainType == TerrainTypes.TERRAIN_COAST and plot:IsLake() == false then
			if featureType == FeatureTypes.NO_FEATURE then
				iNumCoast = iNumCoast + 1;
			end
		end
		if plotType ~= PlotTypes.PLOT_OCEAN then
			iNumLand = iNumLand + 1;
		end
	end
	-- If too much land, reject this site.
	if iNumLand ~= 1 then
		return
	end
	-- If not enough coast, reject this site.
	if iNumCoast < 4 then
		return
	end
	-- This site is good.
	table.insert(self.gibraltar_list, plotIndex);
end
------------------------------------------------------------------------------
function AssignStartingPlots:CanBeMtSinai(x, y)
	-- Checks a candidate plot for eligibility to be Mt Sinai.
	local plot = Map.GetPlot(x, y);
	-- Checking center plot, which must be at least one plot away from any salt water.
	if plot:IsWater() then
		return
	end
	local iW, iH = Map.GetGridSize();
	local plotIndex = y * iW + x + 1;
	if self.plotDataIsCoastal[plotIndex] == true then
		return
	end
	local terrainType = plot:GetTerrainType()
	local iNumMountains, iNumHills, iNumDesert = 0, 0, 0;
	local plotType = plot:GetPlotType();
	if plotType == PlotTypes.PLOT_MOUNTAIN then
		iNumMountains = iNumMountains + 1;
	elseif plotType == PlotTypes.PLOT_HILLS then
		iNumHills = iNumHills + 1;
	end
	-- Now process the surrounding plots.
	for loop, direction in ipairs(self.direction_types) do
		local adjPlot = Map.PlotDirection(x, y, direction)
		if adjPlot:IsLake() then
			return
		end
		terrainType = adjPlot:GetTerrainType()
		if terrainType == TerrainTypes.TERRAIN_DESERT then
			iNumDesert = iNumDesert + 1;
		end
		plotType = adjPlot:GetPlotType();
		if plotType == PlotTypes.PLOT_MOUNTAIN then
			iNumMountains = iNumMountains + 1;
		elseif plotType == PlotTypes.PLOT_HILLS then
			iNumHills = iNumHills + 1;
		end
	end
	-- If not enough desert, reject this site.
	if iNumDesert < 2 then
		return
	end
	-- If too many mountains, reject this site.
	if iNumMountains > 3 then
		return
	end
	-- If not enough hills, reject this site.
	if iNumHills + iNumMountains < 1 then
		return
	end
	table.insert(self.sinai_list, plotIndex);
end
------------------------------------------------------------------------------
function AssignStartingPlots:GenerateNaturalWondersCandidatePlotLists()
	-- This function scans the map for eligible sites for all "Natural Wonders" Features.
	local iW, iH = Map.GetGridSize();
	-- Set up Landmass check for Mount Fuji (it's not to be on the biggest landmass, if the world has oceans).
	local biggest_landmass = Map.FindBiggestArea(false)
	self.iBiggestLandmassID = biggest_landmass:GetID()
	local biggest_ocean = Map.FindBiggestArea(true)
	local iNumBiggestOceanPlots = biggest_ocean:GetNumTiles()
	if iNumBiggestOceanPlots > (iW * iH) / 4 then
		self.bWorldHasOceans = true;
	else
		self.bWorldHasOceans = false;
	end
	-- Main loop
	for y = 0, iH - 1 do
		for x = 0, iW - 1 do
			if self:ExamineCandidatePlotForNaturalWondersEligibility(x, y) == true then
				-- Plot has passed checks applicable to all NW types. Move on to specific checks.
				self:CanBeGibraltar(x, y)
				self:CanBeMtSinai(x, y)
			end
		end
	end
	-- Eligibility will affect which NWs can be used, and number of candidates will affect placement order.
	local iCanBeGibraltar = table.maxn(self.gibraltar_list);
	local iCanBeSinai = table.maxn(self.sinai_list);

	-- Sort the wonders with fewest candidates listed first.
	-- If the Geyser is eligible, always choose it and give it top priority.
	local NW_eligibility_order, NW_eligibility_unsorted, NW_eligibility_sorted = {}, {}, {}; 
	if iCanBeGibraltar > 0 then
		table.insert(NW_eligibility_unsorted, {3, iCanBeGibraltar});
		table.insert(NW_eligibility_sorted, iCanBeGibraltar);
	end
	if iCanBeSinai > 0 then
		table.insert(NW_eligibility_unsorted, {11, iCanBeSinai});
		table.insert(NW_eligibility_sorted, iCanBeSinai);
	end
	table.sort(NW_eligibility_sorted);
	
	-- Match each sorted eligibility count to the matching unsorted NW number and record in sequence.
	for NW_order = 1, 2 do
		for loop, data_pair in ipairs(NW_eligibility_unsorted) do
			local unsorted_count = data_pair[2];
			if NW_eligibility_sorted[NW_order] == unsorted_count then
				local unsorted_NW_num = data_pair[1];
				table.insert(NW_eligibility_order, unsorted_NW_num);
				table.remove(NW_eligibility_unsorted, loop);
				break
			end
		end
	end
	
	--[[ Debug printout of natural wonder candidate plot lists
	print("-"); print("-"); print("--- Number of Candidate Plots on the map for Natural Wonders ---"); print("-");
	print("- Gibraltar:", iCanBeGibraltar);
	print("- Mt Sinai:", iCanBeSinai);
	print("-"); print("--- End of candidates readout for Natural Wonders ---"); print("-");	
	]]--

	return NW_eligibility_order;
end
------------------------------------------------------------------------------
function AssignStartingPlots:AttemptToPlaceNaturalWonder(iNaturalWonderNumber)
	-- Attempt to place a specific Natural Wonder.
	-- 1 Everest - 2 Crater - 3 Titicaca - 4 Fuji - 5 Mesa - 6 Reef - 7 Krakatoa (unforced) - 8 Krakatoa (forced)
	local iW, iH = Map.GetGridSize();
	local wonder_list = table.fill(-1, 8);
	for thisFeature in GameInfo.Features() do
		if thisFeature.Type == "FEATURE_MT_SINAI" then
			wonder_list[11] = thisFeature.ID;
		elseif thisFeature.Type == "FEATURE_GIBRALTAR" then
			wonder_list[3] = thisFeature.ID;
		end
	end

	if iNaturalWonderNumber == 3 then -- Gibraltar
		local candidate_plot_list = GetShuffledCopyOfTable(self.gibraltar_list)
		for loop, plotIndex in ipairs(candidate_plot_list) do
			if self.naturalWondersData[plotIndex] == 0 then -- No collision with civ start or other NW, so place Titicaca here!
				local x = (plotIndex - 1) % iW;
				local y = (plotIndex - x - 1) / iW;
				local plot = Map.GetPlot(x, y);
				-- Where it does not already, force the local terrain to conform to what the NW needs.
				plot:SetPlotType(PlotTypes.PLOT_LAND, false, false);
				plot:SetTerrainType(TerrainTypes.TERRAIN_GRASS, false, false)
				for loop, direction in ipairs(self.direction_types) do
					local adjPlot = Map.PlotDirection(x, y, direction)
					if adjPlot:GetPlotType() == PlotTypes.PLOT_OCEAN then
						if adjPlot:GetTerrainType() ~= TerrainTypes.TERRAIN_COAST then
							adjPlot:SetTerrainType(TerrainTypes.TERRAIN_COAST, false, false)
						end
					else
						if adjPlot:GetPlotType() ~= PlotTypes.PLOT_LAND then
							adjPlot:SetPlotType(PlotTypes.PLOT_LAND, false, false);
						end
					end
				end
				-- Now place Gibraltar and record the placement.
				plot:SetFeatureType(wonder_list[3])
				table.insert(self.placed_natural_wonder, 3);
				self:PlaceResourceImpact(x, y, 6, math.floor(iH / 5))	-- Natural Wonders layer
				self:PlaceResourceImpact(x, y, 1, 1)					-- Strategic layer
				self:PlaceResourceImpact(x, y, 2, 1)					-- Luxury layer
				self:PlaceResourceImpact(x, y, 3, 1)					-- Bonus layer
				self:PlaceResourceImpact(x, y, 5, 1)					-- City State layer
				self:PlaceResourceImpact(x, y, 7, 1)					-- Marble layer
				local plotIndex = y * iW + x + 1;
				self.playerCollisionData[plotIndex] = true;				-- Record exact plot of wonder in the collision list.
				--
				--print("- Placed Gibraltar in Plot", x, y);
				--
				return true
			end
		end
		-- If reached here, Gibraltar was unable to be placed because all candidates are too close to an already-placed NW.
		return false

	elseif iNaturalWonderNumber == 11 then -- MtSinai
		local candidate_plot_list = GetShuffledCopyOfTable(self.sinai_list)
		for loop, plotIndex in ipairs(candidate_plot_list) do
			if self.naturalWondersData[plotIndex] == 0 then -- No collision with civ start or other NW, so place Mesa here!
				local x = (plotIndex - 1) % iW;
				local y = (plotIndex - x - 1) / iW;
				local plot = Map.GetPlot(x, y);
				-- Where it does not already, force the local terrain to conform to what the NW needs.
				if not plot:IsMountain() then
					plot:SetPlotType(PlotTypes.PLOT_MOUNTAIN, false, false);
				end
				if plot:GetTerrainType() ~= TerrainTypes.TERRAIN_DESERT then
					plot:SetTerrainType(TerrainTypes.TERRAIN_DESERT, false, false)
				end
				-- Now place Mesa and record the placement.
				plot:SetFeatureType(wonder_list[11])
				table.insert(self.placed_natural_wonder, 11);
				self:PlaceResourceImpact(x, y, 6, math.floor(iH / 5))	-- Natural Wonders layer
				self:PlaceResourceImpact(x, y, 1, 1)					-- Strategic layer
				self:PlaceResourceImpact(x, y, 2, 1)					-- Luxury layer
				self:PlaceResourceImpact(x, y, 3, 1)					-- Bonus layer
				self:PlaceResourceImpact(x, y, 5, 1)					-- City State layer
				self:PlaceResourceImpact(x, y, 7, 1)					-- Marble layer
				local plotIndex = y * iW + x + 1;
				self.playerCollisionData[plotIndex] = true;				-- Record exact plot of wonder in the collision list.
				return true
			end
		end
		return false

	end
	print("Unsupported Natural Wonder Number:", iNaturalWonderNumber);
	return false
end
------------------------------------------------------------------------------
function AssignStartingPlots:PlaceNaturalWonders()
	local NW_eligibility_order = self:GenerateNaturalWondersCandidatePlotLists()
	local iNumNWCandidates = table.maxn(NW_eligibility_order);
	if iNumNWCandidates == 0 then
		--print("No Natural Wonders placed, no eligible sites found for any of them.");
		return
	end
	local iNumNWtoPlace = 2;
	local selected_NWs, fallback_NWs = {}, {};
	local iNumSelectedSoFar = 0;
	-- If Geyser is eligible, always choose it. (This is because its eligibility requirements are so much steeper.)
	if NW_eligibility_order[1] == 1 then
		table.insert(selected_NWs, NW_eligibility_order[1]);
		--[[ This was a section to give a second NW the "always choose" priority, but that wonder got changed.
		if NW_eligibility_order[2] == 3 then
			table.insert(selected_NWs, 3);
			table.remove(NW_eligibility_order, 2);
			iNumSelectedSoFar = iNumSelectedSoFar + 1;
		end
		]]--
		table.remove(NW_eligibility_order, 1);
		iNumSelectedSoFar = iNumSelectedSoFar + 1;
	end
	-- Choose a random selection from the others, to reach the quota to place. If any left over, set as fallbacks.
	local NW_shuffled_order = GetShuffledCopyOfTable(NW_eligibility_order);
	for loop, NW in ipairs(NW_eligibility_order) do
		for test_loop, shuffled_NW in ipairs(NW_shuffled_order) do
			if shuffled_NW == NW then
				if test_loop <= iNumNWtoPlace - iNumSelectedSoFar then
					table.insert(selected_NWs, NW);
				else
					table.insert(fallback_NWs, NW);
				end
			end
		end
	end
	-- Place the NWs
	local iNumPlaced = 0;
	for loop, NW in ipairs(selected_NWs) do
		local bSuccess = self:AttemptToPlaceNaturalWonder(NW)
		if bSuccess then
			iNumPlaced = iNumPlaced + 1;
		end
	end
	if iNumPlaced < iNumNWtoPlace then
		for loop, NW in ipairs(fallback_NWs) do
			if iNumPlaced >= iNumNWtoPlace then
				break
			end
			local bSuccess = self:AttemptToPlaceNaturalWonder(NW)
			if bSuccess then
				iNumPlaced = iNumPlaced + 1;
			end
		end
	end
end
------------------------------------------------------------------------------
function AssignStartingPlots:AssignCityStatesToRegionsOrToUninhabited(args)
	-- Custom for Europe Scenario. Regions are hand drawn, CS assignments hardcoded.
	local regional_assignment_data = {
		1,
		3, 3, 3,
		4,
		5,
		6, 6,
		7,
		8, 8,
		9, 
		10, 10, 10, 10, 10, 10, 10, 10, 10,
		11, 11,
		12, 12,
	};
	for loop = 1, 25 do
		self.city_state_region_assignments[loop] = regional_assignment_data[loop];
	end
	self.iNumCityStatesUninhabited = 0;
end
------------------------------------------------------------------------------
function AssignStartingPlots:PlaceCityStateInRegion(city_state_number, region_number)
	--print("Place City State in Region called for City State", city_state_number, "Region", region_number);
	local iW, iH = Map.GetGridSize();
	local placed_city_state = false;
	local reached_middle = false;
	local region_data_table = self.regionData[region_number];
	local iWestX = region_data_table[1];
	local iSouthY = region_data_table[2];
	local iWidth = region_data_table[3];
	local iHeight = region_data_table[4];
	local iAreaID = region_data_table[5];
	
	local eligible_coastal, eligible_inland = {}, {};
	
	-- Main loop, first pass, unforced
	local x, y;
	local curWX = iWestX;
	local curSY = iSouthY;
	local curWid = iWidth;
	local curHei = iHeight;
	while placed_city_state == false and reached_middle == false do
		-- Send the remaining unprocessed portion of the region to be processed.
		local nextWX, nextSY, nextWid, nextHei;
		eligible_coastal, eligible_inland, nextWX, nextSY, nextWid, nextHei, 
		  reached_middle = self:ObtainNextSectionInRegion(curWX, curSY, curWid, curHei, iAreaID, false, false) -- Don't force it. Yet.
		curWX, curSY, curWid, curHei = nextWX, nextSY, nextWid, nextHei;
		-- Attempt to place city state using the two plot lists received from the last call.
		x, y, placed_city_state = self:PlaceCityState(eligible_coastal, eligible_inland, false, false) -- Don't need to re-check collisions.
	end
	
	if placed_city_state == true then
		-- Record and enact the placement.
		self.cityStatePlots[city_state_number] = {x, y, region_number};
		self.city_state_validity_table[city_state_number] = true; -- This is the line that marks a city state as valid to be processed by the rest of the system.
		local city_state_ID = city_state_number + GameDefines.MAX_MAJOR_CIVS - 1;
		local cityState = Players[city_state_ID];
		local cs_start_plot = Map.GetPlot(x, y)
		cityState:SetStartingPlot(cs_start_plot)
		self:GenerateLuxuryPlotListsAtCitySite(x, y, 1, true) -- Removes Feature Ice from coasts adjacent to the city state's new location
		self:PlaceResourceImpact(x, y, 5, 3) -- City State layer *** Custom for Europe Scenario, down from 4 ***
		self:PlaceResourceImpact(x, y, 2, 3) -- Luxury layer
		self:PlaceResourceImpact(x, y, 1, 0) -- Strategic layer, at start point only.
		self:PlaceResourceImpact(x, y, 3, 3) -- Bonus layer
		self:PlaceResourceImpact(x, y, 4, 3) -- Fish layer
		self:PlaceResourceImpact(x, y, 7, 3) -- Marble layer
		local impactPlotIndex = y * iW + x + 1;
		self.playerCollisionData[impactPlotIndex] = true;
		--print("-"); print("City State", city_state_number, "has been started at Plot", x, y, "in Region#", region_number);
	else
		--print("-"); print("WARNING: Crowding issues for City State #", city_state_number, " - Could not find valid site in Region#", region_number);
		self.iNumCityStatesDiscarded = self.iNumCityStatesDiscarded + 1;
	end
end
------------------------------------------------------------------------------
function AssignStartingPlots:PlaceCityStates()
	print("Map Generation - Choosing sites for City States");
	-- This function is dependent on AssignLuxuryRoles() having been executed first.
	-- This is because some city state placements are made in compensation for drawing
	-- the short straw in regard to multiple regions being assigned the same luxury type.

	self:AssignCityStatesToRegionsOrToUninhabited()
	
	--print("-"); print("--- City State Placement Results ---");

	local iW, iH = Map.GetGridSize();
	for cs_number, region_number in ipairs(self.city_state_region_assignments) do
		if cs_number <= self.iNumCityStates then -- Make sure it's an active city state before processing.
			--print("Place City States, place in Region#", region_number, "for City State", cs_number);
			self:PlaceCityStateInRegion(cs_number, region_number)
		end
	end
	
	if self.iNumCityStatesDiscarded > 0 then
		--print("*** ALERT ***");
		--print("- Discarding " .. self.iNumCityStatesDiscarded .. " City States!"); print("***");
	end
end
------------------------------------------------------------------------------
function AssignStartingPlots:PlaceLuxuries()
	-- This function is dependent upon AssignLuxuryRoles() and PlaceCityStates() having been executed first.
	local iW, iH = Map.GetGridSize();
	-- Place Luxuries at civ start locations.
	for loop, reg_data in ipairs(self.regions_sorted_by_type) do
		local region_number = reg_data[1];
		local this_region_luxury = reg_data[2];
		local x = self.startingPlots[region_number][1];
		local y = self.startingPlots[region_number][2];
		--print("-"); print("Attempting to place Luxury#", this_region_luxury, "at start plot", x, y, "in Region#", region_number);
		-- Determine number to place at the start location
		local iNumToPlace = 1;
		if self.resource_setting == 4 then -- Legendary Start
			iNumToPlace = 2;
		end
		if self.regionData[region_number][8] < 2.5 then -- Low fertility per region rectangle plot, add a lux.
			--print("-"); print("Region#", region_number, "has low rectangle fertility, giving it an extra Luxury at start plot.");
			iNumToPlace = iNumToPlace + 1;
			self.luxury_low_fert_compensation[this_region_luxury] = self.luxury_low_fert_compensation[this_region_luxury] + 1;
			self.region_low_fert_compensation[region_number] = self.region_low_fert_compensation[region_number] + 1;
		end
		if self.regionData[region_number][6] / self.regionTerrainCounts[region_number][2] < 4 then -- Low fertility per land plot.
			--print("-"); print("Region#", region_number, "has low per-plot fertility, giving it an extra Luxury at start plot.");
			iNumToPlace = iNumToPlace + 1;
			self.luxury_low_fert_compensation[this_region_luxury] = self.luxury_low_fert_compensation[this_region_luxury] + 1;
			self.region_low_fert_compensation[region_number] = self.region_low_fert_compensation[region_number] + 1;
		end
		-- Obtain plot lists appropriate to this luxury type.
		local primary, secondary, tertiary, quaternary, luxury_plot_lists, shuf_list;
		primary, secondary, tertiary, quaternary = self:GetIndicesForLuxuryType(this_region_luxury);
		luxury_plot_lists = self:GenerateLuxuryPlotListsAtCitySite(x, y, 2, false)

		-- First pass, checking only first two rings with a 50% ratio.
		shuf_list = GetShuffledCopyOfTable(luxury_plot_lists[primary])
		local iNumLeftToPlace = self:PlaceSpecificNumberOfResources(this_region_luxury, 1, iNumToPlace, 0.5, -1, 0, 0, shuf_list);
		if iNumLeftToPlace > 0 and secondary > 0 then
			shuf_list = GetShuffledCopyOfTable(luxury_plot_lists[secondary])
			iNumLeftToPlace = self:PlaceSpecificNumberOfResources(this_region_luxury, 1, iNumLeftToPlace, 0.5, -1, 0, 0, shuf_list);
		end
		if iNumLeftToPlace > 0 and tertiary > 0 then
			shuf_list = GetShuffledCopyOfTable(luxury_plot_lists[tertiary])
			iNumLeftToPlace = self:PlaceSpecificNumberOfResources(this_region_luxury, 1, iNumLeftToPlace, 0.5, -1, 0, 0, shuf_list);
		end
		if iNumLeftToPlace > 0 and quaternary > 0 then
			shuf_list = GetShuffledCopyOfTable(luxury_plot_lists[quaternary])
			iNumLeftToPlace = self:PlaceSpecificNumberOfResources(this_region_luxury, 1, iNumLeftToPlace, 0.5, -1, 0, 0, shuf_list);
		end

		if iNumLeftToPlace > 0 then
			-- Second pass, checking three rings with a 100% ratio.
			luxury_plot_lists = self:GenerateLuxuryPlotListsAtCitySite(x, y, 3, false)
			shuf_list = GetShuffledCopyOfTable(luxury_plot_lists[primary])
			iNumLeftToPlace = self:PlaceSpecificNumberOfResources(this_region_luxury, 1, iNumLeftToPlace, 1, -1, 0, 0, shuf_list);
			if iNumLeftToPlace > 0 and secondary > 0 then
				shuf_list = GetShuffledCopyOfTable(luxury_plot_lists[secondary])
				iNumLeftToPlace = self:PlaceSpecificNumberOfResources(this_region_luxury, 1, iNumLeftToPlace, 1, -1, 0, 0, shuf_list);
			end
			if iNumLeftToPlace > 0 and tertiary > 0 then
				shuf_list = GetShuffledCopyOfTable(luxury_plot_lists[tertiary])
				iNumLeftToPlace = self:PlaceSpecificNumberOfResources(this_region_luxury, 1, iNumLeftToPlace, 1, -1, 0, 0, shuf_list);
			end
			if iNumLeftToPlace > 0 and quaternary > 0 then
				shuf_list = GetShuffledCopyOfTable(luxury_plot_lists[quaternary])
				iNumLeftToPlace = self:PlaceSpecificNumberOfResources(this_region_luxury, 1, iNumLeftToPlace, 1, -1, 0, 0, shuf_list);
			end
		end

		if iNumLeftToPlace > 0 then
			-- If we haven't been able to place all of this lux type at the start, it CAN be placed
			-- in the region somewhere. Subtract remainder from this region's compensation, so that the
			-- regional process, later, will attempt to place this remainder somewhere in the region.
			self.luxury_low_fert_compensation[this_region_luxury] = self.luxury_low_fert_compensation[this_region_luxury] - iNumLeftToPlace;
			self.region_low_fert_compensation[region_number] = self.region_low_fert_compensation[region_number] - iNumLeftToPlace;
		end
		if iNumLeftToPlace > 0 and self.iNumTypesRandom > 0 then
			-- We'll attempt to place one source of a Luxury type assigned to random distribution.
			local randoms_to_place = 1;
			for loop, random_res in ipairs(self.resourceIDs_assigned_to_random) do
		 		primary, secondary, tertiary, quaternary = self:GetIndicesForLuxuryType(random_res);
		 		if randoms_to_place > 0 then
					shuf_list = GetShuffledCopyOfTable(luxury_plot_lists[primary])
					randoms_to_place = self:PlaceSpecificNumberOfResources(random_res, 1, 1, 1, -1, 0, 0, shuf_list);
				end
				if randoms_to_place > 0 and secondary > 0 then
					shuf_list = GetShuffledCopyOfTable(luxury_plot_lists[secondary])
					randoms_to_place = self:PlaceSpecificNumberOfResources(random_res, 1, 1, 1, -1, 0, 0, shuf_list);
				end
				if randoms_to_place > 0 and tertiary > 0 then
					shuf_list = GetShuffledCopyOfTable(luxury_plot_lists[tertiary])
					randoms_to_place = self:PlaceSpecificNumberOfResources(random_res, 1, 1, 1, -1, 0, 0, shuf_list);
				end
				if randoms_to_place > 0 and quaternary > 0 then
					shuf_list = GetShuffledCopyOfTable(luxury_plot_lists[quaternary])
					randoms_to_place = self:PlaceSpecificNumberOfResources(random_res, 1, 1, 1, -1, 0, 0, shuf_list);
				end
			end
		end
	end
	
	-- Place Luxuries at City States.
	-- Candidates include luxuries exclusive to CS, the lux assigned to this CS's region (if in a region), and the randoms.
	for city_state = 1, self.iNumCityStates do
		-- First check to see if this city state number received a valid start plot.
		if self.city_state_validity_table[city_state] == false then
			-- This one did not! It does not exist on the map nor have valid data, so we will ignore it.
		else
			-- OK, it's a valid city state. Process it.
			local region_number = self.city_state_region_assignments[city_state];
			local x = self.cityStatePlots[city_state][1];
			local y = self.cityStatePlots[city_state][2];
			local allowed_luxuries = self:GetListOfAllowableLuxuriesAtCitySite(x, y, 2)
			local lux_possible_for_cs = {}; -- Recorded with ID as key, weighting as data entry
			-- Identify Allowable Luxuries assigned to City States.
			-- If any CS-Only types are eligible, then all combined will have a weighting of 75%
			local cs_only_types = {};
			for loop, res_ID in ipairs(self.resourceIDs_assigned_to_cs) do
				if allowed_luxuries[res_ID] == true then
					table.insert(cs_only_types, res_ID);
				end
			end
			local iNumCSAllowed = table.maxn(cs_only_types);
			if iNumCSAllowed > 0 then
				for loop, res_ID in ipairs(cs_only_types) do
					lux_possible_for_cs[res_ID] = 75 / iNumCSAllowed;
				end
			end
			-- Identify Allowable Random Luxuries and the Regional Luxury if any.
			-- If any random types are eligible (plus the regional type if in a region) these combined carry a 25% weighting.
			if self.iNumTypesRandom > 0 or region_number > 0 then
				local random_types_allowed = {};
				for loop, res_ID in ipairs(self.resourceIDs_assigned_to_random) do
					if allowed_luxuries[res_ID] == true then
						table.insert(random_types_allowed, res_ID);
					end
				end
				local iNumRandAllowed = table.maxn(random_types_allowed);
				local iNumAllowed = iNumRandAllowed;
				if region_number > 0 then
					iNumAllowed = iNumAllowed + 1; -- Adding the region type in to the mix with the random types.
					local res_ID = self.region_luxury_assignment[region_number];
					if allowed_luxuries[res_ID] == true then
						lux_possible_for_cs[res_ID] = 25 / iNumAllowed;
					end
				end
				if iNumRandAllowed > 0 then
					for loop, res_ID in ipairs(random_types_allowed) do
						lux_possible_for_cs[res_ID] = 25 / iNumAllowed;
					end
				end
			end

			-- If there are no allowable luxury types at this city site, then this city state gets none.
			local iNumAvailableTypes = table.maxn(lux_possible_for_cs);
			if iNumAvailableTypes == 0 then
				--print("City State #", city_state, "has poor land, ineligible to receive a Luxury resource.");
			else
				-- Calculate probability thresholds for each allowable luxury type.
				local res_threshold = {};
				local totalWeight, accumulatedWeight = 0, 0;
				for res_ID, this_weight in pairs(lux_possible_for_cs) do
					totalWeight = totalWeight + this_weight;
				end
				for res_ID, this_weight in pairs(lux_possible_for_cs) do
					local threshold = (this_weight + accumulatedWeight) * 10000 / totalWeight;
					res_threshold[res_ID] = threshold;
					accumulatedWeight = accumulatedWeight + this_weight;
				end
				-- Choose luxury type.
				local use_this_ID;
				local diceroll = Map.Rand(10000, "Choose resource type - Assign Luxury To City State - Lua");
				for res_ID, threshold in pairs(res_threshold) do
					if diceroll < threshold then -- Choose this resource type.
						use_this_ID = res_ID;
						break
					end
				end
				--print("-"); print("-"); print("-Assigned Luxury Type", use_this_ID, "to City State#", city_state);
				-- Place luxury.
				local primary, secondary, tertiary, quaternary, luxury_plot_lists, shuf_list;
				primary, secondary, tertiary, quaternary = self:GetIndicesForLuxuryType(use_this_ID);
				luxury_plot_lists = self:GenerateLuxuryPlotListsAtCitySite(x, y, 2, false)
				shuf_list = GetShuffledCopyOfTable(luxury_plot_lists[primary])
				local iNumLeftToPlace = self:PlaceSpecificNumberOfResources(use_this_ID, 1, 1, 1, -1, 0, 0, shuf_list);
				if iNumLeftToPlace > 0 and secondary > 0 then
					shuf_list = GetShuffledCopyOfTable(luxury_plot_lists[secondary])
					iNumLeftToPlace = self:PlaceSpecificNumberOfResources(use_this_ID, 1, 1, 1, -1, 0, 0, shuf_list);
				end
				if iNumLeftToPlace > 0 and tertiary > 0 then
					shuf_list = GetShuffledCopyOfTable(luxury_plot_lists[tertiary])
					iNumLeftToPlace = self:PlaceSpecificNumberOfResources(use_this_ID, 1, 1, 1, -1, 0, 0, shuf_list);
				end
				if iNumLeftToPlace > 0 and quaternary > 0 then
					shuf_list = GetShuffledCopyOfTable(luxury_plot_lists[quaternary])
					iNumLeftToPlace = self:PlaceSpecificNumberOfResources(use_this_ID, 1, 1, 1, -1, 0, 0, shuf_list);
				end
				--if iNumLeftToPlace == 0 then
					--print("-"); print("Placed Luxury ID#", use_this_ID, "at City State#", city_state, "in Region#", region_number, "located at Plot", x, y);
				--end
			end
		end
	end
		
	-- Place Regional Luxuries
	for region_number, res_ID in ipairs(self.region_luxury_assignment) do
		--print("-"); print("- - -"); print("Attempting to place regional luxury #", res_ID, "in Region#", region_number);
		local iNumAlreadyPlaced = self.amounts_of_resources_placed[res_ID + 1];
		local assignment_split = self.luxury_assignment_count[res_ID];
		local primary, secondary, tertiary, quaternary, luxury_plot_lists, shuf_list, iNumLeftToPlace;
		primary, secondary, tertiary, quaternary = self:GetIndicesForLuxuryType(res_ID);
		luxury_plot_lists = self:GenerateLuxuryPlotListsInRegion(region_number)

		-- Calibrate number of luxuries per region to world size and number of civs
		-- present. The amount of lux per region should be at its highest when the 
		-- number of civs in the game is closest to "default" for that map size.
		local target_list = self:GetRegionLuxuryTargetNumbers()
		local targetNum = math.floor((target_list[self.iNumCivs] + (0.5 * self.luxury_low_fert_compensation[res_ID])) / assignment_split);
		targetNum = targetNum - self.region_low_fert_compensation[region_number];
		-- Adjust target number according to Resource Setting.
		if self.resource_setting == 1 then
			targetNum = targetNum - 1;
		elseif self.resource_setting == 3 then
			targetNum = targetNum + 1
		end
		local iNumThisLuxToPlace = math.max(1, targetNum); -- Always place at least one.

		--print("-"); print("Target number for Luxury#", res_ID, "with assignment split of", assignment_split, "is", targetNum);
		
		-- Place luxuries.
		shuf_list = GetShuffledCopyOfTable(luxury_plot_lists[primary])
		iNumLeftToPlace = self:PlaceSpecificNumberOfResources(res_ID, 1, iNumThisLuxToPlace, 0.3, 2, 0, 3, shuf_list);
		if iNumLeftToPlace > 0 and secondary > 0 then
			shuf_list = GetShuffledCopyOfTable(luxury_plot_lists[secondary])
			iNumLeftToPlace = self:PlaceSpecificNumberOfResources(res_ID, 1, iNumLeftToPlace, 0.3, 2, 0, 3, shuf_list);
		end
		if iNumLeftToPlace > 0 and tertiary > 0 then
			shuf_list = GetShuffledCopyOfTable(luxury_plot_lists[tertiary])
			iNumLeftToPlace = self:PlaceSpecificNumberOfResources(res_ID, 1, iNumLeftToPlace, 0.4, 2, 0, 2, shuf_list);
		end
		if iNumLeftToPlace > 0 and quaternary > 0 then
			shuf_list = GetShuffledCopyOfTable(luxury_plot_lists[quaternary])
			iNumLeftToPlace = self:PlaceSpecificNumberOfResources(res_ID, 1, iNumLeftToPlace, 0.5, 2, 0, 2, shuf_list);
		end
		--print("-"); print("-"); print("Number of LuxuryID", res_ID, "left to place in Region#", region_number, "is", iNumLeftToPlace);
	end

	-- Place Random Luxuries
	if self.iNumTypesRandom > 0 then
		--print("* *"); print("* iNumTypesRandom = ", self.iNumTypesRandom); print("* *");
		-- This table governs targets for total number of luxuries placed in the world, not
		-- including the "extra types" of Luxuries placed at start locations. These targets
		-- are approximate. An additional random factor is added in based on number of civs.
		-- Any difference between regional and city state luxuries placed, and the target, is
		-- made up for with the number of randomly placed luxuries that get distributed.
		local world_size_data = self:GetWorldLuxuryTargetNumbers()
		local targetLuxForThisWorldSize = world_size_data[1];
		local loopTarget = world_size_data[2];
		local extraLux = Map.Rand(self.iNumCivs, "Luxury Resource Variance - Place Resources LUA");
		local iNumRandomLuxTarget = targetLuxForThisWorldSize + extraLux - self.totalLuxPlacedSoFar;
		local iNumRandomLuxPlaced, iNumThisLuxToPlace = 0, 0;
		-- This table weights the amount of random luxuries to place, with first-selected getting heavier weighting.
		local random_lux_ratios_table = {
		{1},
		{0.55, 0.45},
		{0.40, 0.33, 0.27},
		{0.35, 0.25, 0.25, 0.15},
		{0.25, 0.25, 0.20, 0.15, 0.15},
		{0.20, 0.20, 0.20, 0.15, 0.15, 0.10},
		{0.20, 0.20, 0.15, 0.15, 0.10, 0.10, 0.10},
		{0.20, 0.15, 0.15, 0.10, 0.10, 0.10, 0.10, 0.10} };

		for loop, res_ID in ipairs(self.resourceIDs_assigned_to_random) do
			local primary, secondary, tertiary, quaternary, luxury_plot_lists, current_list, iNumLeftToPlace;
			primary, secondary, tertiary, quaternary = self:GetIndicesForLuxuryType(res_ID);
			if self.iNumTypesRandom > 8 then
				iNumThisLuxToPlace = math.max(3, math.ceil(iNumRandomLuxTarget / 10));
			else
				local lux_minimum = math.max(3, loopTarget - loop);
				local lux_share_of_remaining = math.ceil(iNumRandomLuxTarget * random_lux_ratios_table[self.iNumTypesRandom][loop]);
				iNumThisLuxToPlace = math.max(lux_minimum, lux_share_of_remaining);
			end
			-- Place this luxury type.
			current_list = self.global_luxury_plot_lists[primary];
			iNumLeftToPlace = self:PlaceSpecificNumberOfResources(res_ID, 1, iNumThisLuxToPlace, 0.25, 2, 4, 6, current_list);
			if iNumLeftToPlace > 0 and secondary > 0 then
				current_list = self.global_luxury_plot_lists[secondary];
				iNumLeftToPlace = self:PlaceSpecificNumberOfResources(res_ID, 1, iNumLeftToPlace, 0.25, 2, 4, 6, current_list);
			end
			if iNumLeftToPlace > 0 and tertiary > 0 then
				current_list = self.global_luxury_plot_lists[tertiary];
				iNumLeftToPlace = self:PlaceSpecificNumberOfResources(res_ID, 1, iNumLeftToPlace, 0.25, 2, 4, 6, current_list);
			end
			if iNumLeftToPlace > 0 and quaternary > 0 then
				current_list = self.global_luxury_plot_lists[quaternary];
				iNumLeftToPlace = self:PlaceSpecificNumberOfResources(res_ID, 1, iNumLeftToPlace, 0.3, 2, 4, 6, current_list);
			end
			iNumRandomLuxPlaced = iNumRandomLuxPlaced + iNumThisLuxToPlace - iNumLeftToPlace;
			--print("-"); print("Random Luxury Target Number:", iNumThisLuxToPlace);
			--print("Random Luxury Target Placed:", iNumThisLuxToPlace - iNumLeftToPlace); print("-");
		end

		--[[
		print("-"); print("+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+");
		print("+ Random Luxuries Target Number:", iNumRandomLuxTarget);
		print("+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+");
		print("+ Random Luxuries Number Placed:", iNumRandomLuxPlaced);
		print("+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+"); print("-");
		]]--

	end

	-- For Resource settings other than Sparse, add a second luxury type at start locations.
	-- This second type will be selected from Random types if possible, CS types if necessary, and other regions' types as a final fallback.
	-- Marble is included in the types possible to be placed.
	if self.resource_setting ~= 1 then
		-- ********************************************
		for region_number = 1, 12 do -- CUSTOM, hardcode's the scenario script to 12 civs. ****************
		-- ********************************************
			local x = self.startingPlots[region_number][1];
			local y = self.startingPlots[region_number][2];
			local use_this_ID;
			local candidate_types, iNumTypesAllowed = {}, 0;
			local allowed_luxuries = self:GetListOfAllowableLuxuriesAtCitySite(x, y, 2)
			--print("-"); print("--- Eligible Types List for Second Luxury in Region#", region_number, "---");
			-- See if any Random types are eligible.
			for loop, res_ID in ipairs(self.resourceIDs_assigned_to_random) do
				if allowed_luxuries[res_ID] == true then
					--print("- Found eligible luxury type:", res_ID);
					iNumTypesAllowed = iNumTypesAllowed + 1;
					table.insert(candidate_types, res_ID);
				end
			end
			-- Check to see if any Special Case luxuries are eligible. Disallow if Strategic Balance resource setting.
			if self.resource_setting ~= 5 then
				for loop, res_ID in ipairs(self.resourceIDs_assigned_to_special_case) do
					if allowed_luxuries[res_ID] == true then
						--print("- Found eligible luxury type:", res_ID);
						iNumTypesAllowed = iNumTypesAllowed + 1;
						table.insert(candidate_types, res_ID);
					end
				end
			end
		
			if iNumTypesAllowed > 0 then
				local diceroll = 1 + Map.Rand(iNumTypesAllowed, "Choosing second luxury type at a start location - LUA");
				use_this_ID = candidate_types[diceroll];
			else
				-- See if any City State types are eligible.
				for loop, res_ID in ipairs(self.resourceIDs_assigned_to_cs) do
					if allowed_luxuries[res_ID] == true then
						--print("- Found eligible luxury type:", res_ID);
						iNumTypesAllowed = iNumTypesAllowed + 1;
						table.insert(candidate_types, res_ID);
					end
				end
				if iNumTypesAllowed > 0 then
					local diceroll = 1 + Map.Rand(iNumTypesAllowed, "Choosing second luxury type at a start location - LUA");
					use_this_ID = candidate_types[diceroll];
				else
					-- See if anybody else's regional type is eligible.
					local region_lux_ID = self.region_luxury_assignment[region_number];
					for loop, res_ID in ipairs(self.resourceIDs_assigned_to_regions) do
						if res_ID ~= region_lux_ID then
							if allowed_luxuries[res_ID] == true then
								--print("- Found eligible luxury type:", res_ID);
								iNumTypesAllowed = iNumTypesAllowed + 1;
								table.insert(candidate_types, res_ID);
							end
						end
					end
					if iNumTypesAllowed > 0 then
						local diceroll = 1 + Map.Rand(iNumTypesAllowed, "Choosing second luxury type at a start location - LUA");
						use_this_ID = candidate_types[diceroll];
					--else
						--print("-"); print("Failed to place second Luxury type at start in Region#", region_number, "-- no eligible types!"); print("-");
					end
				end
			end
			--print("--- End of Eligible Types list for Second Luxury in Region#", region_number, "---");
			if use_this_ID ~= nil then -- Place this luxury type at this start.
				local primary, secondary, tertiary, quaternary, luxury_plot_lists, shuf_list;
				primary, secondary, tertiary, quaternary = self:GetIndicesForLuxuryType(use_this_ID);
				luxury_plot_lists = self:GenerateLuxuryPlotListsAtCitySite(x, y, 2, false)
				shuf_list = GetShuffledCopyOfTable(luxury_plot_lists[primary])
				local iNumLeftToPlace = self:PlaceSpecificNumberOfResources(use_this_ID, 1, 1, 1, -1, 0, 0, shuf_list);
				if iNumLeftToPlace > 0 and secondary > 0 then
					shuf_list = GetShuffledCopyOfTable(luxury_plot_lists[secondary])
					iNumLeftToPlace = self:PlaceSpecificNumberOfResources(use_this_ID, 1, 1, 1, -1, 0, 0, shuf_list);
				end
				if iNumLeftToPlace > 0 and tertiary > 0 then
					shuf_list = GetShuffledCopyOfTable(luxury_plot_lists[tertiary])
					iNumLeftToPlace = self:PlaceSpecificNumberOfResources(use_this_ID, 1, 1, 1, -1, 0, 0, shuf_list);
				end
				if iNumLeftToPlace > 0 and quaternary > 0 then
					shuf_list = GetShuffledCopyOfTable(luxury_plot_lists[quaternary])
					iNumLeftToPlace = self:PlaceSpecificNumberOfResources(use_this_ID, 1, 1, 1, -1, 0, 0, shuf_list);
				end
				if iNumLeftToPlace == 0 then
					--print("-"); print("Placed Second Luxury type of ID#", use_this_ID, "for start located at Plot", x, y, " in Region#", region_number);
				end
			end
		end
	end

	-- Handle Special Case Luxuries
	if self.iNumTypesSpecialCase > 0 then
		-- Add a special case function for each luxury to be handled as a special case.
		self:PlaceMarble()
	end

end
------------------------------------------------------------------------------
function AssignStartingPlots:PlaceSexyBonusAtCivStarts()
	-- This function will place a Bonus resource in the third ring around a Civ's start.
	-- The added Bonus is meant to make the start look more sexy, so to speak.
	-- Third-ring resources will take a long time to bring online, but will assist the site in the late game.
	-- Alternatively, it may assist a different city if another city is settled close enough to the capital and takes control of this tile.
	local iW, iH = Map.GetGridSize();
	local wrapX = Map:IsWrapX();
	local wrapY = Map:IsWrapY();
	local odd = self.firstRingYIsOdd;
	local even = self.firstRingYIsEven;
	local nextX, nextY, plot_adjustments;
	
	local bonus_type_associated_with_region_type = {self.deer_ID, self.banana_ID, 
	self.deer_ID, self.wheat_ID, self.sheep_ID, self.wheat_ID, self.cow_ID, self.cow_ID};
	
	-- ********************************************
	for region_number = 1, 12 do -- CUSTOM, hardcode's the scenario script to 12 civs. ****************
	-- ********************************************
		local x = self.startingPlots[region_number][1];
		local y = self.startingPlots[region_number][2];
		local region_type = self.regionTypes[region_number];
		local use_this_ID = bonus_type_associated_with_region_type[region_type];
		local plot_list, fish_list = {}, {};
		-- For notes on how the hex-iteration works, refer to PlaceResourceImpact()
		local ripple_radius = 3;
		local currentX = x - ripple_radius;
		local currentY = y;
		for direction_index = 1, 6 do
			for plot_to_handle = 1, ripple_radius do
			 	if currentY / 2 > math.floor(currentY / 2) then
					plot_adjustments = odd[direction_index];
				else
					plot_adjustments = even[direction_index];
				end
				nextX = currentX + plot_adjustments[1];
				nextY = currentY + plot_adjustments[2];
				if wrapX == false and (nextX < 0 or nextX >= iW) then
					-- X is out of bounds.
				elseif wrapY == false and (nextY < 0 or nextY >= iH) then
					-- Y is out of bounds.
				else
					local realX = nextX;
					local realY = nextY;
					if wrapX then
						realX = realX % iW;
					end
					if wrapY then
						realY = realY % iH;
					end
					-- We've arrived at the correct x and y for the current plot.
					local plot = Map.GetPlot(realX, realY);
					local featureType = plot:GetFeatureType()
					if plot:GetResourceType(-1) == -1 and featureType ~= FeatureTypes.FEATURE_OASIS then -- No resource or Oasis here, safe to proceed.
						local plotType = plot:GetPlotType()
						local terrainType = plot:GetTerrainType()
						local plotIndex = realY * iW + realX + 1;
						-- Now check this plot for eligibility for the applicable Bonus type for this region.
						if use_this_ID == self.deer_ID then
							if featureType == FeatureTypes.FEATURE_FOREST then
								table.insert(plot_list, plotIndex);
							elseif terrainType == TerrainTypes.TERRAIN_TUNDRA and plotType == PlotTypes.PLOT_LAND then
								table.insert(plot_list, plotIndex);
							end
						elseif use_this_ID == self.banana_ID then
							if featureType == FeatureTypes.FEATURE_JUNGLE then
								table.insert(plot_list, plotIndex);
							end
						elseif use_this_ID == self.wheat_ID then
							if plotType == PlotTypes.PLOT_LAND then
								if terrainType == TerrainTypes.TERRAIN_PLAINS and featureType == FeatureTypes.NO_FEATURE then
									table.insert(plot_list, plotIndex);
								elseif featureType == FeatureTypes.FEATURE_FLOOD_PLAINS then
									table.insert(plot_list, plotIndex);
								elseif terrainType == TerrainTypes.TERRAIN_DESERT and plot:IsFreshWater() then
									table.insert(plot_list, plotIndex);
								end
							end
						elseif use_this_ID == self.sheep_ID then
							if plotType == PlotTypes.PLOT_HILLS and featureType == FeatureTypes.NO_FEATURE then
								if terrainType == TerrainTypes.TERRAIN_PLAINS or terrainType == TerrainTypes.TERRAIN_GRASS or terrainType == TerrainTypes.TERRAIN_TUNDRA then
									table.insert(plot_list, plotIndex);
								end
							end
						elseif use_this_ID == self.cow_ID then
							if terrainType == TerrainTypes.TERRAIN_GRASS and plotType == PlotTypes.PLOT_LAND then
								if featureType == FeatureTypes.NO_FEATURE then
									table.insert(plot_list, plotIndex);
								end
							end
						end
						if plotType == PlotTypes.PLOT_OCEAN then
							if not plot:IsLake() then
								if featureType ~= self.feature_atoll and featureType ~= FeatureTypes.FEATURE_ICE then
									if terrainType == TerrainTypes.TERRAIN_COAST then
										table.insert(fish_list, plotIndex);
									end
								end
							end
						end
					end
				end
				currentX, currentY = nextX, nextY;
			end
		end
		local iNumCandidates = table.maxn(plot_list);
		if iNumCandidates > 0 then
			--print("Placing 'sexy Bonus' in third ring of start location in Region#", region_number);
			local shuf_list = GetShuffledCopyOfTable(plot_list)
			local iNumLeftToPlace = self:PlaceSpecificNumberOfResources(use_this_ID, 1, 1, 1, -1, 0, 0, shuf_list);
			if iNumCandidates > 1 and use_this_ID == self.sheep_ID then
				-- Hills region, attempt to give them a second Sexy Sheep.
				--print("Placing a second 'sexy Sheep' in third ring of start location in Hills Region#", region_number);
				iNumLeftToPlace = self:PlaceSpecificNumberOfResources(use_this_ID, 1, 1, 1, -1, 0, 0, shuf_list);
			end
		else
			local iFishCandidates = table.maxn(fish_list);
			if iFishCandidates > 0 then
				--print("Placing 'sexy Fish' in third ring of start location in Region#", region_number);
				local shuf_list = GetShuffledCopyOfTable(fish_list)
				local iNumLeftToPlace = self:PlaceSpecificNumberOfResources(self.fish_ID, 1, 1, 1, -1, 0, 0, shuf_list);
			end
		end
	end
end
------------------------------------------------------------------------------
function AssignStartingPlots:AddExtraBonusesToHillsRegions()
	-- Do nothing.
end
------------------------------------------------------------------------------
function StartPlotSystem()
	print("Creating start plot database.");
	local start_plot_database = AssignStartingPlots.Create()
	
	print("Dividing the map in to Regions.");
	start_plot_database:GenerateRegions()

	print("Choosing start locations for civilizations.");
	start_plot_database:ChooseLocations()
	
	print("Normalizing start locations and assigning them to Players.");
	start_plot_database:BalanceAndAssign()

	print("Placing Natural Wonders.");
	start_plot_database:PlaceNaturalWonders()

	print("Placing Resources and City States.");
	start_plot_database:PlaceResourcesAndCityStates()
end
------------------------------------------------------------------------------
