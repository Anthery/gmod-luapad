--[[

local function FindPlys(pattern)
	pattern = pattern:Replace("*", ".-")
	local plys = {}
	for _,ply in pairs(player.GetAll()) do
		if ply:Nick():match(pattern) then
			table.insert(plys, ply)
		end
	end
	return plys
end

local function RunClCode(code)
	local func = CompileString( code, "TestCode", false )
	if type(func) == "function" then
		local env = {
			me = LocalPlayer(),
			plys = FindPlys
		}
		setmetatable(env, {__index = _G})
		setfenv(func, env)
		MsgN("== EXECUTING CODE ==")
		local time = RealTime()
		func()
		MsgN("== CODE EXECUTION FINISHED ==")
		MsgN("== Execution Time: " .. tostring(RealTime() - time) .. " ==")
	else
		MsgN("Error: ", func)
	end
end

LuaPadEditor:AddHook("SetupKeys", "ExecCode", function(self)
	self:SetupKey("Run Code", "CTRL S", function(self)
		RunClCode(self:GetValue())
	end)
end)
]]