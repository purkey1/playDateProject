import("CoreLibs/graphics")
import("CoreLibs/sprites")

local gfx = playdate.graphics
local spr = gfx.sprite

-- Variables for our sprites
local fishingHookSprite = nil
local backroundSprite = nil

--Fish
local fishSprite = nil
local codSprite = nil
local nemoSprite = nil
local epicSprite = nil
local octopusSprite = nil
local anglerSprite = nil
local insaneSprite = nil
local unknownSprite = nil

-- variables for crank pos
local crankChange = 0
local isDocked = true

-- fish raritys
Fishys = {
	Cod = { probability = 50 / 100, imgPath = "assets/Fish/Common-Cod" }, --Common
	Nemo = { probability = 20 / 100, imgPath = "assets/Fish/Rare-Nemo" }, --Rare
	Pufferfish = { probability = 15 / 100, imgPath = "assets/Fish/Epic-Pufferfish" }, --Epic
	Octopus = { probability = 8 / 100, imgPath = "assets/Fish/Legendary-Octopus" }, --Legendary
	Angler = { probability = 4 / 100, imgPath = "assets/Fish/Mythical-Angler" }, --Mythical
	Jellyfish = { probability = 2 / 100, imgPath = "assets/Fish/Insane-Jellyfish" }, --Insane
	Shark = { probability = 1 / 100, imgPath = "assets/Fish/Unknown-Shark" }, --Unknown
}

local spawnedFish = {}

function getRandomFish()
	local chance = math.random()
	local total = 0
	for fish, data in pairs(Fishys) do
		total += data.probability
		if chance <= total then
			return fish
		end
	end
end

function spawnFish(count)
	for num = 1, count do
		local fishName = getRandomFish()
		local fishData = Fishys[fishName]
		local fishImg = gfx.image.new(fishData.imgPath)
		fishSprite = spr.new(fishImg)
		local rndmX = math.random(50, 350)
		local rndmY = math.random(220, 2350)
		fishSprite:moveTo(rndmX, rndmY)
		fishSprite:add()
		table.insert(spawnedFish, fishSprite)
	end
end

function setupGame()
	-- Load images
	local backround = gfx.image.new("assets/FishyFishyUnderwater")
	local fishingHook = gfx.image.new("assets/fishhook2")

	-- Check if images loaded
	if not fishingHook or not backround then
		print("ERROR: Could not load images!")
		return
	end

	-- Create sprites from images
	fishingHookSprite = spr.new(fishingHook)
	backroundSprite = spr.new(backround)

	-- Position sprites
	fishingHookSprite:moveTo(200, 50)
	backroundSprite:moveTo(200, 1200)

	-- Add sprites to display list (makes them visible)
	fishingHookSprite:add()
	backroundSprite:add()

	local randomFishcount = math.random(10, 20)
	spawnFish(randomFishcount)
	print("Spawned: " .. randomFishcount .. " fish")
	print("all sprites loaded")
end

function playdate.update()
	-- Clear screen
	gfx.clear()

	-- Move hook with arrow keys
	if playdate.buttonIsPressed(playdate.kButtonRight) then
		fishingHookSprite:moveBy(5, 0)
	elseif playdate.buttonIsPressed(playdate.kButtonLeft) then
		fishingHookSprite:moveBy(-5, 0)
	end

	--Limits hook going off screen
	if fishingHookSprite.x >= 375 then
		fishingHookSprite:moveTo(374, 50)
	elseif fishingHookSprite.x <= 25 then
		fishingHookSprite:moveTo(26, 50)
	end

	--get crank pos
	crankChange = playdate.getCrankChange()
	local reeling = crankChange / 2

	-- scroll backround with crank
	backroundSprite:moveBy(0, -2 + reeling)


	--limits scrolling backround too far and moves fish with backround
	if backroundSprite.y >= 1200 then
		backroundSprite:moveTo(200, 1199)
		for _, fish in pairs(spawnedFish) do
			fish:moveBy(0, -2 + reeling)

			local randomSpeed = math.random(1,4)
			local currentPosX = fish.x
			if currentPosX > 350 or currentPosX < 50 then
				randomSpeed = -randomSpeed
			end
			fish:moveBy(randomSpeed, 0)
			
		end
	elseif backroundSprite.y <= -960 then
		backroundSprite:moveTo(200, -959)
		for _, fish in pairs(spawnedFish) do
			fish:moveBy(0, -2 + reeling)

			local randomSpeed = math.random(1,4)
			local currentPosX = fish.x
			if currentPosX > 350 or currentPosX < 50 then
				randomSpeed = -randomSpeed
			end
			fish:moveBy(randomSpeed, 0)
			
		end
	else
		for _, fish in pairs(spawnedFish) do
			fish:moveBy(0, -2 + reeling)

			local randomSpeed = math.random(1,4)
			local currentPosX = fish.x
			if currentPosX > 350 or currentPosX < 50 then
				randomSpeed = -randomSpeed
			end
			fish:moveBy(randomSpeed, 0)

		end
	end

	-- Update all sprites
	gfx.sprite.update()
end

-- Start the game
setupGame()
