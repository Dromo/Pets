
function DrawShortcutBar()

	wQSBarOverlay = Turbine.UI.Window();
	wQSBarOverlay:SetSize(SCREENWIDTH,SCREENHEIGHT);
	wQSBarOverlay:SetPosition(0,0);
	wQSBarOverlay:SetVisible(false);

	-- SETTINGS.MAXROWSLOTS
	lstShortcuts = Turbine.UI.ListBox();
	lstShortcuts:SetParent(wQSBarOverlay);
	--lstShortcuts:SetBackColor(Turbine.UI.Color(0.4,0.2,0.2,0.2));
	lstShortcuts:SetPosition(wIcon:GetLeft()+wIcon:GetWidth(),wIcon:GetTop());
	lstShortcuts:SetHeight(0);
	lstShortcuts:SetOrientation(Turbine.UI.Orientation.Horizontal);
	HandleBarWidth();

	LoadSavedPets();

	-- WINDOW EVENTS --
	local function OverlayClickEvent()
		wQSBarOverlay:SetVisible(false);
	end

	AddCallback(wQSBarOverlay,"MouseClick",OverlayClickEvent);

end


function HandleBarMove(left,top)
	lstShortcuts:SetPosition(left,top);
end


function LoadSavedPets()
	if type(_BARPETS) ~= 'table' then return end;

	for k,v in pairs(_BARPETS) do
		AddShortcut(k);
	end

end


function HandleBarWidth()
	lstShortcuts:SetWidth((QSSIZE*SETTINGS.MAXROWSLOTS)+(PADDING*(SETTINGS.MAXROWSLOTS+1)));
	lstShortcuts:SetMaxItemsPerLine(SETTINGS.MAXROWSLOTS);
end


function HandleBarHeight()
	local rows = math.ceil(lstShortcuts:GetItemCount()/SETTINGS.MAXROWSLOTS);
	if rows == 0 then
		lstShortcuts:SetHeight(0);
	else
		lstShortcuts:SetHeight((QSSIZE*rows)+(PADDING*(rows)));
	end
end


function AddShortcut(petID)

	local petName = _PETSTRINGS[petID][1];
	local petFamily = _PETS[petID][3];

	local itemContainer = Turbine.UI.Control();
	itemContainer:SetSize(QSSIZE+PADDING,QSSIZE+PADDING);
	itemContainer:SetBackColor(Turbine.UI.Color(0.4,0.2,0.2,0.2));
	itemContainer["petID"] = petID;
	itemContainer["petName"] = petName;
	itemContainer["petFamily"] = petFamily;

	local qsPet = NewQuickslot(itemContainer,QSSIZE,QSSIZE,PADDING,0,Turbine.UI.Lotro.ShortcutType.Skill,"0x"..Utils.TO_HEX(_PETS[petID][1]));
	qsPet.MouseClick = function ()
		wQSBarOverlay:SetVisible(false);
	end

	local listCount = lstShortcuts:GetItemCount();
	-- Add to list at sorted index
	if listCount == 0 then
		lstShortcuts:AddItem(itemContainer);
	else
		local isAdded = false;
		for i=1, listCount do
			local item = lstShortcuts:GetItem(i);
			if item.petFamily == petFamily then
				if item.petName > petName then
					lstShortcuts:InsertItem(i,itemContainer);
					isAdded = true;
					break;
				end
			elseif item.petFamily > petFamily then
				lstShortcuts:InsertItem(i,itemContainer);
				isAdded = true;
				break;
			end
		end
		if isAdded == false then lstShortcuts:AddItem(itemContainer) end;
	end

	HandleBarHeight();
end


function RemoveShortcut(petID)

	for i=1, lstShortcuts:GetItemCount() do
		local item = lstShortcuts:GetItem(i);

		if item.petID == petID then
			lstShortcuts:RemoveItemAt(i);
			break;
		end
	end

	HandleBarHeight();
end
