----------------------------------------------------------------------------------------------------
-- Quickslot Bar
-- Uses SETTINGS.BARORIENTATION:
--   1 = Right → Down
--   2 = Left → Down
--   3 = Right → Up
--   4 = Left → Up
--   5 = Up → Left  (vertical first, then new columns to the left)
--   6 = Up → Right (vertical first, then new columns to the right)
--   7 = Down → Left  (vertical first, then new columns to the left)
--   8 = Down → Right (vertical first, then new columns to the right)
----------------------------------------------------------------------------------------------------

wQSBarOverlay = nil
barContainer  = nil
barItems      = {}   -- sorted list of all bar item controls

-- last known icon position (used for anchoring the bar)
local lastIconX = SETTINGS.ICON and SETTINGS.ICON.X or 0
local lastIconY = SETTINGS.ICON and SETTINGS.ICON.Y or 0

----------------------------------------------------------------------------------------------------
-- Helper: ensure BARORIENTATION has a sane default
----------------------------------------------------------------------------------------------------
local function EnsureBarOrientation()
    if SETTINGS.BARORIENTATION == nil then
        SETTINGS.BARORIENTATION = 1 -- Down → Right
    end
end

----------------------------------------------------------------------------------------------------
-- LayoutBar
-- Positions and arranges all items in barContainer based on:
--   - SETTINGS.BARORIENTATION (1..8)
--   - SETTINGS.MAXROWSLOTS
--       * for 1..4: max slots per row (horizontal first)
--       * for 5..8: max slots per column (vertical first)
--   - lastIconX / lastIconY (icon position)
----------------------------------------------------------------------------------------------------
function LayoutBar()
    if not barContainer then
        return
    end

    EnsureBarOrientation()

    local count = #barItems
    if count == 0 then
        barContainer:SetSize(0, 0)
        return
    end

    local maxSlots = SETTINGS.MAXROWSLOTS or 12
    if maxSlots < 1 then maxSlots = 1 end

    local cellW = QSSIZE + PADDING
    local cellH = QSSIZE + PADDING

    local orientation = SETTINGS.BARORIENTATION
    local iconWidth   = wIcon and wIcon:GetWidth()  or QSSIZE
    local iconHeight  = wIcon and wIcon:GetHeight() or QSSIZE

    -- For 1..4: horizontal-first (existing behavior)
    -- For 5..8: vertical-first (stack icons; when MAX reached, start a new vertical column left/right)
    local verticalFirst = (orientation >= 5 and orientation <= 8)

    local rows, cols, barWidth, barHeight

    if not verticalFirst then
        cols = maxSlots
        rows = math.ceil(count / cols)
        barWidth  = cols * cellW
        barHeight = rows * cellH
    else
        rows = maxSlots
        cols = math.ceil(count / rows)
        barWidth  = cols * cellW
        barHeight = rows * cellH
    end

    barContainer:SetSize(barWidth, barHeight)

    -- Anchor bar relative to icon position
    local containerX, containerY

    if orientation == 1 then
        -- Right -> Down: bar to the right, top aligned with icon
        containerX = lastIconX + iconWidth
        containerY = lastIconY
    elseif orientation == 2 then
        -- Left -> Down: bar to the left, top aligned with icon
        containerX = lastIconX - barWidth
        containerY = lastIconY
    elseif orientation == 3 then
        -- Right -> Up: bar to the right, bottom aligned with icon
        containerX = lastIconX + iconWidth
        containerY = lastIconY + iconHeight - barHeight
    elseif orientation == 4 then
        -- Left -> Up: bar to the left, bottom aligned with icon
        containerX = lastIconX - barWidth
        containerY = lastIconY + iconHeight - barHeight
    elseif orientation == 5 then
        -- Up -> Left (vertical first): bar ABOVE icon, grow columns to the LEFT
        containerX = lastIconX + iconWidth - barWidth
        containerY = lastIconY - barHeight
    elseif orientation == 6 then
        -- Up -> Right (vertical first): bar ABOVE icon, grow columns to the RIGHT
        containerX = lastIconX
        containerY = lastIconY - barHeight
    elseif orientation == 7 then
        -- Down -> Left (vertical first): bar BELOW icon, grow columns to the LEFT
        containerX = lastIconX + iconWidth - barWidth
        containerY = lastIconY + iconHeight
    elseif orientation == 8 then
        -- Down -> Right (vertical first): bar BELOW icon, grow columns to the RIGHT
        containerX = lastIconX
        containerY = lastIconY + iconHeight
    else
        -- fallback
        containerX = lastIconX + iconWidth
        containerY = lastIconY
    end

    barContainer:SetPosition(containerX, containerY)

    -- Place all items inside the bar container
    for index, ctrl in ipairs(barItems) do
        local zeroBased = index - 1
        local rowIndex, colIndex

        if not verticalFirst then
            -- existing: fill left->right, then next row
            rowIndex = math.floor(zeroBased / cols)   -- 0..rows-1 (top to bottom)
            colIndex = zeroBased % cols               -- 0..cols-1 (left to right)

            -- horizontal mirroring for "left" variants
            if orientation == 2 or orientation == 4 then
                colIndex = (cols - 1) - colIndex
            end

            -- side -> up variants: first row should be next to icon, additional rows go further up
            if orientation == 3 or orientation == 4 then
                rowIndex = (rows - 1) - rowIndex
            end
        else
            -- new: fill vertically (one column) first, then next column
            colIndex = math.floor(zeroBased / rows)   -- 0..cols-1
            rowIndex = zeroBased % rows               -- 0..rows-1 (top to bottom)

            -- "Up" variants: start near icon (bottom of bar) and grow upward
            if orientation == 5 or orientation == 6 then
                rowIndex = (rows - 1) - rowIndex
            end

            -- "Left" variants: first column should be next to icon, additional columns go further left
            if orientation == 5 or orientation == 7 then
                colIndex = (cols - 1) - colIndex
            end
        end

        local x = colIndex * cellW
        local y = rowIndex * cellH

        ctrl:SetPosition(x, y)
    end
end

----------------------------------------------------------------------------------------------------
-- DrawShortcutBar
-- Creates the overlay and the bar container and loads saved pets
----------------------------------------------------------------------------------------------------
function DrawShortcutBar()

    lastIconX = SETTINGS.ICON and SETTINGS.ICON.X or 0
    lastIconY = SETTINGS.ICON and SETTINGS.ICON.Y or 0

    EnsureBarOrientation()

    wQSBarOverlay = Turbine.UI.Window()
    wQSBarOverlay:SetSize(SCREENWIDTH, SCREENHEIGHT)
    wQSBarOverlay:SetPosition(0, 0)
    wQSBarOverlay:SetVisible(false)
    wQSBarOverlay:SetZOrder(1)

    barContainer = Turbine.UI.Control()
    barContainer:SetParent(wQSBarOverlay)
    barContainer:SetSize(0, 0)
    barContainer:SetPosition(lastIconX, lastIconY)

    barItems = {}

    local function OverlayClickEvent()
        wQSBarOverlay:SetVisible(false)
    end

    AddCallback(wQSBarOverlay, "MouseClick", OverlayClickEvent)

    LoadSavedPets()
end

----------------------------------------------------------------------------------------------------
-- HandleBarMove
-- Called from DesktopIcon when the icon is dragged.
-- Updates the anchor position and re-layouts the bar.
----------------------------------------------------------------------------------------------------
function HandleBarMove(iconX, iconY)
    lastIconX = iconX or lastIconX
    lastIconY = iconY or lastIconY

    LayoutBar()
end

----------------------------------------------------------------------------------------------------
-- GetBarSize
-- Returns current bar width and height (used by DesktopIcon.lua
-- to clamp the icon position so icon+bar stay on-screen).
----------------------------------------------------------------------------------------------------
function GetBarSize()
    if barContainer == nil then
        return 0, 0
    end

    return barContainer:GetWidth(), barContainer:GetHeight()
end

----------------------------------------------------------------------------------------------------
-- LoadSavedPets
-- Adds all pets stored in _BARPETS to the bar.
----------------------------------------------------------------------------------------------------
function LoadSavedPets()
    if type(_BARPETS) ~= "table" then
        return
    end

    for petID, _ in pairs(_BARPETS) do
        AddShortcut(petID)
    end
end

----------------------------------------------------------------------------------------------------
-- AddShortcut
-- Creates a new quickslot for a pet and inserts it into the bar,
-- sorted by pet family, then by pet name (ascending).
-- Visual direction depends only on BARORIENTATION, not on sorting.
----------------------------------------------------------------------------------------------------
function AddShortcut(petID)

    if not _PETS or not _PETSTRINGS or not _PETS[petID] or not _PETSTRINGS[petID] then
        return
    end

    local petName   = _PETSTRINGS[petID][1]
    local petFamily = _PETS[petID][3]

    if not petName or not petFamily then
        return
    end

    local item = Turbine.UI.Control()
    item:SetSize(QSSIZE + PADDING, QSSIZE + PADDING)
    item:SetBackColor(Turbine.UI.Color(0.4, 0.2, 0.2, 0.2))
    item.petID     = petID
    item.petName   = petName
    item.petFamily = petFamily

    local qs = NewQuickslot(
        item,
        QSSIZE,
        QSSIZE,
        0,
        0,
        Turbine.UI.Lotro.ShortcutType.Skill,
        "0x" .. Utils.TO_HEX(_PETS[petID][1])
    )

    qs.MouseClick = function()
        if wQSBarOverlay then
            wQSBarOverlay:SetVisible(false)
        end
    end

    item:SetParent(barContainer)

    -- Insert sorted by family, then by pet name (ascending)
    local insertPos = #barItems + 1
    for i, existing in ipairs(barItems) do
        if existing.petFamily == petFamily then
            if existing.petName > petName then
                insertPos = i
                break
            end
        elseif existing.petFamily > petFamily then
            insertPos = i
            break
        end
    end

    table.insert(barItems, insertPos, item)

    LayoutBar()
end

----------------------------------------------------------------------------------------------------
-- RemoveShortcut
-- Removes the quickslot for the given pet from the bar.
----------------------------------------------------------------------------------------------------
function RemoveShortcut(petID)
    if not barItems or #barItems == 0 then
        return
    end

    for i, item in ipairs(barItems) do
        if item.petID == petID then
            item:SetParent(nil)
            table.remove(barItems, i)
            break
        end
    end

    LayoutBar()
end
