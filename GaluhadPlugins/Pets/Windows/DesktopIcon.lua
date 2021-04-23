
function DrawDesktopIcon()

	wIcon = Turbine.UI.Window();
	wIcon:SetSize(QSSIZE,QSSIZE);
	wIcon:SetPosition(SETTINGS.ICON.X,SETTINGS.ICON.Y);
	wIcon:SetBackground(_IMAGES[1]);
	wIcon:SetBlendMode(0);
	wIcon:SetToolTip(PLUGINNAME);
	wIcon:SetVisible(SETTINGS.ICON.VISIBLE);
	wIcon:SetHideF12(true);
	wIcon:SetCloseEsc(false);
	wIcon:SetWantsKeyEvents(true);

	Utils.Onscreen(wIcon);

	DrawShortcutBar();

	-- WINDOW KEY EVENTS -----------------------------------------------------------------------------------------------------
	wIcon.KeyDown = function (sender,args)
		if args.Action == 268435635 then	-- F12
			HandleF12Event();
		elseif args.Action == 145 then		-- ESC
			HandleEscEvent();
		end
	end


	-- WINDOW MOUSE EVENTS ---------------------------------------------------------------------------------------------------
	wIcon.MouseDown = function (sender, args)
		blDragging = true;
		relX = args.X;
		relY = args.Y;
	end

	wIcon.MouseUp = function (sender, args)
		blDragging = false;
	end

	wIcon.MouseMove = function (sender, args)
		if blDragging == true then
			local scX = Turbine.UI.Display.GetMouseX();
			local scY = Turbine.UI.Display.GetMouseY();
			SETTINGS.ICON.X = scX - relX;
			SETTINGS.ICON.Y = scY - relY;

			if SETTINGS.ICON.X < 0 then SETTINGS.ICON.X = 0 end
			if SETTINGS.ICON.X > (SCREENWIDTH-lstShortcuts:GetWidth()-wIcon:GetWidth()) then SETTINGS.ICON.X = (SCREENWIDTH-lstShortcuts:GetWidth()-wIcon:GetWidth()) end
			if SETTINGS.ICON.Y < 0 then SETTINGS.ICON.Y = 0 end
			if SETTINGS.ICON.Y > (SCREENHEIGHT-lstShortcuts:GetHeight()) then SETTINGS.ICON.Y = (SCREENHEIGHT-lstShortcuts:GetHeight()) end

			wIcon:SetPosition(SETTINGS.ICON.X,SETTINGS.ICON.Y);
			HandleBarMove(SETTINGS.ICON.X+wIcon:GetWidth(),SETTINGS.ICON.Y);
		end
	end

	wIcon.MouseDoubleClick = function (sender, args)
		if (args.Button == Turbine.UI.MouseButton.Left) then
			wMainWin:SetVisible(true);
			wMainWin:Activate();
		end
	end

	wIcon.MouseClick = function (sender,args)
		wQSBarOverlay:SetVisible(not wQSBarOverlay:IsVisible());
	end
end
