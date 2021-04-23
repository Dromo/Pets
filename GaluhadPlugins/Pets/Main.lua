
PLUGINDIR = "GaluhadPlugins.Pets";
RESOURCEDIR = "GaluhadPlugins/Pets/Resources/";
PLUGINNAME = "Pets";

-- Turbine Imports..
import "Turbine";
import "Turbine.Gameplay";
import "Turbine.UI";
import "Turbine.UI.Lotro";

-- Plugin Imports..
import (PLUGINDIR..".Globals");
import (PLUGINDIR..".Images");
import (PLUGINDIR..".Data");
import (PLUGINDIR..".AddCallBack");
import (PLUGINDIR..".Functions");
import (PLUGINDIR..".Commands");
import (PLUGINDIR..".VindarPatch");
import (PLUGINDIR..".Images");

-- Utils Imports..
import (PLUGINDIR..".Utils");

-- Windows..
import (PLUGINDIR..".Windows");


-----------------------------------------------------------------------------------------------------------

function saveData()
	PatchDataSave(Turbine.DataScope.Character, "Pets_Settings", SETTINGS);
	PatchDataSave(Turbine.DataScope.Character, "Pets_Selected", _BARPETS);
end


function loadData()
	---------------------------------------------------------------------------------------------------------------------------------
	-- SAVED SETTINGS --
	local SavedSettings = {};

	function GetSavedSettings()
		SavedSettings = PatchDataLoad(Turbine.DataScope.Character, "Pets_Settings");
	end

	if pcall(GetSavedSettings) then
		GetSavedSettings();
	else -- Loaded with errors
		SavedSettings = nil;
		printError(GetString(1));
	end

	-- Check the saved settings to make sure it is still compatible with newer updates, add in any missing default settings
	if type(SavedSettings) == 'table' then
		local tempSETTINGS = {};
		tempSETTINGS = Utils.deepcopy(DEFAULT_SETTINGS);
		SETTINGS = Utils.mergeTables(tempSETTINGS,SavedSettings);
	else
		SETTINGS = Utils.deepcopy(DEFAULT_SETTINGS);
	end

	---------------------------------------------------------------------------------------------------------------------------------
	-- SELECTED PETS --
	local SavedPets = {};

	function GetSavedPets()
		SavedPets = PatchDataLoad(Turbine.DataScope.Character, "Pets_Selected");
	end

	if pcall(GetSavedPets) then
		GetSavedPets();
	else -- Loaded with errors
		SavedPets = nil;
		printError(GetString(1));
	end

	-- Check the saved settings to make sure it is still compatible with newer updates, add in any missing default settings
	if type(SavedPets) == 'table' then
		_BARPETS = Utils.deepcopy(SavedPets);
	end

	----------------------------------------------------------------------------------------------------------------------------------
end


function print(MESSAGE)
	if MESSAGE == nil then return end;
	Turbine.Shell.WriteLine("<rgb=#FF6666>" .. tostring(MESSAGE) .. "</rgb>");
end


function printError(STRING)
	if STRING == nil or STRING == "" then return end;
	Turbine.Shell.WriteLine("<rgb=#FF3333>"..PLUGINNAME..": " .. tostring(STRING) .. "\n" .. GetString(2) .. "</rgb>");
end


function LoadStrings()
	LANGID = Utils.GetClientLanguage();
	_STRINGS = {};
	import (PLUGINDIR..".Strings");
end


function LoadSequence()
	LoadStrings();
	loadData();
	--VerifyData();
	--Utils.InitiateChatLogger();
	Windows.DrawWindows();
	RegisterCommands();
	Turbine.Plugin.Unload = function ()
		saveData();
	end
	print("Loaded '" .. PLUGINNAME .. "' by Galuhad [Evernight], patched by Drono");
	print(GetString(13));
end


-- Initiate load sequence
LoadSequence();
