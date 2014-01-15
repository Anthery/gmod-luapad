
function LuaPadEditor:SyntaxColorLine(row, coloringcomment)
	local cols = {}
	local lasttable;
	self.line = self.Rows[row]
	self.pos = 0
	self.char = ""
	self.str = ""

	local CheckGlobal = function(...) -- a quick helper function
		self:CheckGlobal(...)
	end

	-- TODO: Color customization?
	colors = {
		["none"] =  { self:CallHook("ThemeColor", "Syntax_none") or Color(0, 0, 0, 255), false},
		["number"] =    { self:CallHook("ThemeColor", "Syntax_number") or Color(218, 165, 32, 255), false},
		["function"] =  { self:CallHook("ThemeColor", "Syntax_function") or Color(100, 100, 255, 255), false},
		["enumeration"] =  { self:CallHook("ThemeColor", "Syntax_enum") or Color(184, 134, 11, 255), false},
		["metatable"] =  { self:CallHook("ThemeColor", "Syntax_metatable") or Color(140, 100, 90, 255), false},
		["table"] =  { self:CallHook("ThemeColor", "Syntax_table") or Color(140, 100, 90, 255), false}, -- TODO other color than metatable
		["string"] =    { self:CallHook("ThemeColor", "Syntax_string") or Color(120, 120, 120, 255), false},
		["expression"] =    { self:CallHook("ThemeColor", "Syntax_expression") or Color(0, 0, 255, 255), false},
		["operator"] =  { self:CallHook("ThemeColor", "Syntax_operator") or Color(0, 0, 128, 255), false},
		["comment"] =   { self:CallHook("ThemeColor", "Syntax_comment") or Color(0, 120, 0, 255), false},
	}

	colors["string2"] = colors["string"];

	self:NextChar();

	while self.char do
		token = "";
		self.str = "";
		
		while self.char and self.char == " " do self:NextChar() end
		if(!self.char) then break end
		
		if coloringcomment then
			if coloringcomment == "]]" then
				local endingml = false
				while self.char do
					if self.char == "]" then
						if endingml then self:NextChar() coloringcomment = nil break end
						endingml = true
					else
						endingml = false
					end
					self:NextChar()
				end
			elseif coloringcomment == "*/" then
				local endingml = false
				while self.char do
					if endingml and self.char == "/" then self:NextChar() coloringcomment = nil break
					elseif not endingml and self.char == "*" then endingml = true
					else endingml = false end
					self:NextChar()
				end
			else
				ErrorNoHalt("Unknown coloring comment style " .. tostring(coloringcomment))
			end
			token = "comment"
		elseif(self.char >= "0" and self.char <= "9") then
			while self.char and (self.char >= "0" and self.char <= "9" or self.char == "." or self.char == "_") do self:NextChar() end
			
			token = "number"
		elseif(self.char >= "a" and self.char <= "z" or self.char >= "A" and self.char <= "Z") then
			
			while self.char and (self.char >= "a" and self.char <= "z" or self.char >= "A" and self.char <= "Z" or
			self.char >= "0" and self.char <= "9" or self.char == "_" or self.char == ".") do self:NextChar(); end
			
			local sstr = string.Trim(self.str)

			local var = self:FindVar(sstr)

			if(table.HasValue(self.LUA_KEYWORDS, sstr)) then
				
				token = "expression"
				
			elseif( var ) then

				--if((CheckGlobal(sstr) == "e") && sstr == string.upper(sstr)) then
				--	token = "enumeration";
				--elseif(CheckGlobal(sstr) == "m") then
				if type(var) == "table" then
					token = "metatable";
				elseif type(var) == "number" then
					token = "number"
				elseif type(var) == "string" then
					token = "string"
				elseif type(var) == "function" then
					token = "function"
				else
					token = "none"
				end
				
			else
				token = "none"
				
			end
		elseif(self.char == "\"") then -- TODO: Fix multiline strings, and add support for [[stuff]]!
		
			self:NextChar()
			while self.char and self.char != "\"" do
				if(self.char == "\\") then self:NextChar() end
				self:NextChar()
			end
			self:NextChar()
			
			token = "string"
		elseif(self.char == "'") then
		
			self:NextChar()
			while self.char and self.char != "'" do
				if(self.char == "\\") then self:NextChar() end
				self:NextChar()
			end
			self:NextChar()
			
			token = "string2"
		elseif(self.char == "/" or self.char == "-") then -- TODO: Multiline comments work on single lines, need multiline integration!
		
			local lastchar = self.char;
			self:NextChar()
			
			if(self.char == lastchar or (lastchar == "/" and self.char == "*")) then
				if self.char == "-" then
					local startpos, sbrackets = self.pos, 0
					local multiline, endingml = false, false

					while self.char do
						self:NextChar()
						if self.char == "[" then sbrackets = sbrackets + 1 end
						if multiline and self.char == "]" then
							if endingml then self:NextChar() break end
							endingml = true
						elseif not multiline and (self.pos-startpos) == 2 and sbrackets == 2 then
							multiline = true
						else
							endingml = false
						end
					end

					if multiline and not self.char then -- multiline comment didnt end
						coloringcomment = "]]"
					end

				elseif self.char == "*" then
					local endingml = false
					local needcontinue = false
					while self.char do
						self:NextChar()
						if endingml and self.char == "/" then self:NextChar() break
						elseif not endingml and self.char == "*" then endingml = true
						else endingml = false end
					end

					if not self.char then -- multiline comment didnt end
						coloringcomment = "*/"
					end

				else -- One line //
					while self.char do
						self:NextChar()
					end
				end
				
				token = "comment"

			else
				token = "none";
			end
		elseif(self.char == "[") then
		
			local lastchar = self.char;
			self:NextChar()
			
			if(self.char == "[") then

				local lasttoken = token

				local closingbracket = false
				while self.char do
					self:NextChar()
					if self.char == "]" then
						if closingbracket then break end
						closingbracket = true
					else
						closingbracket = false
					end
				end
				
				if lasttoken == "comment" then
					token = "comment"
				else
					token = "none" -- TODO array selector could have its own token?
				end
			else
				token = "none";
			end
		else
		
			self:NextChar()
			
			token = "operator"
			
		end
		
		color = colors[token]
		if(#cols > 1 and color == cols[#cols][2]) then
			cols[#cols][1] = cols[#cols][1] .. self.str
		else
			cols[#cols + 1] = {self.str, color}
		end
	end

	return cols, coloringcomment
end