-- Boot: bring the world up first, then the systems that use it.

local ORDER = { "WorldBuilder", "EconomySystem", "TideEvent", "RaidSystem", "RebirthSystem" }

local function findServerModule(name)
	return game.ServerScriptService:FindFirstChild(name, true)
end

for _, name in ipairs(ORDER) do
	local module = findServerModule(name)
	if not module then
		warn("[Bazaar] Missing server module: " .. name)
	else
		local ok, loaded = pcall(require, module)
		if not ok or type(loaded) ~= "table" or type(loaded.Start) ~= "function" then
			warn("[Bazaar] Cannot start " .. name .. ": " .. tostring(loaded))
		else
			local started, err = pcall(loaded.Start)
			if not started then warn("[Bazaar] " .. name .. " failed: " .. tostring(err)) end
		end
	end
end

print("[Bazaar] All server systems online.")
