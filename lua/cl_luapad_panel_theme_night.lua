
local function ReverseColor(r, g, b, a)
	return Color(255 - r, 255 - g, 255 - b, a)
end

local colors = {
	Gutter = Color(55, 55, 55, 255),
	StatusBar = Color(65, 65, 65, 255),
	Background = Color(25, 25, 25, 255),
	Selection = Color(85, 85, 85, 255),
	SelectedRow = Color(25, 25, 25, 255),
	Cursor = ReverseColor(72, 61, 139),

	-- Syntax

	Syntax_none = ReverseColor(0, 0, 0),
	Syntax_number = ReverseColor(218, 165, 32),
	Syntax_function = ReverseColor(100, 100, 255),
	Syntax_enum = ReverseColor(184, 134, 11),
	Syntax_metatable = ReverseColor(140, 100, 90),
	Syntax_table = ReverseColor(140, 100, 90),
	Syntax_string = ReverseColor(120, 120, 120),
	Syntax_expression = ReverseColor(0, 0, 255),
	Syntax_operator = ReverseColor(0, 0, 128),
	Syntax_comment = ReverseColor(0, 120, 0)
}

LuaPadEditor:AddHook("ThemeColor", "Theme_NightShade", function(self, name)
	return colors[name]
end)