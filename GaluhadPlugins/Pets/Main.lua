----------------------------------------------------------------
-- Pets
-- Main entry point: loads data, windows, commands and patches
----------------------------------------------------------------

PLUGINDIR   = "GaluhadPlugins.Pets"
RESOURCEDIR = "GaluhadPlugins/Pets/Resources/"
PLUGINNAME  = "Pets"

----------------------------------------------------------------
-- Turbine imports
----------------------------------------------------------------
import "Turbine"
import "Turbine.Gameplay"
import "Turbine.UI"
import "Turbine.UI.Lotro"

----------------------------------------------------------------
-- Plugin imports
----------------------------------------------------------------
import (PLUGINDIR .. ".Globals")
import (PLUGINDIR .. ".Images")
import (PLUGINDIR .. ".Data")
import (PLUGINDIR .. ".AddCallBack")
import (PLUGINDIR .. ".Functions")
import (PLUGINDIR .. ".Commands")
import (PLUGINDIR .. ".VindarPatch")
import (PLUGINDIR .. ".Images")

-- Utils
import (PLUGINDIR .. ".Utils")

-- Windows
import (PLUGINDIR .. ".Windows")

----------------------------------------------------------------
-- Data save / load
----------------------------------------------------------------
function saveData()
    PatchDataSave(Turbine.DataScope.Character, "Pets_Settings", SETTINGS)
    PatchDataSave(Turbine.DataScope.Character, "Pets_Selected", _BARPETS)
end

function loadData()
    ----------------------------------------------------------------
    -- Settings
    ----------------------------------------------------------------
    local okSettings, savedSettings = pcall(
        PatchDataLoad,
        Turbine.DataScope.Character,
        "Pets_Settings"
    )

    if not okSettings then
        savedSettings = nil
        printError(GetString(1))
    end

    if type(savedSettings) == "table" then
        -- Start from defaults and merge user settings on top
        local temp = Utils.deepcopy(DEFAULT_SETTINGS)
        SETTINGS = Utils.mergeTables(temp, savedSettings)
    else
        -- Fallback to defaults
        SETTINGS = Utils.deepcopy(DEFAULT_SETTINGS)
    end

    ----------------------------------------------------------------
    -- Selected pets / quickslot layout
    ----------------------------------------------------------------
    local okPets, savedPets = pcall(
        PatchDataLoad,
        Turbine.DataScope.Character,
        "Pets_Selected"
    )

    if not okPets then
        savedPets = nil
        printError(GetString(1))
    end

    if type(savedPets) == "table" then
        _BARPETS = Utils.deepcopy(savedPets)
    end
end

----------------------------------------------------------------
-- Shell output helpers
----------------------------------------------------------------
function print(message)
    if message == nil then
        return
    end
    Turbine.Shell.WriteLine("<rgb=#FF6666>" .. tostring(message) .. "</rgb>")
end

function printError(text)
    if text == nil or text == "" then
        return
    end
    Turbine.Shell.WriteLine("<rgb=#FF3333>" .. PLUGINNAME .. ": " .. tostring(text) .. "\n" .. GetString(2) .. "</rgb>")
end

----------------------------------------------------------------
-- Localization
----------------------------------------------------------------
function LoadStrings()
    LANGID = Utils.GetClientLanguage()
    _STRINGS = {}
    import (PLUGINDIR .. ".Strings")
end

----------------------------------------------------------------
-- Main load sequence
----------------------------------------------------------------
function LoadSequence()
    LoadStrings()
    loadData()
    Windows.DrawWindows()
    RegisterCommands()

    -- Save on plugin unload
    Turbine.Plugin.Unload = function()
        saveData()
    end

    print("Loaded '" .. PLUGINNAME .. "' by Galuhad [Evernight], patched by Drono and DaBear78")
    print(GetString(13))
end

----------------------------------------------------------------
-- Start plugin
----------------------------------------------------------------
LoadSequence()
