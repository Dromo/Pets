
if LANGID == 2 then		-- French
	import (PLUGINDIR..".Strings.French");
elseif LANGID == 3 then		-- German
	import (PLUGINDIR..".Strings.German");
elseif LANGID == 4 then		-- Russian
	import (PLUGINDIR..".Strings.Russian");
else
	import (PLUGINDIR..".Strings.English");
end
