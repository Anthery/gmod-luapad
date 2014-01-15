
LuaPadEditor:AddHook("SetupKeys", "AutoCompletion", function(self)

	local function SelectAutoCompl(self, isTab)
		local sugg = self:GetSuggestions()
		if self.SuggestionsVisible and sugg and #sugg > 0 then
			local hovered = sugg[self.HoveredSuggestion or 1]
			if hovered then
				local line = self.Caret[1]
				--local cword, lchar, rchar = self:GetCaretWord(true)

				--self:SetCaret(self:SetArea({self.Caret, self:MovePosition(self.Caret, -string.len(cword))}))
				--self:SetCaret(self:SetArea({ {line, lchar}, {line, rchar+1} }))

				self.Start = self:GetWordStart(self.Caret)
				self.Caret = self:GetWordEnd(self.Caret)
				self:SetSelection(hovered.name)

				local cchar = self.Caret[2]

				self.SuggestionsVisible = false

				if hovered.atype == "function" then
					self:SetSelection("()")
					self:SetCaret({line, cchar+1})
				elseif hovered.atype == "table" then
					self:SetSelection(".")
					self:SetCaret({line, cchar+1})
					self.SuggestionsVisible = true
				end

				self:_OnTextChanged()

			end

			if isTab then
				self.TabFocus = true
			end

			return true
		end
	end

	self:SetupKey("Select Auto-Completion", "ENTER", SelectAutoCompl)
	self:SetupKey("Select Auto-Completion (alt)", "TAB", function(self)
		return SelectAutoCompl(self, true)
	end)

	self:SetupKey("Move Down In Auto-Completion List", "DOWN", function(self)
		if self.SuggestionsVisible and (self.SuggestionCount or 0) > 0 then
			self.HoveredSuggestion = (self.HoveredSuggestion or 0) + 1
			return true
		end
	end)
	self:SetupKey("Move Up In Auto-Completion List", "UP", function(self)
		if self.SuggestionsVisible and (self.SuggestionCount or 0) > 0 then
			self.HoveredSuggestion = (self.HoveredSuggestion or 0) - 1
			return true
		end
	end)
end)

LuaPadEditor.AutoComplVariableColors = {
	string = Color(0, 0, 127),
	table = Color(127, 0, 127),
	Other = Color(0, 0, 0)
}

LuaPadEditor:AddHook("PostPaint", "AutoCompletion", function(self)
	local sugg = self:GetSuggestions()
	self.SuggestionCount = sugg and #sugg or 0
	if sugg and self.SuggestionsVisible then
		local cx, cy = self:CaretPos()
		local sx, sy = self:ScrollPos()
		cy = cy - sy
		cx = cx - sx

		if #sugg == 0 then
			--self.SuggestionsVisible = false
		end

		surface.SetFont("LuapadEditor")

		local eah = draw.GetFontHeight("LuapadEditor") * 1.7
		local cw, ch = 150, 0

		local suggs = 0
		for k,v in pairs(sugg) do
			if suggs > 15 then break end
			local tw, th = surface.GetTextSize(v.name)
			cw = math.max(tw + 14, cw)
			suggs = suggs + 1
		end

		ch = math.min(#sugg, 16) * eah

		surface.SetDrawColor(Color(255, 255, 255, 255))
		surface.DrawRect(cx, cy, cw, ch)
		surface.SetDrawColor(Color(0, 0, 0, 255))
		surface.DrawOutlinedRect(cx, cy, cw, ch)

		if not self.HoveredSuggestion or not self.SuggestionsVisible then
			self.HoveredSuggestion = 1
		end

		do
			if self.HoveredSuggestion < 1 then
				self.HoveredSuggestion = #sugg
			elseif self.HoveredSuggestion > #sugg then
				self.HoveredSuggestion = 1
			end
		end

		local suggs = 0
		for k,v in ipairs(sugg) do
			if suggs > 15 then break end

			local clr = self.AutoComplVariableColors[v.atype] or self.AutoComplVariableColors.Other

			if self.HoveredSuggestion == k then
				surface.SetDrawColor(Color(0, 127, 0, 100))
				surface.DrawRect(cx + 2, cy + 2 + (k-1)*eah, cw - 4, eah-4)
			end

			draw.DrawText(v.name, "LuapadEditor", cx + 5, cy + 5 + (k-1)*eah, clr, TEXT_ALIGN_LEFT)
			suggs = suggs + 1
		end
	end
end)

function LuaPadEditor:FindVar(var)
	local loc = var:Split(".")
	local x = self.OverrideGlobal or _G
	for _, v in ipairs( loc ) do
		x = x[ v ]
		if not x then return end
	end
	return x
end

function LuaPadEditor:FindVarParent(var)
	local loc = var:Split(".")
	local x = self.OverrideGlobal or _G
	if #loc > 1 and not x[loc[1]] then
		return nil -- it's not in _G, we can give up
	end
	local par
	for _, v in ipairs( loc ) do
		par = x
		if type(x) ~= "table" then return nil end -- We shouldnt have a suggestions at all (except metatable?) if indexing nontable
		x = x[ v ]
		if not x then return par end
	end
	return par
end

function LuaPadEditor:FindPossibleVars(var)
	local last = var:Split(".")
	last = last[#last]
	local par = self:FindVarParent(var)
	if par then
		local r = {}
		for name,value in SortedPairs(par) do
			if name:StartWith(last) and name ~= last then
				table.insert(r, {name = name, atype = type(value)})
			end
		end
		return r
	end
	return nil
end

function LuaPadEditor:FindPossibleKeyWords(var)
	for _,kw in pairs(self.LUA_KEYWORDS) do
		if kw:StartWith(var) then
			return kw
		end
	end
end

function LuaPadEditor:GetSuggestions()
	local cword = self:GetCaretMemberGet()

	if cword == "" then return end
	local sugg = {}

	local var = self:FindPossibleVars(cword)
	table.Add(sugg, var)

	local kw = self:FindPossibleKeyWords(cword)
	if kw then
		table.insert(sugg, {name = kw, atype = "string"})
	end

	for _,su in pairs(sugg) do
		if su.name == cword then
			table.RemoveByValue(sugg, su)
		end
	end

	return #sugg > 0 and sugg or nil
end