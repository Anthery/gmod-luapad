 -- Andreas "Syranide" Svensson's editor for Wire Expression 2
 -- edited by DarKSunrise aka Assassini
 -- to work with Luapad and with Lua-syntax
 -- edited by Wyozi with auto completion, GM13 fixes and massive refactoring

local function GenSingleFileLuaPad()
	local code = ""
	local folder = GAMEMODE.FolderName.."/gamemode/mlumodules/luapad/"

	local function AppendCode(filename)
		local f = file.Open(folder .. filename, "r", "LUA")
		local data = f:Read( f:Size() )
		code = code .. "-- LuaPad module " .. filename .. ": \n"
		code = code .. data .. "\n\n"
		f:Close()
	end

	for _, pnlfile in pairs(file.Find(folder .. "cl_luapad_panel*.lua", "LUA")) do
		AppendCode(pnlfile)
	end

	-- Register file
	do
		AppendCode("cl_luapad_register.lua")
	end

	file.Write("luapad.txt", code)
	MsgN("Written to luapad.txt")

end

concommand.Add("mlu_genluapad", GenSingleFileLuaPad)


concommand.Add("luapad", function()
	local frame = vgui.Create("DFrame")
	frame:SetSize(800, 600)
	frame:SetTitle("G = server, H = client")
	frame:Center()

	local editor = vgui.Create("LuapadEditor", frame)
	editor:Dock( FILL )

	frame:MakePopup()
end)