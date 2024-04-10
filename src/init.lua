--!strict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

type CameraConfig = {
	fov: number?,
	sensitivity: number?,

	offset: Vector3?,

	minZoom: number?,
	maxZoom: number?,
	zoomStrength: number?,
	zoomForce: number?,

	minAngle: number?,
	maxAngle: number?,
}

local Shifty = {}

function Shifty.new(camera: Camera, config: CameraConfig)
	local self = {}
	local cleanup: { RBXScriptConnection } = {}
	local player = Players.LocalPlayer

	-- Config
	local fov = config.fov or 70
	local sensitivity = config.sensitivity or 0.4

	local offset = config.offset or Vector3.new(1.5, 2, 4)

	local minZoom = config.minZoom or 0
	local maxZoom = config.maxZoom or 20
	local zoomStrength = config.zoomStrength or 4
	local zoomForce = config.zoomForce or 15

	local minAngle = config.minAngle or -80
	local maxAngle = config.maxAngle or 80

	-- State
	local enabled = false
	local justEnabled = false
	local locked = true

	local angle = Vector2.new(0, 0)
	local zoom = {
		at = minZoom,
		to = minZoom,
	}

	local function lerp(at: number, to: number, alpha: number)
		return at + (to - at) * math.clamp(alpha, 0, 1)
	end

	local function setDefaultCameraZoom(to: number)
		-- Why isn't there a property for this?
		--[[local current = { player.CameraMinZoomDistance, player.CameraMaxZoomDistance }
		camera.CFrame = CFrame.lookAt(camera.Focus.Position - camera.CFrame.LookVector * to, camera.Focus.Position)

		player.CameraMinZoomDistance = to
		player.CameraMaxZoomDistance = to

		task.defer(function()
			player.CameraMinZoomDistance = current[1]
			player.CameraMaxZoomDistance = current[2]
		end)--]]
	end

	local function getCameraInfo()
		local x, y = camera.CFrame:ToOrientation()
		local zoom = (camera.CFrame.Position - camera.Focus.Position).Magnitude - offset.Z

		return Vector2.new(math.deg(y), math.deg(x)), zoom
	end

	local function camStep(dt: number)
		local char = player.Character
		if not char then
			return
		end

		local pivot = char:GetPivot()
		local origin = CFrame.new(pivot.Position)
			* CFrame.Angles(0, math.rad(angle.X), 0)
			* CFrame.Angles(math.rad(angle.Y), 0, 0)

		local camPos = (origin + origin:VectorToWorldSpace(offset + Vector3.new(0, 0, zoom.at))).Position
		local camFocus = (origin + origin:VectorToWorldSpace(offset - Vector3.new(0, 0, 1))).Position

		camera.CFrame = camera.CFrame:Lerp(CFrame.lookAt(camPos, camFocus), if justEnabled then dt * 30 else 1)

		camera.CameraType = Enum.CameraType.Scriptable
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	end

	local function angleStep(dt: number)
		local delta = UserInputService:GetMouseDelta()
		angle = Vector2.new(
			(angle.X - delta.X * sensitivity) % 360,
			math.clamp(angle.Y - delta.Y * sensitivity, minAngle, maxAngle)
		)
	end

	local function zoomStep(dt: number)
		zoom.at = lerp(zoom.at, zoom.to, dt * zoomForce)
	end

	local function lockStep(dt: number)
		if not locked then
			return
		end

		local char = player.Character
		if not char then
			return
		end

		local pivot = char:GetPivot()
		local facePos = camera.CFrame.Position + camera.CFrame.LookVector * 1000
		char:PivotTo(CFrame.lookAt(pivot.Position, Vector3.new(facePos.X, pivot.Position.Y, facePos.Z)))
	end

	function self:Enable()
		local cameraStepConnection = RunService.RenderStepped:Connect(camStep)
		local angleStepConnection = RunService.RenderStepped:Connect(angleStep)
		local zoomStepConnection = RunService.Heartbeat:Connect(zoomStep)
		local lockStepConnection = RunService.Heartbeat:Connect(lockStep)

		local zoomInputConnection = UserInputService.InputChanged:Connect(function(input, processed)
			if processed then
				return
			end
			if input.UserInputType == Enum.UserInputType.MouseWheel then
				local direction = -input.Position.Z
				zoom.to = math.clamp(zoom.to + direction * zoomStrength, minZoom, maxZoom)
			end
		end)

		table.insert(cleanup, cameraStepConnection)
		table.insert(cleanup, angleStepConnection)
		table.insert(cleanup, zoomStepConnection)
		table.insert(cleanup, zoomInputConnection)
		table.insert(cleanup, lockStepConnection)

		task.delay(0.2, function()
			justEnabled = false
		end)

		local currentAngle, currentZoom = getCameraInfo()
		angle = currentAngle
		zoom = {
			at = currentZoom,
			to = currentZoom,
		}

		enabled = true
		justEnabled = true

		camera.FieldOfView = fov
		UserInputService.MouseIconEnabled = false
	end

	function self:Disable()
		for _, connection in cleanup do
			connection:Disconnect()
		end

		setDefaultCameraZoom(zoom.at + offset.Z)

		enabled = false
		camera.CameraType = Enum.CameraType.Custom
		camera.FieldOfView = 70
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
	end

	function self:Toggle()
		if enabled then
			self:Disable()
		else
			self:Enable()
		end
	end

	function self:Lock()
		locked = true
	end

	function self:Unlock()
		locked = false
	end

	function self:ToggleLock()
		locked = not locked
	end

	function self:IsEnabled()
		return enabled
	end

	return self
end

return Shifty
