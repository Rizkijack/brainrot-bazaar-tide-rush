-- BrainrotVisuals.client: bob, spin, mutation sparkles and rarity tags for every summoned citizen.

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotConfig"))

local folder = workspace:WaitForChild("Brainrots", 15)
if not folder then
	warn("[Bazaar] No Brainrots folder; visuals disabled.")
	return
end

local function addSparkle(root, mutation)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "Mutation Sparkle"
	emitter.Rate = mutation == "CORRUPTED" and 26 or 14
	emitter.Lifetime = NumberRange.new(1.5)
	emitter.Speed = NumberRange.new(2, 6)
	emitter.Size = NumberSequence.new(0.7)
	emitter.Color = ColorSequence.new(Config.MutationColor(mutation))
	emitter.Parent = root
end

local function addRarityTag(root, model)
	local bg = Instance.new("BillboardGui")
	bg.Name = "RarityLabel"
	bg.Size = UDim2.new(0, 300, 0, 52)
	bg.StudsOffset = Vector3.new(0, 6.4, 0)
	bg.AlwaysOnTop = true
	bg.MaxDistance = 220
	bg.Parent = root
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 0.4
	label.BackgroundColor3 = Color3.fromRGB(12, 6, 28)
	label.Text = tostring(model:GetAttribute("Mutation")) .. " " .. tostring(model:GetAttribute("Rarity"))
	label.TextColor3 = Config.RarityColor(model:GetAttribute("Rarity"))
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = bg
end

RunService.RenderStepped:Connect(function()
	local t = tick()
	for _, model in ipairs(folder:GetChildren()) do
		if model:IsA("Model") then
			local root = model.PrimaryPart
			local hx = model:GetAttribute("HomeX")
			local hy = model:GetAttribute("HomeY")
			local hz = model:GetAttribute("HomeZ")
			if root and hx and hy and hz then
				local spin = model:GetAttribute("Spin") or 0.8
				root.CFrame = CFrame.new(hx, hy + math.sin(t * 2 + hx) * 0.5, hz) * CFrame.Angles(0, t * spin, 0)

				local mutation = model:GetAttribute("Mutation")
				if mutation and mutation ~= "Normal" and not root:FindFirstChild("Mutation Sparkle") then
					addSparkle(root, mutation)
				end
				if not root:FindFirstChild("RarityLabel") then addRarityTag(root, model) end
			end
		end
	end
end)

print("[Bazaar] Brainrot visuals online.")
