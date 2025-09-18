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
	Nemo = { probability = 20 / 100, imgPath = "assets/Fish/Common-Cod" }, --Rare
	Epic = { probability = 15 / 100, imgPath = "assets/Fish/Common-Cod" }, --Epic
	Octopus = { probability = 8 / 100, imgPath = "assets/Fish/Common-Cod" }, --Legendary
	Angler = { probability = 4 / 100, imgPath = "assets/Fish/Common-Cod" }, --Mythical
	Insane = { probability = 2 / 100, imgPath = "assets/Fish/Common-Cod" }, --Insane
	Unknown = { probability = 1 / 100, imgPath = "assets/Fish/Common-Cod" }, --Unknown
}

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

local spawnedFish = {}

function spawnFish(count)
	for num = 1, count do
		local fishName = getRandomFish()
		print(fishName)
		local fishData = Fishys[fishName]
		local fishImg = gfx.image.new(fishData.imgPath)
		fishSprite = spr.new(fishImg)
		local rndmX = math.random(25, 375)
		local rndmY = math.random(120, 1150)
		fishSprite:moveTo(rndmX, rndmY)
		fishSprite:add()
		print("Fish spawned")
	end
end

function setupGame()
	-- Load images
	local backround = gfx.image.new("assets/FishyFishyUnderwater")
	local fishingHook = gfx.image.new("assets/fishhook2")

	local Cod = gfx.image.new("assets/Fish/Common-Cod")
	local Nemo = gfx.image.new("assets/Fish/Rare-Nemo")
	local Epic = gfx.image.new("assets/Fish/Epic-")
	local Octopus = gfx.image.new("assets/Fish/Legendary-Octopus")
	local Angler = gfx.image.new("assets/Fish/Mythical-Angler")
	local Insane = gfx.image.new("assets/Fish/Insane-")
	local Unknown = gfx.image.new("assets/Fish/Unknown-")

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

	local fishCount = 0
	if fishCount <= 5 then
		local fish = getRandomFish()
		print(fish)
		if fish == "Cod" then
		elseif fish == "Nemo" then
		elseif fish == "Epic" then
		elseif fish == "Octopus" then
		elseif fish == "Angler" then
		elseif fish == "Insane" then
		elseif fish == "Unknown" then
		end
	end

	spawnFish(5)
	print("all sprites loaded")
end

function playdate.update()
	-- Clear screen
	gfx.clear()

	-- Move player with arrow keys
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
	backroundSprite:moveBy(0, -2)
	backroundSprite:moveBy(0, reeling)

	if backroundSprite.y >= 1200 then
		backroundSprite:moveTo(200, 1199)
	elseif backroundSprite.y <= -960 then
		backroundSprite:moveTo(200, -959)
	end

	-- Update all sprites
	gfx.sprite.update()
end

-- Start the game
setupGame()
