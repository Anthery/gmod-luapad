LuaPadEditor:AddHook("PaintRowGutter", "ErrorChecker", function(self, row, width, height)
	if self.ErrorLine and self.ErrorLine.line == row then
		surface.DrawCircle(width+7, height+7, 5, Color(255, 0, 0))
	end
end)

LuaPadEditor:AddHook("TextChanged", "ErrorChecker", function(self, inserted, fulltext)

	local func = fulltext:len() > 0 and CompileString( fulltext, "TestCode", false ) or false

	if type(func) == "string" and not func:StartWith("Invali") then
		local line, msg = string.match(func, "%a+:(%d+):(.+)")
		self.ErrorLine = {
			line = tonumber(line),
			err = msg
		}
		self:SetStatus("Error on #" .. tostring(line) .. ": " .. msg)
		--MsgN(line, ": ", msg)
	else
		self:SetStatus("")
		self.ErrorLine = nil
	end
end)