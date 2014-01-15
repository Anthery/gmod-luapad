
local IndentCharacters = {" ", "	"}

local function TrimIndentations(line)
	local fi = 1
	for i=1,line:len() do
		if not table.HasValue(IndentCharacters, line:sub(i, i)) then fi = i break end
	end
	return line:sub(fi)
end

local function EndWithKeyword(line, keyword)
	local len = line:len()
	local klen = keyword:len()

	local lsoff = 1
	if line:sub(len, len) == ";" then lsoff = lsoff - 2 end
	if line:sub(len, len) == ")" then lsoff = lsoff - 2 end

	local nl = len-klen+lsoff

	if line:sub(nl, nl + klen) == keyword then
		return true
	end
	return false
end

local function Finds(string, pattern)
	local count = 0
	for i in string.gmatch(string, pattern) do
	   count = count + 1
	end
	return count
end

local function CheckEnds(row)
	local thens = Finds(row, "then")
	local ends = Finds(row, "end")
	if thens == ends then return false end

	return EndWithKeyword(row, "end")
end

local function CheckBrackets(row)
	local l = Finds(row, "{")
	local r = Finds(row, "}")
	return l ~= r
end

function LuaPadEditor:FixLuaIndentation(spacesPerIndent)
	spacesPerIndent = spacesPerIndent or 4

	local indentlevel = 0
	for ln,row in pairs(self.Rows) do
		local trimmedrow = row:Trim()
		if trimmedrow:StartWith("until") or CheckEnds(trimmedrow) or (EndWithKeyword(trimmedrow, "}") and CheckBrackets(trimmedrow)) then
			indentlevel = indentlevel - 1
		end

		if Finds(row, "elseif") > 0 or Finds(row, "else") > 0 then indentlevel = indentlevel - 1 end

		self.Rows[ln] = string.rep(" ", indentlevel*spacesPerIndent) .. trimmedrow

		if EndWithKeyword(trimmedrow, "do") or EndWithKeyword(trimmedrow, "then") or EndWithKeyword(trimmedrow, "else") or (CheckBrackets(row) or EndWithKeyword(row, "{")) or trimmedrow:find("function(.*)%)") then
			indentlevel = indentlevel + 1
		end
		indentlevel = math.max(indentlevel, 0)
	end
end