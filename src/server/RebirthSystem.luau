-- RebirthSystem: cash in 50,000 lifetime earnings at the Vault for a permanent x2 multiplier.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotConfig"))
local State = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("State"))
local Net = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net"))
local GameState = require(game.ServerScriptService:FindFirstChild("GameState", true))

local RebirthSystem = {}
local remotes

function RebirthSystem.HandleRebirth(player)
	local ok, reason = GameState.CanRebirth(player)
	if not ok then
		remotes.Toast:FireClient(player, reason, Color3.fromRGB(255, 90, 90))
		return false
	end

	local state = GameState.ResetForRebirth(player)
	for _, model in ipairs(workspace.Brainrots:GetChildren()) do
		if model:GetAttribute("OwnerId") == player.UserId then model:Destroy() end
	end

	remotes.Rebirth:FireClient(player, state.rebirths, state.multiplier)
	remotes.Owned:FireClient(player, state.owned)
	remotes.Money:FireClient(player, state.money, 0, state.lifetime, state.rebirths, state.multiplier, state.capacity)
	remotes.Toast:FireClient(player, "REBIRTH " .. state.rebirths .. " - income x" .. state.multiplier .. " FOREVER", Color3.fromRGB(255, 220, 90))
	return true
end

function RebirthSystem.Start()
	remotes = Net.CreateRemotes()
	remotes.Rebirth.OnServerEvent:Connect(RebirthSystem.HandleRebirth)
end

return RebirthSystem
