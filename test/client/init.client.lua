--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shifty = require(ReplicatedStorage.Packages.Shifty)

local camera = workspace.CurrentCamera

local function runTest(label: string, test: () -> ())
	local success, err = pcall(function()
		test()
	end)

	if success then
		print(`Test "{label}" passed`)
	else
		error(`Test "{label}" failed. \n{err}`)
	end
end

--[[runTest("Camera toggling", function()
	local cam = Shifty.new(camera, {})
	cam:Toggle()
	assert(cam:IsEnabled() == true)
	cam:Toggle()
	assert(cam:IsEnabled() == false)
end)--]]

runTest("Main", function()
	local cam = Shifty.new(camera, {})
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end

		if input.KeyCode == Enum.KeyCode.LeftShift then
			cam:Toggle()
		end
	end)
end)
