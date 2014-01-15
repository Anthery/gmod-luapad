
LuaPadEditor:AddHook("Initialize", "Keys", function(self)
	self.Shortcuts = {}

	self:CallHook("SetupKeys")
end)

local function FunctionCaller(fn, bool)
	return function(self)
		return fn(self, bool)
	end
end

LuaPadEditor:AddHook("SetupKeys", "DefaultKeys", function(self)
	--[[ Not sure these do anything

	self:SetupKey("Scroll Up", "CTRL UP", function(self)
		self.Scroll[1] = self.Scroll[1] - 1
		if(self.Scroll[1] < 1) then self.Scroll[1] = 1 end
	end)
	self:SetupKey("Scroll Down", "CTRL DOWN", function(self)
		self.Scroll[1] = self.Scroll[1] + 1
	end)
	self:SetupKey("Scroll Left", "CTRL LEFT", function(self)
		if self:HasSelection() then -- ?
			self.Start = self:CopyPosition(self.Caret)
		end
		self:ScrollCaret()
		self.Start = self:CopyPosition(self.Caret)
	end)
	self:SetupKey("Scroll Right", "CTRL RIGHT", function(self)
		if self:HasSelection() then -- ?
			self.Start = self:CopyPosition(self.Caret)
		end
		self:ScrollCaret()
		self.Start = self:CopyPosition(self.Caret)
	end)
	]]
	self:SetupDefKey("Select To Word Start", "CTRL SHIFT LEFT", function(self)
		self.Caret = self:GetWordStart(self:MovePosition(self.Caret, -2))
		self:ScrollCaret()
	end)
	self:SetupDefKey("Select To Word End", "CTRL SHIFT RIGHT", function(self)
		self.Caret = self:GetWordEnd(self:MovePosition(self.Caret, 1))
		self:ScrollCaret()
	end)

	local function MoveToHome(self, shift)
		self.Caret[1] = 1
		self.Caret[2] = 1
		
		self:ScrollCaret()

		if not shift then
			self.Start = self:CopyPosition(self.Caret)
		end
	end
	local function MoveToEnd(self, shift)
		self.Caret[1] = #self.Rows
		self.Caret[2] = 1
		
		self:ScrollCaret()

		if not shift then
			self.Start = self:CopyPosition(self.Caret)
		end
	end

	self:SetupDefKey("Move To Page Start", "CTRL HOME", FunctionCaller(MoveToHome, false))
	self:SetupDefKey("Select To Page Start", "CTRL SHIFT HOME", FunctionCaller(MoveToHome, true))

	self:SetupDefKey("Move To Page End", "CTRL END", FunctionCaller(MoveToEnd, false))
	self:SetupDefKey("Select To Page End", "CTRL SHIFT END", FunctionCaller(MoveToEnd, true))

	self:SetupDefKey("New Line", "ENTER", function(self)
		local row = self.Rows[self.Caret[1]]:sub(1,self.Caret[2]-1)
		local rowt = row:Trim()
		local diff = (row:find("%S") or (row:len()+1))-1
		local tabcount = math.floor(diff / 4)

		if rowt:EndsWith("then") or rowt:EndsWith("do") or rowt:EndsWith("until") or rowt:EndsWith("{") then
			tabcount = tabcount + 1
		end

		local tabs = string.rep("    ", tabcount)
		self:SetSelection("\n" .. tabs)
	end)

	local function MoveUp(self, shift)
		if(self.Caret[1] > 1) then
			self.Caret[1] = self.Caret[1] - 1
			
			local length = string.len(self.Rows[self.Caret[1]])
			if(self.Caret[2] > length + 1) then
				self.Caret[2] = length + 1
			end
		end
		
		self:ScrollCaret()
		
		if not shift then
			self.Start = self:CopyPosition(self.Caret)
		end
	end

	self:SetupDefKey("Move Up", "UP", FunctionCaller(MoveUp, false))
	self:SetupDefKey("Select Up", "SHIFT UP", FunctionCaller(MoveUp, true))

	local function MoveDown(self, shift)
		if(self.Caret[1] < #self.Rows) then
			self.Caret[1] = self.Caret[1] + 1
			
			local length = string.len(self.Rows[self.Caret[1]])
			if(self.Caret[2] > length + 1) then
				self.Caret[2] = length + 1
			end
		end
		
		self:ScrollCaret()
		
		if not shift then
			self.Start = self:CopyPosition(self.Caret)
		end
	end

	self:SetupDefKey("Move Down", "DOWN", FunctionCaller(MoveDown, false))
	self:SetupDefKey("Select Down", "SHIFT DOWN", FunctionCaller(MoveDown, true))

	local function MoveLeft(self, shift)
		if self:HasSelection() and not shift then
			self.Start = self:CopyPosition(self.Caret)
		else
			local buffer = self:GetArea({{self.Caret[1], self.Caret[2] - 4}, {self.Caret[1], self.Caret[2]}})
			local moveAmount = 1
			if(self.Caret[2] % 4 == 1 and string.len(buffer) > 0 and string.rep(" ", string.len(buffer)) == buffer) then
				moveAmount = 4
			end
			self.Caret = self:MovePosition(self.Caret, -moveAmount)
		end
		
		self:ScrollCaret()
		
		if not shift then
			self.Start = self:CopyPosition(self.Caret)
		end
	end

	self:SetupDefKey("Move Left", "LEFT", FunctionCaller(MoveLeft, false))
	self:SetupDefKey("Select Left", "SHIFT LEFT", FunctionCaller(MoveLeft, true))

	local function MoveRight(self, shift)
		if self:HasSelection() and not shift then
			self.Start = self:CopyPosition(self.Caret)
		else
			local buffer = self:GetArea({{self.Caret[1], self.Caret[2]}, {self.Caret[1], self.Caret[2] + 4}})
			local moveAmount = 1
			if(self.Caret[2] % 4 == 1 and string.len(buffer) > 0 and string.rep(" ", string.len(buffer)) == buffer) then
				moveAmount = 4
			end
			self.Caret = self:MovePosition(self.Caret, moveAmount)
		end
		
		self:ScrollCaret()
		
		if not shift then
			self.Start = self:CopyPosition(self.Caret)
		end
	end

	self:SetupDefKey("Move Right", "RIGHT", FunctionCaller(MoveRight, false))
	self:SetupDefKey("Select Right", "SHIFT RIGHT", FunctionCaller(MoveRight, false))

	self:SetupDefKey("Backspace", "BACKSPACE", function(self)
		if(self:HasSelection()) then
			self:SetSelection()
		else
			local buffer = self:GetArea({self.Caret, {self.Caret[1], 1}})
			if(self.Caret[2] % 4 == 1 and string.len(buffer) > 0 and string.rep(" ", string.len(buffer)) == buffer) then
				self:SetCaret(self:SetArea({self.Caret, self:MovePosition(self.Caret, -4)}))
			else
				local prevcaret, nextcaret = {self.Caret[1], self.Caret[2]-1}, {self.Caret[1], self.Caret[2]+1}
				local prevbuff, nextbuff = self:GetArea({self.Caret, prevcaret}), self:GetArea({self.Caret, nextcaret})
				if self.MatchPairs[prevbuff] and self.MatchPairs[prevbuff] == nextbuff then -- if two quotations or (matching) brackets in a row and removing first one, we should rm 2nd one which is what this does
					self:SetCaret(self:SetArea({prevcaret, nextcaret}))
				else
					self:SetCaret(self:SetArea({self.Caret, self:MovePosition(self.Caret, -1)}))
				end
			end
		end
	end)
	self:SetupDefKey("Delete", "DELETE", function(self)
		if(self:HasSelection()) then
			self:SetSelection()
		else
			local buffer = self:GetArea({{self.Caret[1], self.Caret[2] + 4}, {self.Caret[1], 1}})
			if(self.Caret[2] % 4 == 1 and string.rep(" ", string.len(buffer)) == buffer and string.len(self.Rows[self.Caret[1]]) >= self.Caret[2] + 4 - 1) then
				self:SetCaret(self:SetArea({self.Caret, self:MovePosition(self.Caret, 4)}))
			else
				self:SetCaret(self:SetArea({self.Caret, self:MovePosition(self.Caret, 1)}))
			end
		end
	end)
	self:SetupDefKey("Go To Start Of Line", "HOME", function(self)
		local row = self.Rows[self.Caret[1]]
		local first_char = row:find("%S") or row:len()+1
		if(self.Caret[2] == first_char) then
			self.Caret[2] = 1
		else
			self.Caret[2] = first_char
		end
		
		self:ScrollCaret()
		
		if(!shift) then
			self.Start = self:CopyPosition(self.Caret)
		end
	end)
	self:SetupDefKey("Go To End Of Line", "END", function(self)
		local length = string.len(self.Rows[self.Caret[1]])
		self.Caret[2] = length + 1
		
		self:ScrollCaret()
		
		if(!shift) then
			self.Start = self:CopyPosition(self.Caret)
		end
	end)
	self:SetupDefKey("Indent", "TAB", function(self)
		if(self:HasSelection()) then
			self:Indent(shift)
		else
			if(shift) then
				local newpos = self.Caret[2]-4
				if(newpos < 1) then newpos = 1 end
				self.Start = { self.Caret[1], newpos }
				if(self:GetSelection():find("%S")) then 
					self.Start = self:CopyPosition(self.Caret)
				else
					self:SetSelection("")
				end
			else
				local count = (self.Caret[2] + 2) % 4 + 1
				self:SetSelection(string.rep(" ", count))
			end
		end
		self.TabFocus = true
	end)

	local function MovePageDown(self, shift)
		self.Caret[1] = self.Caret[1] + math.ceil(self.Size[1] / 2)
		self.Scroll[1] = self.Scroll[1] + math.ceil(self.Size[1] / 2)
		if(self.Caret[1] > #self.Rows) then self.Caret[1] = #self.Rows end
		if(self.Caret[1] == #self.Rows) then self.Caret[2] = 1 end
		
		local length = string.len(self.Rows[self.Caret[1]])
		if(self.Caret[2] > length + 1) then self.Caret[2] = length + 1 end
		
		self:ScrollCaret()
		
		if(!shift) then
			self.Start = self:CopyPosition(self.Caret)
		end
	end

	self:SetupDefKey("Go Down By One Page", "PAGEDOWN", FunctionCaller(MovePageDown, false))
	self:SetupDefKey("Select Down By One Page", "SHIFT PAGEDOWN", FunctionCaller(MovePageDown, true))

	local function MovePageUp(self, shift)
		self.Caret[1] = self.Caret[1] - math.ceil(self.Size[1] / 2)
		self.Scroll[1] = self.Scroll[1] - math.ceil(self.Size[1] / 2)
		if(self.Caret[1] < 1) then self.Caret[1] = 1 end
		
		local length = string.len(self.Rows[self.Caret[1]])
		if(self.Caret[2] > length + 1) then self.Caret[2] = length + 1 end
		if(self.Scroll[1] < 1) then self.Scroll[1] = 1 end
		
		self:ScrollCaret()
		
		if(!shift) then
			self.Start = self:CopyPosition(self.Caret)
		end
	end

	self:SetupDefKey("Go Up By One Page", "PAGEUP", FunctionCaller(MovePageUp, false))
	self:SetupDefKey("Select Up By One Page", "SHIFT PAGEUP", FunctionCaller(MovePageUp, true))
end)

function LuaPadEditor:SetupDefKey(name, defshortcut, callback, priority)
	self:SetupKey(name, defshortcut, callback, priority or self.HOOK_UNIMPORTANT)
end
function LuaPadEditor:SetupKey(name, defshortcut, callback, priority)
	priority = priority or self.HOOK_NORMAL

	self.Shortcuts[defshortcut] = self.Shortcuts[defshortcut] or {}
	local tbl = self.Shortcuts[defshortcut]

	tbl[name] = {callback = callback, priority = priority}
end

function LuaPadEditor:_OnKeyCodeTyped(code)
	self.Blink = RealTime()

	local control = input.IsKeyDown(KEY_LCONTROL) or input.IsKeyDown(KEY_RCONTROL)
	local alt = input.IsKeyDown(KEY_LALT) or input.IsKeyDown(KEY_RALT)
	local shift = input.IsKeyDown(KEY_LSHIFT) or input.IsKeyDown(KEY_RSHIFT)

	local searchString = ""
	if control then searchString = searchString .. "CTRL " end
	if alt then searchString = searchString .. "ALT " end
	if shift then searchString = searchString .. "SHIFT " end

	local keyTyped
	for k,v in pairs(_G) do
		if v == code and k:StartWith("KEY_") and not k:find("SHIFT", _, true) and not k:find("CONTROL", _, true) and not k:find("ALT", _, true) then
			keyTyped = k:sub(5)
			searchString = searchString .. keyTyped
			break
		end
	end

	searchString = searchString:Trim()

	local shortcuts = self.Shortcuts[searchString]
	if not shortcuts then 

		if not alt and not control and not shift then
			self.SuggestionsVisible = true -- I dont even know what doing atm
		end

		return
	end

	local nscs = {}
	table.foreach(shortcuts, function(k,v) table.insert(nscs, v) end)
	table.sort(nscs, function(a, b)
		return a.priority > b.priority
	end)

	for _,sc in ipairs(nscs) do
		if sc.callback(self) then
			break
		end
	end

end