-- Net: remote names and the create/wait helpers shared by server and client.
-- The server creates the Remotes folder at boot; the client waits for it.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = {}

Net.Events = {
	Purchase = "Purchase",
	Owned = "Owned",
	Money = "Money",
	Tide = "Tide",
	Raid = "Raid",
	Rebirth = "Rebirth",
	Upgrade = "Upgrade",
	Toast = "Toast",
	Lock = "Lock",
}

local cached

function Net.CreateRemotes()
	if cached then return cached end
	local folder = ReplicatedStorage:FindFirstChild("Remotes")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Remotes"
		folder.Parent = ReplicatedStorage
	end
	cached = {}
	for key, name in pairs(Net.Events) do
		local remote = folder:FindFirstChild(name)
		if not remote then
			remote = Instance.new("RemoteEvent")
			remote.Name = name
			remote.Parent = folder
		end
		cached[key] = remote
	end
	return cached
end

function Net.GetRemotes()
	if cached then return cached end
	local folder = ReplicatedStorage:WaitForChild("Remotes", 15)
	if not folder then return nil end
	cached = {}
	for key, name in pairs(Net.Events) do
		cached[key] = folder:WaitForChild(name, 15)
	end
	return cached
end

return Net
