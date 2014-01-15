
function LuaPadEditor:OnMousePressed(code)
	if self:CallHook("MousePressed", code) then
		return
	end
	if(code == MOUSE_LEFT) then
		if((CurTime() - self.LastClick) < 1 and self.tmp and self:CursorToCaret()[1] == self.Caret[1] and self:CursorToCaret()[2] == self.Caret[2]) then
			self.Start = self:GetWordStart(self.Caret)
			self.Caret = self:GetWordEnd(self.Caret)
			self.tmp = false
			return
		end
		
		self.tmp = true
		
		self.LastClick = CurTime()
		self:RequestFocus()
		self.Blink = RealTime()
		self.MouseDown = true

		self.SuggestionsVisible = false
		
		self.Caret = self:CursorToCaret()
		if(!input.IsKeyDown(KEY_LSHIFT) and !input.IsKeyDown(KEY_RSHIFT)) then
			self.Start = self:CursorToCaret()
		end
	elseif(code == MOUSE_RIGHT) then
		local menu = DermaMenu()

		self:CallHook("RightMouseMenu", menu)

		menu:Open()
	end
end

function LuaPadEditor:OnMouseReleased(code)
	if(!self.MouseDown) then return end

	if(code == MOUSE_LEFT) then
		self.MouseDown = nil
		if(!self.tmp) then return end
		self.Caret = self:CursorToCaret()
	end
end

function LuaPadEditor:OnMouseWheeled(delta)
	self.Scroll[1] = self.Scroll[1] - 4 * delta
	if(self.Scroll[1] < 1) then self.Scroll[1] = 1 end
	if(self.Scroll[1] > #self.Rows) then self.Scroll[1] = #self.Rows end
	self.ScrollBar:SetScroll(self.Scroll[1] - 1)
end