
LuaPadEditor:AddHook("SetupKeys", "TextCmds", function(self)
	self:SetupKey("Select All", "CTRL A", self.SelectAll)
	self:SetupKey("Cut", "CTRL X", self.DoCut)
	self:SetupKey("Copy", "CTRL C", self.DoCopy)
end)

LuaPadEditor:AddHook("RightMouseMenu", "TextCmds", function(self, menu)
	
	if(self:HasSelection()) then
		menu:AddOption("Cut",  function()
			if(self:HasSelection()) then
				self.clipboard = self:GetSelection()
				self.clipboard = string.Replace(self.clipboard, "\n", "\r\n")
				SetClipboardText(self.clipboard)
				self:SetSelection()
			end
		end)
		menu:AddOption("Copy",  function()
			if(self:HasSelection()) then
				self.clipboard = self:GetSelection()
				self.clipboard = string.Replace(self.clipboard, "\n", "\r\n")
				SetClipboardText(self.clipboard)
			end
		end)
	end
	
	menu:AddOption("Paste",  function()
		if(self.clipboard) then
			self:SetSelection(self.clipboard)
		else
			self:SetSelection()
		end
	end)
	
	if(self:HasSelection()) then
		menu:AddOption("Delete",  function()
			self:SetSelection()
		end)
	end

	menu:AddSpacer()
	
	menu:AddOption("Select all",  function()
		self:SelectAll()
	end)
end)

function LuaPadEditor:DoCut()
	if(self:HasSelection()) then
		self.clipboard = self:GetSelection()
		self.clipboard = string.Replace(self.clipboard, "\n", "\r\n")
		SetClipboardText(self.clipboard)
		self:SetSelection()
	end
end

function LuaPadEditor:DoCopy()
	if(self:HasSelection()) then
		self.clipboard = self:GetSelection()
		self.clipboard = string.Replace(self.clipboard, "\n", "\r\n")
		SetClipboardText(self.clipboard)
	end
end

function LuaPadEditor:SelectAll()
	self.Caret = {#self.Rows, string.len(self.Rows[#self.Rows]) + 1}
	self.Start = {1, 1}
	self:ScrollCaret()
end