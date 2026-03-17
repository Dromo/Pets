----------------------------------------------------------------
-- Known (trained) pet skills of the player (by skill name)
-- Used to decide which pets the player already owns.
----------------------------------------------------------------
local KNOWN_PET_SKILLS = nil

-- Cached normalized name/description strings for text search
local _PET_SEARCHKEYS = nil

-- Key code for the Enter key in LotRO (used in SearchTextEnter)
local KEY_ENTER = 162

----------------------------------------------------------------
-- Name normalization for comparisons and search
----------------------------------------------------------------
local function NormalizeName(name)
    if not name or name == "" then
        return ""
    end

    -- NBSP variants -> space
    name = string.gsub(name, "\194\160", " ")
    name = string.gsub(name, string.char(160), " ")

    if StripAccent then
        name = StripAccent(name)
    end

    name = string.upper(name)
    name = string.gsub(name, "%s+", " ")
    name = string.gsub(name, "^%s+", "")
    name = string.gsub(name, "%s+$", "")

    return name
end

----------------------------------------------------------------
-- Build map of all trained pet skills (by normalized name)
----------------------------------------------------------------
local function BuildKnownPetSkillMap()
    KNOWN_PET_SKILLS = {}

    local player = Turbine.Gameplay.LocalPlayer.GetInstance()
    if not player then
        return
    end

    local skills = player:GetTrainedSkills()
    if not skills then
        return
    end

    local count = skills:GetCount()
    for i = 1, count do
        local skill = skills:GetItem(i)
        if skill ~= nil then
            local info = skill:GetSkillInfo()
            if info ~= nil then
                local name = info:GetName()
                if name ~= nil then
                    local key = NormalizeName(name)
                    if key ~= "" then
                        KNOWN_PET_SKILLS[key] = true
                    end
                end
            end
        end
    end
end

----------------------------------------------------------------
-- Check if a pet is owned based on its display name
-- (global so DesktopIcon.lua can use it if needed)
----------------------------------------------------------------
function IsPetOwned(petID)
    if KNOWN_PET_SKILLS == nil then
        BuildKnownPetSkillMap()
    end

    local petData = _PETS[petID]
    if not petData then
        return false
    end

    if not _PETSTRINGS[petID] or not _PETSTRINGS[petID][1] then
        return false
    end

    local petName = _PETSTRINGS[petID][1]
    local key = NormalizeName(petName)

    if key == "" then
        return false
    end

    return KNOWN_PET_SKILLS[key] == true
end

----------------------------------------------------------------
-- Helper: reset reloader plugin state so it can be used again
----------------------------------------------------------------
local function ResetPetsReloader()
    if Turbine.PluginManager and Turbine.PluginManager.UnloadScriptState then
        pcall(function()
            Turbine.PluginManager.UnloadScriptState("Pets Reloader")
        end)
    end
end

----------------------------------------------------------------
-- MIGRATION:
-- Remove old SETTINGS.GROWUP and map to the new BARORIENTATION
-- BARORIENTATION:
--   1 = Down -> Right
--   2 = Down -> Left
--   3 = Up -> Right
--   4 = Up -> Left
----------------------------------------------------------------
local function MigrateOldSettings()
    if SETTINGS.BARORIENTATION == nil then
        SETTINGS.BARORIENTATION = 1
    end

    if SETTINGS.GROWUP ~= nil then
        if SETTINGS.GROWUP == true then
            SETTINGS.BARORIENTATION = 3   -- Up -> Right
        else
            SETTINGS.BARORIENTATION = 1   -- Down -> Right
        end

        SETTINGS.GROWUP = nil

        if saveData ~= nil then
            pcall(function()
                saveData()
            end)
        end
    end
end

----------------------------------------------------------------
-- Main window
----------------------------------------------------------------
function DrawMainWin()

    -- Run migration for legacy settings
    MigrateOldSettings()

    if SETTINGS.ONLYKNOWN == nil then
        SETTINGS.ONLYKNOWN = false
    end

    -- Ensure MAXROWSLOTS has a sane default
    if SETTINGS.MAXROWSLOTS == nil then
        if DEFAULT_SETTINGS and DEFAULT_SETTINGS["MAXROWSLOTS"] then
            SETTINGS.MAXROWSLOTS = DEFAULT_SETTINGS["MAXROWSLOTS"]
        else
            SETTINGS.MAXROWSLOTS = 12
        end
    end

    if SETTINGS.MAXROWSLOTS < 5 then SETTINGS.MAXROWSLOTS = 5 end
    if SETTINGS.MAXROWSLOTS > 30 then SETTINGS.MAXROWSLOTS = 30 end

    -- Ensure BARORIENTATION is within 1..8
    if SETTINGS.BARORIENTATION == nil
       or SETTINGS.BARORIENTATION < 1
       or SETTINGS.BARORIENTATION > 8 then
        SETTINGS.BARORIENTATION = 1
    end

    -- Make sure the reloader can be loaded again
    ResetPetsReloader()

    wMainWin = Turbine.UI.Lotro.Window()
    wMainWin:SetSize(640, 820)
    wMainWin:SetPosition(SETTINGS.MAINWIN.X, SETTINGS.MAINWIN.Y)
    wMainWin:SetText(PLUGINNAME)
    wMainWin:SetHideF12(true)
    wMainWin:SetCloseEsc(true)
    wMainWin:SetVisible(SETTINGS.MAINWIN.VISIBLE)

    Utils.Onscreen(wMainWin)

    ----------------------------------------------------------------
    -- Layout anchors for list area and lower controls
    ----------------------------------------------------------------
    local renameTop  = wMainWin:GetHeight() - 120   -- first config row
    local listBottom = renameTop - 10               -- bottom of list area

    ----------------------------------------------------------------
    -- Search / filter area
    ----------------------------------------------------------------
    NewWindowLabel(wMainWin, 200, 18, 50, 40, GetString(6))
    txtSearch = NewWindowTextBox(wMainWin, 200, 20, 50, 60)

    NewWindowLabel(wMainWin, 200, 18, 260, 40, GetString(5))
    ddFamily = Utils.DropDown(_FAMILY)
    ddFamily:SetParent(wMainWin)
    ddFamily:SetPosition(260, 60)

    lblUpdate = NewWindowLabel(wMainWin, 80, 18, 170, 90, GetString(15))
    lblUpdate:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleRight)

    _UPDATETABLE = {}
    _UPDATETABLE[1] = GetString(14)   -- "All"
    _UPDATETABLE[2] = GetString(17)   -- "All available"

    local updateCount = 3
    for i = #_UPDATES, 1, -1 do
        _UPDATETABLE[updateCount] = _UPDATES[i][1]
        updateCount = updateCount + 1
    end

    ddUpdate = Utils.DropDown(_UPDATETABLE)
    ddUpdate:SetParent(wMainWin)
    ddUpdate:SetPosition(260, 90)

    btnSearch = NewWindowButton(wMainWin, 80, 430, 60, GetString(6))

    ----------------------------------------------------------------
    -- Result list (TreeView)
    ----------------------------------------------------------------
    lblResults = NewWindowLabel(wMainWin, 200, 18, 30, 115)

    imgListBack = Turbine.UI.Control()
    imgListBack:SetParent(wMainWin)
    imgListBack:SetPosition(24, 136)
    imgListBack:SetSize(wMainWin:GetWidth() - 29, listBottom - 136)
    imgListBack:SetBlendMode(4)

    trvPets = Turbine.UI.TreeView()
    trvPets:SetParent(wMainWin)
    trvPets:SetPosition(30, 140)

    local trvHeight = listBottom - trvPets:GetTop()
    if trvHeight < 100 then trvHeight = 100 end

    trvPets:SetSize(wMainWin:GetWidth() - 70, trvHeight)
    trvPets:SetIndentationWidth(0)

    sbtrvPets = NewScrollBar(trvPets, "vertical", wMainWin)

    ----------------------------------------------------------------
    -- Rename row (row 1: rename + alias button + only-known)
    ----------------------------------------------------------------
    txtRename = NewWindowTextBox(wMainWin, 130, 20, 30, renameTop)
    txtRename:SetToolTip(GetString(10))

    qsRename = NewQuickslot(
        wMainWin,
        82, 18,
        txtRename:GetLeft() + txtRename:GetWidth() + 10,
        txtRename:GetTop(),
        Turbine.UI.Lotro.ShortcutType.Alias,
        GetString(8)
    )
    qsRename:SetZOrder(1)

    btnRename = Turbine.UI.Control()
    btnRename:SetParent(wMainWin)
    btnRename:SetSize(82, 18)
    btnRename:SetPosition(qsRename:GetPosition())
    btnRename:SetMouseVisible(false)
    btnRename:SetBackground(_IMAGES[2])
    btnRename:SetZOrder(50)

    lblRename = NewButtonLabel(btnRename, GetString(7))
    lblRename:SetMouseVisible(false)

    chkKnownPets = Turbine.UI.Lotro.CheckBox()
    chkKnownPets:SetParent(wMainWin)
    chkKnownPets:SetSize(260, 20)

    local chkKnownLeft = qsRename:GetLeft() + qsRename:GetWidth() + 40
    chkKnownPets:SetPosition(chkKnownLeft, renameTop - 1)
    chkKnownPets:SetFont(Turbine.UI.Lotro.Font.Verdana14)
    chkKnownPets:SetForeColor(Turbine.UI.Color.Khaki)
    chkKnownPets:SetText(" " .. GetString(16))
    chkKnownPets:SetChecked(SETTINGS.ONLYKNOWN == true)

    ----------------------------------------------------------------
    -- Row 2: Quickslot bar visibility + slots-per-row (slider block)
    ----------------------------------------------------------------
    local row2Top = renameTop + 26

    chkQSBar = Turbine.UI.Lotro.CheckBox()
    chkQSBar:SetParent(wMainWin)
    chkQSBar:SetSize(260, 20)
    chkQSBar:SetPosition(30, row2Top)
    chkQSBar:SetFont(Turbine.UI.Lotro.Font.Verdana14)
    chkQSBar:SetForeColor(Turbine.UI.Color.Khaki)
    chkQSBar:SetText(" " .. GetString(9))
    chkQSBar:SetChecked(SETTINGS.ICON.VISIBLE)

    local lblMaxRows = NewWindowLabel(
        wMainWin,
        200, 18,
        340,
        row2Top,
        GetString(18)          -- localized "Slots per row"
    )

    local sliderMaxRows = Turbine.UI.Lotro.ScrollBar()
    sliderMaxRows:SetParent(wMainWin)
    sliderMaxRows:SetOrientation(Turbine.UI.Orientation.Horizontal)

    local sliderLeft  = 340
    local sliderWidth = 180

    sliderMaxRows:SetSize(sliderWidth, 10)
    sliderMaxRows:SetPosition(sliderLeft, row2Top + 20)
    sliderMaxRows:SetMinimum(5)
    sliderMaxRows:SetMaximum(30)

    local currentSlots = SETTINGS.MAXROWSLOTS
    if currentSlots < 5 then currentSlots = 5 end
    if currentSlots > 30 then currentSlots = 30 end
    sliderMaxRows:SetValue(currentSlots)

    local lblMaxRowsValue = NewWindowLabel(
        wMainWin,
        30, 18,
        sliderLeft + sliderWidth + 5,
        row2Top + 16,
        tostring(currentSlots)
    )

    sliderMaxRows.ValueChanged = function(sender, args)
        local v = sliderMaxRows:GetValue()
        v = math.floor(v + 0.5)
        if v < 5 then v = 5 end
        if v > 30 then v = 30 end

        currentSlots = v
        lblMaxRowsValue:SetText(tostring(v))
    end

    ----------------------------------------------------------------
    -- Row 3: Quickslot bar orientation (dropdown)
    ----------------------------------------------------------------
    local row3Top = row2Top + 40

    local lblOrientation = NewWindowLabel(
        wMainWin,
        200, 18,
        30,
        row3Top,
        GetString(23)  -- "Quickslot bar orientation"
    )

    -- Ensure BARORIENTATION is valid (1..8)
    if SETTINGS.BARORIENTATION == nil
       or SETTINGS.BARORIENTATION < 1
       or SETTINGS.BARORIENTATION > 8 then
        SETTINGS.BARORIENTATION = 1
    end

        local orientationLabels = {
        GetString(19), -- 1
        GetString(20), -- 2
        GetString(21), -- 3
        GetString(22), -- 4
        GetString(29), -- 5
        GetString(30), -- 6
        GetString(31), -- 7
        GetString(32)  -- 8
    }

    -- aktuelle Einstellung als Default-Text
    local currentIndex = SETTINGS.BARORIENTATION
    if currentIndex == nil or currentIndex < 1 or currentIndex > 8 then
        currentIndex = 1
    end

    -- Feste Reihenfolge, aber vorausgewählt über defaultLabel
    ddOrientation = Utils.DropDown(orientationLabels, orientationLabels[currentIndex])
    ddOrientation:SetParent(wMainWin)
    ddOrientation:SetPosition(260, row3Top)

    ----------------------------------------------------------------
    -- Row 4: Quickslot fill mode (action drop-down)
    ----------------------------------------------------------------
    local row4Top = row3Top + 26

    local lblFillMode = NewWindowLabel(
        wMainWin,
        200, 18,
        30,
        row4Top,
        GetString(24)  -- "Quickslots füllen mit:"
    )

    local fillOptions = {
        GetString(25), -- "Keine Änderung"
        GetString(26), -- "Allen bekannten Begleitern"
        GetString(27), -- "Allen Begleitern"
        GetString(28)  -- "Keinen Begleitern"
    }

    ddFillSlots = Utils.DropDown(fillOptions)
    ddFillSlots:SetParent(wMainWin)
    ddFillSlots:SetPosition(260, row4Top)
    -- Standard: erster Eintrag = "Keine Änderung"
    if ddFillSlots.SetWidth ~= nil then
        ddFillSlots:SetWidth(220)  -- oder 240, wenn du mehr Platz willst
    end

    ----------------------------------------------------------------
    -- Single OK button for both slots-per-row, orientation, and fill-mode
    ----------------------------------------------------------------
    local btnSettingsOK = NewWindowButton(
        wMainWin,
        60,
        wMainWin:GetWidth() - 90,   -- right aligned
        row4Top - 2,                -- same row as orientation
        "OK"
    )

    local function ApplyMaxRowsAndReload()
        -- 1) Save slots per row
        SETTINGS.MAXROWSLOTS = currentSlots

        -- 2) Save bar orientation from dropdown (by text)
        if ddOrientation ~= nil and ddOrientation.GetText ~= nil then
            local txt = ddOrientation:GetText()

            if txt == GetString(19) then
                SETTINGS.BARORIENTATION = 1  -- Down -> Right
            elseif txt == GetString(20) then
                SETTINGS.BARORIENTATION = 2  -- Down -> Left
            elseif txt == GetString(21) then
                SETTINGS.BARORIENTATION = 3  -- Up -> Right
            elseif txt == GetString(22) then
                SETTINGS.BARORIENTATION = 4  -- Up -> Left
            elseif txt == GetString(29) then
                SETTINGS.BARORIENTATION = 5  -- Up -> Left (vertical first)
            elseif txt == GetString(30) then
                SETTINGS.BARORIENTATION = 6  -- Up -> Right (vertical first)
            elseif txt == GetString(31) then
                SETTINGS.BARORIENTATION = 7  -- Down -> Left (vertical first)
            elseif txt == GetString(32) then
                SETTINGS.BARORIENTATION = 8  -- Down -> Right (vertical first)
            end
        end

        -- 3) Apply quickslot fill mode (optional action)
        if type(_BARPETS) ~= "table" then
            _BARPETS = {}
        end

        if ddFillSlots ~= nil and ddFillSlots.GetText ~= nil then
            local txt = ddFillSlots:GetText()

            -- determine mode:
            -- 0 = no change
            -- 1 = all known pets
            -- 2 = all pets
            -- 3 = no pets
            local mode = 0

            if txt == GetString(25) then           -- "Keine Änderung"
                mode = 0
            elseif txt == GetString(26) then       -- "Allen bekannten Begleitern"
                mode = 1
            elseif txt == GetString(27) then       -- "Allen Begleitern"
                mode = 2
            elseif txt == GetString(28) then       -- "Keinen Begleitern"
                mode = 3
            end

            if mode ~= 0 then
                -- clear current bar config
                for k in pairs(_BARPETS) do
                    _BARPETS[k] = nil
                end

                if mode == 1 or mode == 2 then
                    -- need futureMin to skip "future" pets
                    local lastUpdateIndex = #_UPDATES
                    local futureMin = _UPDATES[lastUpdateIndex][2]

                    for id, petData in pairs(_PETS) do
                        if id < futureMin then
                            if mode == 2 then
                                -- all pets
                                _BARPETS[id] = 1
                            else
                                -- known pets only
                                if IsPetOwned(id) then
                                    _BARPETS[id] = 1
                                end
                            end
                        end
                    end
                else
                    -- mode == 3: no pets -> just keep _BARPETS cleared
                end
            end
        end

        -- 4) Persist settings
        if saveData ~= nil then
            pcall(function()
                saveData()
            end)
        end

        -- 5) Redraw bar
        LayoutBar()

    end

    AddCallback(btnSettingsOK, "Click", ApplyMaxRowsAndReload)

    ----------------------------------------------------------------
    -- Control events (search, rename, checkboxes)
    ----------------------------------------------------------------
    --SearchTextEnter = function(sender, args)
    --    if args.Action == KEY_ENTER then
    --        PerformSearch()
    --    end
    --end

    RenameChangedEvent = function()
        qsRename:SetShortcut(
            Turbine.UI.Lotro.Shortcut(
                Turbine.UI.Lotro.ShortcutType.Alias,
                GetString(8) .. " " .. txtRename:GetText()
            )
        )
    end

    RenameClickEvent = function(sender, args)
        txtRename:SetText("")
    end

    ShowBarChanged = function()
        SETTINGS.ICON.VISIBLE = chkQSBar:IsChecked()
        wIcon:SetVisible(SETTINGS.ICON.VISIBLE)
        wQSBarOverlay:SetVisible(SETTINGS.ICON.VISIBLE)
    end

    KnownFilterChanged = function()
        local newState = chkKnownPets:IsChecked()
        SETTINGS.ONLYKNOWN = newState

        if newState == true then
            KNOWN_PET_SKILLS = nil
            BuildKnownPetSkillMap()
        end

        PerformSearch()
    end

    AddCallback(txtRename,    "TextChanged",    RenameChangedEvent)
    AddCallback(qsRename,     "MouseUp",        RenameClickEvent)
    AddCallback(btnSearch,    "Click",          PerformSearch)
    AddCallback(txtSearch,    "KeyDown",        SearchTextEnter)
    AddCallback(chkQSBar,     "CheckedChanged", ShowBarChanged)
    AddCallback(chkKnownPets, "CheckedChanged", KnownFilterChanged)

    ----------------------------------------------------------------
    -- Window events (position + visibility persistence)
    ----------------------------------------------------------------
    wMainWin.PositionChanged = function()
        SETTINGS.MAINWIN.X = wMainWin:GetLeft()
        SETTINGS.MAINWIN.Y = wMainWin:GetTop()
    end

    wMainWin.VisibleChanged = function()
        SETTINGS.MAINWIN.VISIBLE = wMainWin:IsVisible()
    end

    ----------------------------------------------------------------
    -- Initial search
    ----------------------------------------------------------------
    PerformSearch()
end

----------------------------------------------------------------
-- Search / filter logic
----------------------------------------------------------------
function PerformSearch()

    btnSearch:Focus()

    local _searchResults = {}
    local _searchStrings = TabulateSearchQuery(txtSearch:GetText())
    local familyIndex = ddFamily:GetSelectedIndex()
    local updateIndex = 0
    local updateMin = 1
    local updateMax = 1
    local onlyOwned = (SETTINGS.ONLYKNOWN == true)

    local updateText = ddUpdate:GetText()
    local totalUpdates = #_UPDATES

    if updateText == GetString(17) then
        updateMin = _UPDATES[1][2]
        updateMax = _UPDATES[totalUpdates - 1][3]
        updateIndex = -1
    elseif updateText ~= GetString(15) then
        for k, v in ipairs(_UPDATES) do
            if v[1] == updateText then
                updateIndex = k
                updateMin = v[2]
                updateMax = v[3]
                break
            end
        end
    end

    local lastUpdateIndex = totalUpdates
    local futureMin = _UPDATES[lastUpdateIndex][2]

    if _PET_SEARCHKEYS == nil then
        _PET_SEARCHKEYS = {}
        for id, _ in pairs(_PETS) do
            local name = ""
            local desc = ""

            if _PETSTRINGS[id] ~= nil then
                name = _PETSTRINGS[id][1] or ""
                desc = _PETSTRINGS[id][2] or ""
            end

            _PET_SEARCHKEYS[id] = {
                name = NormalizeName(name),
                desc = NormalizeName(desc)
            }
        end
    end

    for k, v in pairs(_PETS) do
        local doesMatch = true

        if updateIndex == -1 and k >= futureMin then
            doesMatch = false
        end

        if doesMatch and onlyOwned and not IsPetOwned(k) then
            doesMatch = false
        end

        if doesMatch and updateIndex >= 0 and updateIndex ~= 0 then
            if not (k >= updateMin and k <= updateMax) then
                doesMatch = false
            end
        end

        if doesMatch and v[4] ~= nil and v[4] ~= PLAYERCLASS then
            doesMatch = false
        end

        if doesMatch and familyIndex ~= 1 and v[3] ~= familyIndex then
            doesMatch = false
        end

        if doesMatch and _searchStrings ~= nil then
            local keys = _PET_SEARCHKEYS[k]
            local petName = keys and keys.name or ""
            local petDesc = keys and keys.desc or ""
            local nameMatch = true

            for _, wordVal in pairs(_searchStrings) do
                if string.find(petName, wordVal) == nil and string.find(petDesc, wordVal) == nil then
                    nameMatch = false
                    break
                end
            end

            doesMatch = nameMatch
        end

        if doesMatch then
            table.insert(_searchResults, k)
        end
    end

    DisplayResults(_searchResults)
end

----------------------------------------------------------------
-- Result rendering (TreeView population)
----------------------------------------------------------------
function DisplayResults(searchResults)
    if type(searchResults) ~= "table" then
        return
    end

    local root = trvPets:GetNodes()
    root:Clear()

    local _families = {}
    local maxID = 0

    lblResults:SetText(GetString(12) .. " " .. #searchResults)

    for _, v in ipairs(searchResults) do
        local familyID = _PETS[v][3]

        if _families[familyID] == nil then
            _families[familyID] = {}
        end

        if familyID > maxID then
            maxID = familyID
        end

        table.insert(_families[familyID], v)
    end

    local lastUpdateIndex = #_UPDATES
    local futureMin = _UPDATES[lastUpdateIndex][2]

    for i = 1, maxID do
        if _families[i] ~= nil then
            local rootNode = GetFamilyNode(i)
            root:Add(rootNode)
            local petNodes = rootNode:GetChildNodes()

            local petNames = {}

            for _, v in ipairs(_families[i]) do
                local s = _PETSTRINGS[v]
                if s ~= nil and s[1] ~= nil then
                    table.insert(
                        petNames,
                        { ["id"] = v, ["name"] = s[1] }
                    )
                end
            end

            table.sort(
                petNames,
                function(v1, v2)
                    return v1.name < v2.name
                end
            )

            for _, v in ipairs(petNames) do
                local isFuture = (v.id >= futureMin)
                local disabledFlag = isFuture and 0 or 1
                petNodes:Add(GetPetNode(v.id, isFuture), disabledFlag)
            end

            rootNode:Expand()
        end
    end
end

----------------------------------------------------------------
-- TreeView node: pet family header
----------------------------------------------------------------
function GetFamilyNode(familyID)

    local rootNode = Turbine.UI.TreeNode()
    rootNode:SetSize(trvPets:GetWidth(), 33)

    local itemContainer = Turbine.UI.Control()
    itemContainer:SetParent(rootNode)
    itemContainer:SetSize(rootNode:GetWidth(), 30)
    itemContainer:SetPosition(0, 3)
    itemContainer:SetBackColor(_COLORS[7])

    lblFamily = NewWindowLabel(itemContainer, 300, 30, 3, 2)
    lblFamily:SetFont(_FONTS[5])
    lblFamily:SetForeColor(_COLORS[6])
    lblFamily:SetOutlineColor(_COLORS[8])
    lblFamily:SetFontStyle(Turbine.UI.FontStyle.Outline)
    lblFamily:SetText(_FAMILY[familyID])

    return rootNode
end

----------------------------------------------------------------
-- TreeView node: single pet entry
----------------------------------------------------------------
function GetPetNode(petID, isFuture)

    local petNode = Turbine.UI.TreeNode()
    petNode:SetSize(trvPets:GetWidth(), 40)

    local qsPet = NewQuickslot(
        petNode,
        QSSIZE, QSSIZE,
        10,
        (petNode:GetHeight() - QSSIZE) / 2,
        Turbine.UI.Lotro.ShortcutType.Skill,
        "0x" .. Utils.TO_HEX(_PETS[petID][1])
    )

    qsPet.MouseClick = function()
        petNode:SetExpanded(not petNode:IsExpanded())
    end

    local petName = (_PETSTRINGS[petID] and _PETSTRINGS[petID][1]) or ("Pet #" .. tostring(petID))

    local lblPetName = NewWindowLabel(petNode, 350, 36, 50, 2)
    lblPetName:SetFont(_FONTS[4])
    lblPetName:SetForeColor(_COLORS[1])
    lblPetName:SetText(petName)

    local chkPetEnable = Turbine.UI.Lotro.CheckBox()
    chkPetEnable:SetParent(petNode)
    chkPetEnable:SetSize(20, 20)
    chkPetEnable:SetPosition(petNode:GetWidth() - 25, 10)
    chkPetEnable:SetText("")
    chkPetEnable:SetToolTip(GetString(11))

    if isFuture then
        chkPetEnable:SetEnabled(false)
        chkPetEnable:SetVisible(false)
    end

    if _BARPETS[petID] ~= nil then
        chkPetEnable:SetChecked(true)
    end

    chkPetEnable.CheckedChanged = function()
        petNode:SetExpanded(not petNode:IsExpanded())

        if chkPetEnable:IsChecked() then
            _BARPETS[petID] = 1
            AddShortcut(petID)
        else
            _BARPETS[petID] = nil
            RemoveShortcut(petID)
        end
    end

    local nodeList = petNode:GetChildNodes()
    nodeList:Add(GetSubNode(petID))

    return petNode
end

----------------------------------------------------------------
-- TreeView sub-node: description + item info
----------------------------------------------------------------
function GetSubNode(petID)

    local subNode = Turbine.UI.TreeNode()
    subNode:SetSize(trvPets:GetWidth(), 105)

    local descText = (_PETSTRINGS[petID] and _PETSTRINGS[petID][2]) or ""

    local lblDesc = Turbine.UI.TextBox()
    lblDesc:SetParent(subNode)
    lblDesc:SetPosition(50, 0)
    lblDesc:SetSize(trvPets:GetWidth() - lblDesc:GetLeft() - 10, 0)
    lblDesc:SetForeColor(_COLORS[2])
    lblDesc:SetFont(_FONTS[3])
    lblDesc:SetMultiline(true)
    lblDesc:SetText(descText)

    Utils.AutoHeight(lblDesc)

    local itemInspect = NewItemInfo(_PETS[petID][2])
    itemInspect:SetParent(subNode)
    itemInspect:SetPosition(50, lblDesc:GetHeight() + 5)

    local itemInfo = itemInspect:GetItemInfo()

    local lblItemName = NewWindowLabel(subNode, 400, 36, 90, itemInspect:GetTop())
    lblItemName:SetWidth(trvPets:GetWidth() - lblItemName:GetLeft() - 10)

    if itemInfo ~= nil then
        lblItemName:SetForeColor(_QUALITYCOLORS[itemInfo:GetQuality()])
        lblItemName:SetText(itemInfo:GetName())
    else
        lblItemName:SetText("")
    end

    subNode:SetHeight(lblItemName:GetTop() + lblItemName:GetHeight() + 10)

    return subNode
end
