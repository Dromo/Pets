
-- Initialise tables
_PETS = {};
_STRINGS = {};
_FAMILY = {};
_UPDATES = {};
_PETSTRINGS = {};
SETTINGS = {}; 		-- Table used when loading settings.
V_SETTINGS = 1;		-- Table version number, used when saving/loading each table to check against updates.
_BARPETS = {};

SCREENWIDTH = Turbine.UI.Display.GetWidth();
SCREENHEIGHT = Turbine.UI.Display.GetHeight();

PLAYERCHAR = Turbine.Gameplay.LocalPlayer.GetInstance();
PLAYERCLASS = PLAYERCHAR:GetClass();

PADDING = 1;	-- padding for quickslot bar
QSSIZE = 36;

LANGID = 1;

_COLORS =
{
	[1] = Turbine.UI.Color.Ivory;
	[2] = Turbine.UI.Color.Khaki;
	[3] = Turbine.UI.Color.Red;
	[4] = Turbine.UI.Color.Lime;
	[5] = Turbine.UI.Color(0.8,0.8,0.8);
	[6] = Turbine.UI.Color.Gold;			-- Root node label colour
	[7] = Turbine.UI.Color.DarkOliveGreen;	-- Root node back colour
	[8] = Turbine.UI.Color(0.1,0.1,0.1); 	-- Root node label outline color
};

_FONTS =
{
	[1] = Turbine.UI.Lotro.Font.Verdana10;
	[2] = Turbine.UI.Lotro.Font.Verdana12;
	[3] = Turbine.UI.Lotro.Font.Verdana14;
	[4] = Turbine.UI.Lotro.Font.TrajanPro14;
	[5] = Turbine.UI.Lotro.Font.TrajanPro18;
};

_QUALITYCOLORS =
{
	[0] = Turbine.UI.Color.White;			-- Undefined
	[5] = Turbine.UI.Color.White;			-- Common
	[4] = Turbine.UI.Color.Yellow;			-- Uncommon
	[2] = Turbine.UI.Color.Magenta;			-- Rare
	[3] = Turbine.UI.Color.Aqua;			-- Incomparable
	[1] = Turbine.UI.Color.Orange;			-- Legendary
};


-- Default Settings
DEFAULT_SETTINGS =
	{
	["ENABLENEWPETS"] = true;
	["MAXROWSLOTS"] = 12;

	["MAINWIN"] =
		{
		["X"] = 60;
		["Y"] = 60;
		["VISIBLE"] = false;
		};

	["ICON"] =
		{
		["X"] = 20;
		["Y"] = 20;
		["VISIBLE"] = true;
		};
	};

