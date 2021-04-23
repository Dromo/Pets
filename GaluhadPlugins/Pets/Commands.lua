

function RegisterCommands()

	---------------------------------------------------------------------------------------------

	petsCommand = Turbine.ShellCommand();

	function petsCommand:Execute(command,args)
		if Windows.wMainWin == nil then Windows.DrawMainWin() end;
		Windows.wMainWin:SetVisible(not Windows.wMainWin:IsVisible());
	end

	function petsCommand:GetHelp()
		return GetString(3);
	end

	function petsCommand:GetShortHelp()
		return GetString(3);
	end

	Turbine.Shell.AddCommand( "pets", petsCommand);

end





