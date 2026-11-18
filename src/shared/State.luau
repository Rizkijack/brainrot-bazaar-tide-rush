-- State: the schema and enums for the one per-player state store kept by GameState.
-- Everything in a player's economy lives in this shape; nothing is duplicated on the client.

local State = {}

State.Schema = {
	money = "number",
	lifetime = "number",
	owned = "array<brainrot>",
	rebirths = "number",
	multiplier = "number",
	capacity = "number",
	lockUntil = "number",
	lastLock = "number",
	incomeLevel = "number",
	capacityLevel = "number",
}

State.TidePhase = {
	Idle = "Idle",
	Warning = "Warning",
	Sweeping = "Sweeping",
}

State.RaidState = {
	Idle = "Idle",
	Active = "Active",
}

State.UpgradeKind = {
	Income = "income",
	Capacity = "capacity",
}

State.START_MONEY = 100
State.START_CAPACITY = 8
State.REBIRTH_LIFETIME = 50000
State.LOCK_DURATION = 10
State.LOCK_COOLDOWN = 20

function State.NewPlayerState()
	return {
		money = State.START_MONEY,
		lifetime = 0,
		owned = {},
		rebirths = 0,
		multiplier = 1,
		capacity = State.START_CAPACITY,
		lockUntil = 0,
		lastLock = 0,
		incomeLevel = 0,
		capacityLevel = 0,
	}
end

return State
