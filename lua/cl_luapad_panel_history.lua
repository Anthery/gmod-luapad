
LuaPadEditor:AddHook("Initialize", "History", function(self)
	self.Undo = {}
	self.Redo = {}
end)

LuaPadEditor:AddHook("SetupKeys", "History", function(self)
	self:SetupKey("Undo", "CTRL Z", self.DoUndo)
	self:SetupKey("Redo", "CTRL SHIFT Z", self.DoRedo)
end)

LuaPadEditor:AddHook("RightMouseMenu", "History", function(self, menu)
	if(self:CanUndo()) then
		menu:AddOption("Undo", function()
			self:DoUndo()
		end)
	end
	if(self:CanRedo()) then
		menu:AddOption("Redo", function()
			self:DoRedo()
		end)
	end
	if self:CanUndo() or self:CanRedo() then
		menu:AddSpacer()
	end
end)

function LuaPadEditor:CanUndo()
	return #self.Undo > 0
end

function LuaPadEditor:DoUndo()
	if(#self.Undo > 0) then
		local undo = self.Undo[#self.Undo]
		self.Undo[#self.Undo] = nil
		
		self:SetCaret(self:SetArea(undo[1], undo[2], true, false, undo[3], undo[4]))
	end
end

function LuaPadEditor:CanRedo()
	return #self.Redo > 0
end

function LuaPadEditor:DoRedo()
	if(#self.Redo > 0) then
		local redo = self.Redo[#self.Redo]
		self.Redo[#self.Redo] = nil
		
		self:SetCaret(self:SetArea(redo[1], redo[2], false, true, redo[3], redo[4]))
	end
end