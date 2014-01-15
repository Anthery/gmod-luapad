local function load(f)
	if SERVER then AddCSLuaFile(f) end
	if CLIENT then include(f) end
end

load("cl_luapad.lua")
load("cl_luapad_panel.lua")
load("cl_luapad_panel_autocompl.lua")
load("cl_luapad_panel_errchck.lua")
load("cl_luapad_panel_exec.lua")
load("cl_luapad_panel_fixindent.lua")
load("cl_luapad_panel_history.lua")
load("cl_luapad_panel_keys.lua")
load("cl_luapad_panel_mouse.lua")
load("cl_luapad_panel_render.lua")
load("cl_luapad_panel_syntax.lua")
load("cl_luapad_panel_textcmds.lua")
load("cl_luapad_panel_theme_night.lua")
load("cl_luapad_register.lua")