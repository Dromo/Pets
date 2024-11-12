
function DrawMainWin()

	wMainWin = Turbine.UI.Lotro.Window();
	wMainWin:SetSize(560,750);
	wMainWin:SetPosition(SETTINGS.MAINWIN.X,SETTINGS.MAINWIN.Y);
	wMainWin:SetText(PLUGINNAME);
	wMainWin:SetHideF12(true);
	wMainWin:SetCloseEsc(true);
	wMainWin:SetVisible(SETTINGS.MAINWIN.VISIBLE);

	Utils.Onscreen(wMainWin);

	NewWindowLabel(wMainWin,200,18,50,40,GetString(6));
	txtSearch = NewWindowTextBox(wMainWin,200,20,50,60);

	NewWindowLabel(wMainWin,200,18,260,40,GetString(5));
	ddFamily = Utils.DropDown(_FAMILY);
	ddFamily:SetParent(wMainWin);
	ddFamily:SetPosition(260,60);

	lblUpdate = NewWindowLabel(wMainWin,80,18,170,90,GetString(15));
	lblUpdate:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleRight);

	_UPDATETABLE = {};
	_UPDATETABLE[1] = GetString(14);

	local updateCount = 2;
	for i=table.getn(_UPDATES), 1, -1 do
		_UPDATETABLE[updateCount] = _UPDATES[i][1];
		updateCount = updateCount + 1;
	end

	ddUpdate = Utils.DropDown(_UPDATETABLE);
	ddUpdate:SetParent(wMainWin);
	ddUpdate:SetPosition(260,90);

	btnSearch = NewWindowButton(wMainWin,80,430,60,GetString(6));

	lblResults = NewWindowLabel(wMainWin,200,18,30,115);

	imgListBack = Turbine.UI.Control();
	imgListBack:SetParent(wMainWin);
	imgListBack:SetPosition(24,136);
	imgListBack:SetSize(511,wMainWin:GetHeight()-170);
	imgListBack:SetBlendMode(4);

	trvPets = Turbine.UI.TreeView();
    trvPets:SetParent(wMainWin);
    trvPets:SetPosition(30,140);
    trvPets:SetSize(wMainWin:GetWidth()-70,wMainWin:GetHeight()-trvPets:GetTop()-70);
    --trvPets:SetBackColor(Turbine.UI.Color(0.1,0.1,0.1));
    trvPets:SetIndentationWidth(0);
	sbtrvPets = NewScrollBar(trvPets,"vertical",wMainWin);

	txtRename = NewWindowTextBox(wMainWin,130,20,30,wMainWin:GetHeight()-50);
	txtRename:SetToolTip(GetString(10));
	qsRename = NewQuickslot(wMainWin,77,18,txtRename:GetLeft()+txtRename:GetWidth()+10,txtRename:GetTop(),Turbine.UI.Lotro.ShortcutType.Alias,GetString(8));
	qsRename:SetZOrder(1);

	btnRename = Turbine.UI.Control();
	btnRename:SetParent(wMainWin);
	btnRename:SetSize(77,18);
	btnRename:SetPosition(qsRename:GetPosition());
	btnRename:SetMouseVisible(false);
	btnRename:SetBackground(_IMAGES[2]);
	btnRename:SetZOrder(50);

	lblRename = NewButtonLabel(btnRename,GetString(7));
	lblRename:SetMouseVisible(false);


	chkQSBar = Turbine.UI.Lotro.CheckBox();
	chkQSBar:SetParent(wMainWin);
	chkQSBar:SetSize(170,20);
	chkQSBar:SetPosition(qsRename:GetLeft()+qsRename:GetWidth()+50,qsRename:GetTop());
	chkQSBar:SetFont(Turbine.UI.Lotro.Font.Verdana14);
	chkQSBar:SetForeColor(Turbine.UI.Color.Khaki);
	chkQSBar:SetText(" "..GetString(9));
	chkQSBar:SetChecked(SETTINGS.ICON.VISIBLE);


	-- Control Events
	SearchTextEnter = function(sender,args)
		if args.Action == 162 then PerformSearch() end;
	end

	RenameChangedEvent = function()
		qsRename:SetShortcut(Turbine.UI.Lotro.Shortcut(Turbine.UI.Lotro.ShortcutType.Alias,GetString(8).." "..txtRename:GetText()));
		--print(txtRename:GetText());
	end

	RenameClickEvent = function(sender,args)
		txtRename:SetText("");
	end

	ShowBarChanged = function ()
		SETTINGS.ICON.VISIBLE = chkQSBar:IsChecked();
		wIcon:SetVisible(SETTINGS.ICON.VISIBLE);
		wQSBarOverlay:SetVisible(SETTINGS.ICON.VISIBLE);
	end

	AddCallback(txtRename,"TextChanged",RenameChangedEvent);
	AddCallback(qsRename,"MouseUp",RenameClickEvent);
	AddCallback(btnSearch,"Click",PerformSearch);
	AddCallback(txtSearch,"KeyDown",SearchTextEnter);
	AddCallback(chkQSBar,"CheckedChanged",ShowBarChanged);

	-- Window events
	wMainWin.PositionChanged = function()
		SETTINGS.MAINWIN.X = wMainWin:GetLeft();
		SETTINGS.MAINWIN.Y = wMainWin:GetTop();
	end

	wMainWin.VisibleChanged = function()
		SETTINGS.MAINWIN.VISIBLE = wMainWin:IsVisible();
	end

	-- Function calls
	PerformSearch();

end


function PerformSearch()

	btnSearch:Focus();

	local _searchResults = {};
	local _searchStrings = TabulateSearchQuery(txtSearch:GetText());
	local familyIndex = ddFamily:GetSelectedIndex();
	local updateIndex = 0;
	local updateMin = 1;
	local updateMax = 1;

	-- Check for which update and the min/max IDs to search
	local updateText = ddUpdate:GetText();
	if updateText ~= GetString(15) then -- "All"
		for k,v in pairs (_UPDATES) do
			if v[1] == updateText then
				updateIndex = k;
				updateMin = v[2];
				updateMax = v[3];
				break;
			end
		end
	end


	for k,v in pairs (_PETS) do

		-- Check if between IDs first!
		if updateIndex == 0 or (k >= updateMin and k <= updateMax) then

			local doesMatch = true;

			if v[4] ~= nil and v[4] ~= PLAYERCLASS then doesMatch = false end; -- Filters out class-specific pets.

			if familyIndex ~= 1 and v[3] ~= familyIndex then doesMatch = false end;

			if doesMatch == true and _searchStrings ~= nil then
				local petName = string.upper(StripAccent(_PETSTRINGS[k][1]));
				local petDesc = string.upper (StripAccent(_PETSTRINGS[k][2]));
				local nameMatch = true;

				for wordKey,wordVal in pairs(_searchStrings) do
					if string.find(petName,wordVal) == nil and string.find(petDesc,wordVal) == nil then
						nameMatch = false;
						break;
					end
				end
				doesMatch = nameMatch;
			end

			if doesMatch == true then
				table.insert(_searchResults,k);
			end
		end

	end

	DisplayResults(_searchResults);

end


function DisplayResults(searchResults)
	if type(searchResults) ~= 'table' then return end;

	local root = trvPets:GetNodes();
	root:Clear();

	local _families = {};
	local maxID = 0;

	lblResults:SetText(GetString(12).." "..#searchResults);

	-- group by family
	for k,v in ipairs (searchResults) do
		if _families[_PETS[v][3]] == nil then _families[_PETS[v][3]] = {} end;
		if _PETS[v][3] > maxID then maxID = _PETS[v][3] end;
		table.insert(_families[_PETS[v][3]],v);
	end

	-- add each family as a parent in the treeview, with the pets belonging to it as children
	for i=1,maxID do
		if _families[i] ~= nil then
			local rootNode = GetFamilyNode(i);
			root:Add(rootNode);
			local petNodes = rootNode:GetChildNodes();
			-- Add pet nodes

			local petNames = {};

			for k,v in pairs(_families[i]) do
				table.insert(petNames,{["id"]=v;["name"]=_PETSTRINGS[v][1];});
			end
            
			table.sort	(petNames,
							function (v1, v2)
								return v1.name < v2.name;
							end
						);

			for k,v in pairs (petNames) do
                disabled = 1
                if _UPDATES[table.maxn(_UPDATES)][2] <= v.id then
                    disabled = 0
                end
				petNodes:Add(GetPetNode(v.id),disabled);
			end
			rootNode:Expand();
		end
	end

end


function GetFamilyNode(familyID)

	local rootNode = Turbine.UI.TreeNode();
	rootNode:SetSize(trvPets:GetWidth(),33);

	local itemContainer = Turbine.UI.Control();
	itemContainer:SetParent(rootNode);
	itemContainer:SetSize(rootNode:GetWidth(),30);
	itemContainer:SetPosition(0,3);
	itemContainer:SetBackColor(_COLORS[7]);

	lblFamily = NewWindowLabel(itemContainer,300,30,3,2);
	lblFamily:SetFont(_FONTS[5]);
	lblFamily:SetForeColor(_COLORS[6]);
	lblFamily:SetOutlineColor(_COLORS[8]);
	lblFamily:SetFontStyle( Turbine.UI.FontStyle.Outline );
	lblFamily:SetText(_FAMILY[familyID]);


	return rootNode;

end


function GetPetNode(petID, enabled)

	local petNode = Turbine.UI.TreeNode();
	petNode:SetSize(trvPets:GetWidth(),40);

	local qsPet = NewQuickslot(petNode,QSSIZE,QSSIZE,10,(petNode:GetHeight()-QSSIZE)/2,Turbine.UI.Lotro.ShortcutType.Skill,"0x"..Utils.TO_HEX(_PETS[petID][1]));

	qsPet.MouseClick = function ()
		petNode:SetExpanded(not petNode:IsExpanded());
	end

	local lblPetName = NewWindowLabel(petNode,350,36,50,2);
	lblPetName:SetFont(_FONTS[4]);
	lblPetName:SetForeColor(_COLORS[1]);
	lblPetName:SetText(_PETSTRINGS[petID][1]);
	--lblPetName:SetBackColor(_COLORS[3]);

	local chkPetEnable = Turbine.UI.Lotro.CheckBox();
	chkPetEnable:SetParent(petNode);
	chkPetEnable:SetSize(20,20);
	chkPetEnable:SetPosition(petNode:GetWidth()-25,10);
	chkPetEnable:SetText("");
	chkPetEnable:SetToolTip(GetString(11));
    if disabled == 0 then
        chkPetEnable:SetEnabled(false)
        chkPetEnable:SetVisible(false)
	end
    if _BARPETS[petID] ~= nil then chkPetEnable:SetChecked(true) end;

	chkPetEnable.CheckedChanged = function ()
		petNode:SetExpanded(not petNode:IsExpanded());

		if chkPetEnable:IsChecked() then
			_BARPETS[petID] = 1;
			-- Add to bar
			AddShortcut(petID);
		else
			_BARPETS[petID] = nil;
			-- Remove from bar
			RemoveShortcut(petID);
		end
	end

	local nodeList = petNode:GetChildNodes();
	nodeList:Add(GetSubNode(petID));


	return petNode;

end


function GetSubNode(petID)

	local subNode = Turbine.UI.TreeNode();
	subNode:SetSize(trvPets:GetWidth(),105);

	local lblDesc = Turbine.UI.TextBox();
	lblDesc:SetParent(subNode);
	lblDesc:SetPosition(50,0);
	lblDesc:SetSize(trvPets:GetWidth()-lblDesc:GetLeft()-10,0);
	lblDesc:SetForeColor(_COLORS[2]);
	lblDesc:SetFont(_FONTS[3]);
	lblDesc:SetMultiline(true);
	lblDesc:SetText(_PETSTRINGS[petID][2]);

	Utils.AutoHeight(lblDesc);

	local itemInspect = NewItemInfo(_PETS[petID][2]);
	itemInspect:SetParent(subNode);
	itemInspect:SetPosition(50,lblDesc:GetHeight()+5);

	local itemInfo = itemInspect:GetItemInfo();

	local lblItemName = NewWindowLabel(subNode,400,36,90,itemInspect:GetTop());
	lblItemName:SetWidth(trvPets:GetWidth()-lblItemName:GetLeft()-10);

	if itemInfo ~= nil then
		lblItemName:SetForeColor(_QUALITYCOLORS[itemInfo:GetQuality()]);
		lblItemName:SetText(itemInfo:GetName());
	end

	subNode:SetHeight(lblItemName:GetTop()+lblItemName:GetHeight()+10);

	return subNode;

end
