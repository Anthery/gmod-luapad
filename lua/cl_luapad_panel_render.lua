function LuaPadEditor:PaintRelatedRows(row, cc)
	local cols, cc = self:SyntaxColorLine(row, cc)
	self.PaintRows[row] = cols
	if cc then
		local nr = row+1
		if not self.Rows[nr] then return end -- TODO comment ends prematurely
		self:PaintRelatedRows(nr, cc)
	end
end

surface.CreateFont("LuapadEditor", {
	font = "Lucida Console",
	size = 14,
	weight = 400
})
surface.CreateFont("LuapadEditor_Bold", {
	font = "Lucida Console",
	size = 14,
	weight = 800
})

function LuaPadEditor:PaintLine(row)
	if(row > #self.Rows) then return end

	if(!self.PaintRows[row]) then
		self:PaintRelatedRows(row)
	end

	local width, height = self.FontWidth, self.FontHeight

	if(row == self.Caret[1] and self.TextEntry:HasFocus()) then
		surface.SetDrawColor(self:CallHook("ThemeColor", "SelectedRow") or Color(220, 220, 220, 255))
		surface.DrawRect(width * 3 + 5, (row - self.Scroll[1]) * height, self:GetWide() - (width * 3 + 5), height)
	end

	if(self:HasSelection()) then
		local start, stop = self:MakeSelection(self:Selection())
		local line, char = start[1], start[2]
		local endline, endchar = stop[1], stop[2]
		
		surface.SetDrawColor(self:CallHook("ThemeColor", "Selection") or Color(170, 170, 170, 255))
		local length = string.len(self.Rows[row]) - self.Scroll[2] + 1
		
		char = char - self.Scroll[2]
		endchar = endchar - self.Scroll[2]
		if(char < 0) then char = 0 end
		if(endchar < 0) then endchar = 0 end
		
		if(row == line and line == endline) then
			surface.DrawRect(char * width + width * 3 + 6, (row - self.Scroll[1]) * height, width * (endchar - char), height)
		elseif(row == line) then
			surface.DrawRect(char * width + width * 3 + 6, (row - self.Scroll[1]) * height, width * (length - char + 1), height)
		elseif(row == endline) then
			surface.DrawRect(width * 3 + 6, (row - self.Scroll[1]) * height, width * endchar, height)
		elseif(row > line and row < endline) then
			surface.DrawRect(width * 3 + 6, (row - self.Scroll[1]) * height, width * (length + 1), height)
		end
	end

	draw.SimpleText(tostring(row), "LuapadEditor", width * 3, (row - self.Scroll[1]) * height, Color(128, 128, 128, 255), TEXT_ALIGN_RIGHT)
	self:CallHook("PaintRowGutter", row, 0, (row - self.Scroll[1]) * height)

	local offset = -self.Scroll[2] + 1
	for i,cell in ipairs(self.PaintRows[row]) do
		if(offset < 0) then
			if(string.len(cell[1]) > -offset) then
				line = string.sub(cell[1], -offset + 1)
				offset = string.len(line)
				
				if(cell[2][2]) then
					draw.SimpleText(line, "LuapadEditorBold", width * 3 + 6, (row - self.Scroll[1]) * height, cell[2][1])
				else
					draw.SimpleText(line, "LuapadEditor", width * 3 + 6, (row - self.Scroll[1]) * height, cell[2][1])
				end
			else
				offset = offset + string.len(cell[1])
			end
		else
			if(cell[2][2]) then
				draw.SimpleText(cell[1], "LuapadEditorBold", offset * width + width * 3 + 6, (row - self.Scroll[1]) * height, cell[2][1])
			else
				draw.SimpleText(cell[1], "LuapadEditor", offset * width + width * 3 + 6, (row - self.Scroll[1]) * height, cell[2][1])
			end
			
			offset = offset + string.len(cell[1])
		end
	end

	if(row == self.Caret[1] and self.TextEntry:HasFocus()) then
		if((RealTime() - self.Blink) % 0.8 < 0.4) then
			if(self.Caret[2] - self.Scroll[2] >= 0) then
				surface.SetDrawColor(self:CallHook("ThemeColor", "Cursor") or Color(72, 61, 139, 255))
				surface.DrawRect((self.Caret[2] - self.Scroll[2]) * width + width * 3 + 6, (self.Caret[1] - self.Scroll[1]) * height, 1, height)
			end
		end
	end
end


function LuaPadEditor:Paint()
	if(!input.IsMouseDown(MOUSE_LEFT)) then
		self:OnMouseReleased(MOUSE_LEFT)
	end

	if(!self.PaintRows) then
		self.PaintRows = {}
	end

	if(self.MouseDown) then
		self.Caret = self:CursorToCaret()
	end

    render.PushFilterMin( TEXFILTER.ANISOTROPIC )
    render.PushFilterMag( TEXFILTER.ANISOTROPIC )

	surface.SetDrawColor(self:CallHook("ThemeColor", "Gutter") or Color(200, 200, 200, 255))
	surface.DrawRect(0, 0, self.FontWidth * 3 + 4, self:GetTall())

	surface.SetDrawColor(self:CallHook("ThemeColor", "Background") or Color(230, 230, 230, 255))
	surface.DrawRect(self.FontWidth * 3 + 5, 0, self:GetWide() - (self.FontWidth * 3 + 5), self:GetTall())

	if self.Status then
		self.StatusTrail = math.Approach((self.StatusTrail or 0), self.Status.Alpha or 0, 0.04)

		local statusBaseClr = self:CallHook("ThemeColor", "StatusBar") or Color(200, 200, 200, 255)
		surface.SetDrawColor(ColorAlpha(statusBaseClr, self.StatusTrail))
		surface.DrawRect(self.FontWidth * 3 + 10, self:GetTall()-28, self:GetWide() - (self.FontWidth * 3 + 15), 23)

		surface.SetTextColor(Color(255, 0, 0, 255 * self.StatusTrail))
		surface.SetFont("Trebuchet24")
		surface.SetTextPos(self.FontWidth * 3 + 15, self:GetTall()-28)
		surface.DrawText(self.Status.Msg)
	end

	self.Scroll[1] = math.floor(self.ScrollBar:GetScroll() + 1)

	for i=self.Scroll[1],self.Scroll[1]+self.Size[1]+1 do
		self:PaintLine(i)
	end

	self:CallHook("PostPaint")

    render.PopFilterMin()
    render.PopFilterMag()

	return true
end
