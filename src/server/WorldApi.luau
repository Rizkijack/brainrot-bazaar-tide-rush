-- WorldApi: a tiny bridge so Scripts can ask the world builder for runtime instances.
-- WorldBuilder replaces these no-ops when it boots.

local WorldApi = {}

function WorldApi.SpawnBrainrotModel(_def, _mutation, _pedestalIndex, _ownerId)
	warn("WorldBuilder has not booted yet")
	return nil
end

function WorldApi.RemoveBrainrot(_id) end
function WorldApi.FlashShield(_on) end
function WorldApi.PedestalCFrame(index)
	return CFrame.new(0, 0, 0) + Vector3.new(0, 0, (index or 1) * 3)
end

return WorldApi
