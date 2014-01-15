LuaPadEditor = {}
LuaPadEditor.LUA_KEYWORDS = {
	"and", "break", "do", "else", "elseif", "end", "false", "for", "function", "if", "in", "local", "nil", "not", "or", "repeat", "return", "then", "true", "until", "while"
}

LuaPadEditor.MatchPairs = {
	["\""] = "\"",
	["\'"] = "\'",
	["("] = ")",
	["["] = "]"
}

LuaPadEditor.HOOK_IMPORTANT = 3
LuaPadEditor.HOOK_NORMAL = 2
LuaPadEditor.HOOK_UNIMPORTANT = 1

local function HookTblSorter(a, b)
	return a.priority < b.priority
end

function LuaPadEditor:AddHook( name, id, cb )
	--priority = priority or self.HOOK_NORMAL

	self.Hooks = self.Hooks or {}
	self.Hooks[name] = self.Hooks[name] or {}
	self.Hooks[name][id] = {callback = cb }
	--table.sort(self.Hooks[name], HookTblSorter)
end

function LuaPadEditor:CallHook( name, ... )

	if self.Hooks and self.Hooks[name] then
		for id,val in pairs(self.Hooks[name]) do
			local ret = {val.callback(self, ...)}
			if ret[1] then return unpack(ret) end
		end
	end

	local fn = self[name]
	if not fn then return end
	return fn(self, ...)
end

function LuaPadEditor:Init()
	self:SetCursor("beam");

	surface.SetFont("LuapadEditor");
	self.FontWidth, self.FontHeight = surface.GetTextSize(" ");

	self.Rows = {""};
	self.Caret = {1, 1};
	self.Start = {1, 1};
	self.Scroll = {1, 1};
	self.Size = {1, 1};
	self.PaintRows = {};

	self.Blink = RealTime();

	self.ScrollBar = vgui.Create("DVScrollBar", self);
	self.ScrollBar:SetUp(1, 1);

	self.TextEntry = vgui.Create("TextEntry", self);
	self.TextEntry:SetMultiline(true);
	self.TextEntry:SetSize(0, 0);

	self.TextEntry.OnLoseFocus = function (self) self.Parent:_OnLoseFocus(); end
	self.TextEntry.OnTextChanged = function (self) self.Parent:_OnTextChanged(); end
	self.TextEntry.OnKeyCodeTyped = function (self, code) self.Parent:_OnKeyCodeTyped(code); end

	self.TextEntry.Parent = self;

	self.LastClick = 0;

	self:CallHook("Initialize")

end

function LuaPadEditor:RequestFocus()
	self.TextEntry:RequestFocus();
end

function LuaPadEditor:OnGetFocus()
	self.TextEntry:RequestFocus();
end

function LuaPadEditor:GetValue()
	return string.Implode("\n", self.Rows)
end

function LuaPadEditor:CheckGlobal(func)
	if self.OverrideGlobal then return self.OverrideGlobal[func]
	elseif(_G[func] != nil) then return _G[func]; end

	return false;
end

function LuaPadEditor:SetStatus(status, time)
	time = time or 5

	self.Status = {
		Msg = status,
		Alpha = status == "" and 0 or 1
	}
	timer.Create("LuaPadStatusAlpha", time, 1, function()
		if not self.Status then return end
		self.Status.Alpha = 0
	end)
end

function LuaPadEditor:CursorToCaret()
	local x, y = self:CursorPos();

	x = x - (self.FontWidth * 3 + 6);
	if(x < 0) then x = 0; end
	if(y < 0) then y = 0; end

	local line = math.floor(y / self.FontHeight);
	local char = math.floor(x / self.FontWidth + 0.5);

	line = line + self.Scroll[1];
	char = char + self.Scroll[2];

	if(line > #self.Rows) then line = #self.Rows; end
	local length = string.len(self.Rows[line]);
	if(char > length + 1) then char = length + 1; end

	return { line, char };
end

function LuaPadEditor:CaretPos()
	local line, char = self.Caret[1], self.Caret[2]
	if not line or not char then return end

	local y = line * self.FontHeight
	local x = char * self.FontWidth - 0.5 + (self.FontWidth * 3 + 6)

	return x, y
end

function LuaPadEditor:ScrollPos()
	local line, char = self.Scroll[1], self.Scroll[2]
	if not line or not char then return end

	local y = line * self.FontHeight
	local x = char * self.FontWidth - 0.5 + (self.FontWidth * 3 + 6)

	return x, y
end

function LuaPadEditor:SetText(text)
	self.Rows = string.Explode("\n", text);
	if(self.Rows[#self.Rows] != "") then
		self.Rows[#self.Rows + 1] = "";
	end

	self.Caret = {1, 1};
	self.Start = {1, 1};
	self.Scroll = {1, 1};
	self.Undo = {};
	self.Redo = {};
	self.PaintRows = {};

	self.ScrollBar:SetUp(self.Size[1], #self.Rows - 1);
end

function LuaPadEditor:NextChar()
	if(!self.char) then return end

	self.str = self.str .. self.char
	self.pos = self.pos + 1

	if(self.pos <= string.len(self.line)) then
		self.char = string.sub(self.line, self.pos, self.pos)
	else
		self.char = nil
	end
end

function LuaPadEditor:PerformLayout()
	self.ScrollBar:SetSize(16, self:GetTall())
	self.ScrollBar:SetPos(self:GetWide() - 16, 0)

	self.Size[1] = math.floor(self:GetTall() / self.FontHeight) - 1
	self.Size[2] = math.floor((self:GetWide() - (self.FontWidth * 3 + 6) - 16) / self.FontWidth) - 1

	self.ScrollBar:SetUp(self.Size[1], #self.Rows - 1)
end

function LuaPadEditor:GetCaretMemberGet(stopatperiod)
	local line, char = self.Caret[1], self.Caret[2]
 	local row = self.Rows[line]
 	local lchar, rchar = char-1, char-1 -- we must start at character on left side of caret

 	local function IsValidChar(c)
 		if c == "." then
 			return not stopatperiod
 		end
 		return (c >= "a" and c <= "z") or
 				(c >= "A" and c <= "Z") or
 				(c >= "0" and c <= "9")
 	end

 	-- First traverse left

 	while true do
 		local lower = lchar - 1
 		if lower > 0 and IsValidChar(row:sub(lower, lower)) then
 			lchar = lower
 		else break end
 	end

 	while true do
 		local higher = rchar + 1
 		if higher <= string.len(row) and IsValidChar(row:sub(higher, higher)) then
 			rchar = higher
 		else break end
 	end

 	return row:sub(lchar, rchar), lchar, rchar
 end
 
 function LuaPadEditor:SetCaret(caret)
	self.Caret = self:CopyPosition(caret)
	self.Start = self:CopyPosition(caret)
	self:ScrollCaret()
 end

 function LuaPadEditor:CopyPosition(caret)
	return { caret[1], caret[2] }
 end

 function LuaPadEditor:MovePosition(caret, offset)
	local caret = { caret[1], caret[2] }

	if(offset > 0) then
		while true do
			local length = string.len(self.Rows[caret[1]]) - caret[2] + 2
			if(offset < length) then
				caret[2] = caret[2] + offset
				break
			elseif(caret[1] == #self.Rows) then
				caret[2] = caret[2] + length - 1
				break
			else
				offset = offset - length
				caret[1] = caret[1] + 1
				caret[2] = 1
			end
		end
	elseif(offset < 0) then
		offset = -offset
		
		while true do
			if(offset < caret[2]) then
				caret[2] = caret[2] - offset
				break
			elseif(caret[1] == 1) then
				caret[2] = 1
				break
			else
				offset = offset - caret[2]
				caret[1] = caret[1] - 1
				caret[2] = string.len(self.Rows[caret[1]]) + 1
			end
		end
	end
	
	return caret
 end

 function LuaPadEditor:HasSelection()
	return self.Caret[1] != self.Start[1] || self.Caret[2] != self.Start[2]
 end

 function LuaPadEditor:Selection()
	return { { self.Caret[1], self.Caret[2] }, { self.Start[1], self.Start[2] } }
 end

 function LuaPadEditor:MakeSelection(selection)
	local start, stop = selection[1], selection[2]

	if(start[1] < stop[1] or start[1] == stop[1] and start[2] < stop[2]) then
		return start, stop
	else
		return stop, start
	end
 end

 function LuaPadEditor:GetArea(selection)
	local start, stop = self:MakeSelection(selection)

	if(start[1] == stop[1]) then
		return string.sub(self.Rows[start[1]], start[2], stop[2] - 1)
	else
		local text = string.sub(self.Rows[start[1]], start[2])
		
		for i=start[1]+1,stop[1]-1 do
			text = text .. "\n" .. self.Rows[i]
		end
		
		return text .. "\n" .. string.sub(self.Rows[stop[1]], 1, stop[2] - 1)
	end
 end

 function LuaPadEditor:SetArea(selection, text, isundo, isredo, before, after)
	local start, stop = self:MakeSelection(selection)
	
	local buffer = self:GetArea(selection)
	
	if(start[1] != stop[1] or start[2] != stop[2]) then
		-- clear selection
		self.Rows[start[1]] = string.sub(self.Rows[start[1]], 1, start[2] - 1) .. string.sub(self.Rows[stop[1]], stop[2])
		self.PaintRows[start[1]] = false
		
		for i=start[1]+1,stop[1] do
			table.remove(self.Rows, start[1] + 1)
			table.remove(self.PaintRows, start[1] + 1)
			self.PaintRows = {} -- TODO: fix for cache errors
		end
		
		-- add empty row at end of file (TODO!)
		if(self.Rows[#self.Rows] != "") then
			self.Rows[#self.Rows + 1] = ""
			self.PaintRows[#self.Rows + 1] = false
		end
	end
	
	if(!text or text == "") then
		self.ScrollBar:SetUp(self.Size[1], #self.Rows - 1)
		
		self.PaintRows = {}
	
		self:OnTextChanged()
	
		if(isredo) then
			self.Undo[#self.Undo + 1] = { { self:CopyPosition(start), self:CopyPosition(start) }, buffer, after, before }
			return before
		elseif(isundo) then
			self.Redo[#self.Redo + 1] = { { self:CopyPosition(start), self:CopyPosition(start) }, buffer, after, before }
			return before
		else
			self.Redo = {}
			self.Undo[#self.Undo + 1] = { { self:CopyPosition(start), self:CopyPosition(start) }, buffer, self:CopyPosition(selection[1]), self:CopyPosition(start) }
			return start
		end
	end
	
	-- insert text
	local rows = string.Explode("\n", text)
	
	local remainder = string.sub(self.Rows[start[1]], start[2])
	self.Rows[start[1]] = string.sub(self.Rows[start[1]], 1, start[2] - 1) .. rows[1]
	self.PaintRows[start[1]] = false
	
	for i=2,#rows do
		table.insert(self.Rows, start[1] + i - 1, rows[i])
		table.insert(self.PaintRows, start[1] + i - 1, false)
		self.PaintRows = {} // TODO: fix for cache errors
	end

	local stop = { start[1] + #rows - 1, string.len(self.Rows[start[1] + #rows - 1]) + 1 }
	
	self.Rows[stop[1]] = self.Rows[stop[1]] .. remainder
	self.PaintRows[stop[1]] = false
	
	-- add empty row at end of file (TODO!)
	if(self.Rows[#self.Rows] != "") then
		self.Rows[#self.Rows + 1] = ""
		self.PaintRows[#self.Rows + 1] = false
		self.PaintRows = {} // TODO: fix for cache errors
	end
	
	self.ScrollBar:SetUp(self.Size[1], #self.Rows - 1)
	
	self.PaintRows = {}
	
	self:OnTextChanged()
	
	if(isredo) then
		self.Undo[#self.Undo + 1] = { { self:CopyPosition(start), self:CopyPosition(stop) }, buffer, after, before }
		return before
	elseif(isundo) then
		self.Redo[#self.Redo + 1] = { { self:CopyPosition(start), self:CopyPosition(stop) }, buffer, after, before }
		return before
	else
		self.Redo = {}
		self.Undo[#self.Undo + 1] = { { self:CopyPosition(start), self:CopyPosition(stop) }, buffer, self:CopyPosition(selection[1]), self:CopyPosition(stop) }
		return stop
	end
 end

 function LuaPadEditor:GetSelection()
	return self:GetArea(self:Selection())
 end

 function LuaPadEditor:SetSelection(text)
	self:SetCaret(self:SetArea(self:Selection(), text))
 end

 function LuaPadEditor:_OnLoseFocus()
	if(self.TabFocus) then
		self:RequestFocus()
		self.TabFocus = nil
	end
 end

 function LuaPadEditor:_OnTextChanged()
	local ctrlv = false
	local text = self.TextEntry:GetValue()
	self.TextEntry:SetText("")

	if input.IsKeyDown(KEY_BACKQUOTE) and IgnoreConsoleOpen then return end
	
	if((input.IsKeyDown(KEY_LCONTROL) or input.IsKeyDown(KEY_RCONTROL)) and not (input.IsKeyDown(KEY_LALT) or input.IsKeyDown(KEY_RALT))) then
		-- ctrl+[shift+]key
		if(input.IsKeyDown(KEY_V)) then
			-- ctrl+[shift+]V
			ctrlv = true
		else
			-- ctrl+[shift+]key with key ~= V
			return
		end
	end
	
	if(text == "") then return end
	if(not ctrlv) then
		if(text == "\n") then return end
		if(text == "end") then
			local row = self.Rows[self.Caret[1]]
		end
	end
	
	self:SetSelection(text)
	if self.MatchPairs[text] then
		local cchar = self.Caret[2]
		self:SetSelection(self.MatchPairs[text])
		self:SetCaret({self.Caret[1], cchar})
	end

	self:CallHook("TextChanged", text, self:GetValue())
 end

 function LuaPadEditor:ScrollCaret()
	if(self.Caret[1] - self.Scroll[1] < 2) then
		self.Scroll[1] = self.Caret[1] - 2
		if(self.Scroll[1] < 1) then self.Scroll[1] = 1 end
	end

	if(self.Caret[1] - self.Scroll[1] > self.Size[1] - 2) then
		self.Scroll[1] = self.Caret[1] - self.Size[1] + 2
		if(self.Scroll[1] < 1) then self.Scroll[1] = 1 end
	end
	
	if(self.Caret[2] - self.Scroll[2] < 4) then
		self.Scroll[2] = self.Caret[2] - 4
		if(self.Scroll[2] < 1) then self.Scroll[2] = 1 end
	end
	
	if(self.Caret[2] - 1 - self.Scroll[2] > self.Size[2] - 4) then
		self.Scroll[2] = self.Caret[2] - 1 - self.Size[2] + 4
		if(self.Scroll[2] < 1) then self.Scroll[2] = 1 end
	end
	
	self.ScrollBar:SetScroll(self.Scroll[1] - 1)
 end

 function unindent(line)
	local i = line:find("%S")
	if(i == nil or i > 5) then i = 5 end
	return line:sub(i)
 end

 function LuaPadEditor:GetWordStart(caret)
	local line = string.ToTable(self.Rows[caret[1]])

	local caret1, caret2 = caret[1], caret[2]

	if #line == caret2 - 1 then caret2 = caret2 - 1 end
	if #line < caret2 then return caret end

	for i=0,caret2 do
		if(!line[caret2-i]) then return {caret1,caret2-i+1} end
		if(line[caret2-i] >= "a" and line[caret2-i] <= "z" or line[caret2-i] >= "A" and line[caret2-i] <= "Z" or line[caret2-i] >= "0" and line[caret2-i] <= "9" or line[caret2-i] == ")" --[[ HACK HACK HACK]]) then else return {caret1,caret2-i+1} end
	end
	return {caret1,1}
 end

 function LuaPadEditor:GetWordEnd(caret)
	local line = string.ToTable(self.Rows[caret[1]])
	if(#line < caret[2]) then return caret end
	for i=caret[2],#line do
		if(!line[i]) then return {caret[1],i} end
		if(line[i] >= "a" and line[i] <= "z" or line[i] >= "A" and line[i] <= "Z" or line[i] >= "0" and line[i] <= "9") then else return {caret[1],i} end
	end
	return {caret[1],#line+1}
 end
 
 function LuaPadEditor:Indent(shift)
	local tab_scroll = self:CopyPosition(self.Scroll)
	local tab_start, tab_caret = self:MakeSelection(self:Selection())
	tab_start[2] = 1

	if(tab_caret[2] ~= 1) then
		tab_caret[1] = tab_caret[1] + 1
		tab_caret[2] = 1
	end

	self.Caret = self:CopyPosition(tab_caret)
	self.Start = self:CopyPosition(tab_start)

	if (self.Caret[2] == 1) then
		self.Caret = self:MovePosition(self.Caret, -1)
	end
	
	if(shift) then
		local tmp = self:GetSelection():gsub("\n ? ? ? ?", "\n")
		self:SetSelection(unindent(tmp))
	else
		self:SetSelection("    " .. self:GetSelection():gsub("\n", "\n    "))
	end
	
	self.Caret = self:CopyPosition(tab_caret)
	self.Start = self:CopyPosition(tab_start)
	self.Scroll = self:CopyPosition(tab_scroll)
	self:ScrollCaret()
 end
 
 function LuaPadEditor:OnTextChanged()
	self:CallHook("TextChanged", "", self:GetValue())
 end
 
 function LuaPadEditor:OnShortcut()
 end