import("CoreLibs/graphics")
import("CoreLibs/sprites")

local gfx = playdate.graphics
local spr = gfx.sprite

-- Variables for our sprites
local fishingHookSprite = nil
local backroundSprite = nil

--Fish
local fishSprite = nil
local fishHooked = nil

-- variables for crank pos
local crankChange = 0
local currentRotation = 90

-- fish raritys
Fishys = {
	Cod = { probability = 50 / 100, imgPath = "assets/Fish/Common-Cod" }, --Common
	Nemo = { probability = 20 / 100, imgPath = "assets/Fish/Rare-Nemo" }, --Rare
	Pufferfish = { probability = 15 / 100, imgPath = "assets/Fish/Epic-Pufferfish" }, --Epic
	Octopus = { probability = 8 / 100, imgPath = "assets/Fish/Legendary-Octopus" }, --Legendary
	Angler = { probability = 4 / 100, imgPath = "assets/Fish/Mythical-Angler" }, --Mythical
	Jellyfish = { probability = 2 / 100, imgPath = "assets/Fish/Insane-Jellyfish" }, --Insane
	Shark = { probability = 10000 / 1000000, imgPath = "assets/Fish/Unknown-Shark" }, --Unknown
	SpongeBOB = { probability = 1 / 1000000, imgPath = "assets/Fish/Unknown-Shark" }, --Unknown
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
		--get fish info
		local fishName = getRandomFish()
		local fishData = Fishys[fishName]
		local fishImg = gfx.image.new(fishData.imgPath)
		fishSprite = spr.new(fishImg)
		--add collission
		fishSprite:setCollideRect(0, 0, fishSprite:getSize())
		fishSprite.collisionResponse = spr.kCollisionTypeOverlap
		fishSprite:setGroups(2)
		fishSprite:setCollidesWithGroups(1)
		--move to random spawn point
		local rndmX = math.random(50, 350)
		local rndmY = math.random(220, 2350)
		fishSprite:moveWithCollisions(rndmX, rndmY)
		--give random speed
		fishSprite.speedX = math.random(1, 3)
		--flip the image to make it face the correct way
		fishSprite:setImageFlip(gfx.kImageFlippedX)
		--coinflip fish direction
		local direction = math.random()
		if direction > 0.5 then
			fishSprite.speedX = -fishSprite.speedX
			fishSprite:setImageFlip(gfx.kImageUnflipped)
		end

		fishSprite:add()
		print(fishName)
		table.insert(spawnedFish, fishSprite)
	end
end

function collissionCheck()
	if fishHooked then
		return
	end
    for _, fish in pairs(spawnedFish) do
		--local overlappingSprites = spr.allOverlappingSprites()
		local overlappingSprites = fish:overlappingSprites()
		
		if #overlappingSprites >= 1 then
			print("fish on")
			fishHooked = fish
			fish.speedX = 0
			print(fish)
			if fish == Fishys.Cod  then
				fish:setRotation(90)
			end
		end
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
	local width, height = fishingHookSprite:getSize()
	fishingHookSprite:setCollideRect(2.5, 187.5, width-5, 50)
	fishingHookSprite.collisionResponse = spr.kCollisionTypeOverlap
	fishingHookSprite:setGroups(1)
	fishingHookSprite:setCollidesWithGroups(2)
	backroundSprite = spr.new(backround)

	-- Position sprites
	fishingHookSprite:moveWithCollisions(200, 50)
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
		fishingHookSprite:moveWithCollisions(fishingHookSprite.x + 5, 50)
	elseif playdate.buttonIsPressed(playdate.kButtonLeft) then
		fishingHookSprite:moveWithCollisions(fishingHookSprite.x - 5, 50)
	end

	--Limits hook going off screen
	if fishingHookSprite.x >= 375 then
		fishingHookSprite:moveWithCollisions(374, 50)
	elseif fishingHookSprite.x <= 25 then
		fishingHookSprite:moveWithCollisions(26, 50)
	end

	--Check for collission with fishingHookSprite
	collissionCheck()
	local width, height = fishingHookSprite:getSize()
	if fishHooked then
		fishHooked:moveWithCollisions(fishingHookSprite.x, 187.5)
	end
	--get crank pos
	crankChange = playdate.getCrankChange()
	local reeling = crankChange / 2

	-- scroll backround with crank
	local bgY1 = backroundSprite.y
	backroundSprite:moveBy(0, -2 + reeling)
	local bgY2 = backroundSprite.y - bgY1
	


	--limits scrolling backround too far and moves fish with backround
	if backroundSprite.y >= 1200 then
		backroundSprite:moveTo(200, 1199)
		for _, fish in pairs(spawnedFish) do

			-- Fish swimming left and right with facing the correct direction
			fish:moveBy(fish.speedX, 0)
			if fish.x > 350 then
				fish.speedX = -fish.speedX
				fish:setImageFlip(gfx.kImageUnflipped)
			elseif fish.x < 50 then
				fish.speedX = -fish.speedX
				fish:setImageFlip(gfx.kImageFlippedX)
			end
		end
	elseif backroundSprite.y <= -960 then
		backroundSprite:moveTo(200, -959)
		for _, fish in pairs(spawnedFish) do

			-- Fish swimming left and right with facing the correct direction
			fish:moveBy(fish.speedX, 0)
			if fish.x > 350 then
				fish.speedX = -fish.speedX
				fish:setImageFlip(gfx.kImageUnflipped)
			elseif fish.x < 50 then
				fish.speedX = -fish.speedX
				fish:setImageFlip(gfx.kImageFlippedX)
			end
		end
	else
		for _, fish in pairs(spawnedFish) do
			--Keep fish with backroundSprite
			fish:moveBy(0, bgY2)

			-- Fish swimming left and right with facing the correct direction
			fish:moveBy(fish.speedX, 0)
			if fish.x > 350 then
				fish.speedX = -fish.speedX
				fish:setImageFlip(gfx.kImageUnflipped)
			elseif fish.x < 50 then
				fish.speedX = -fish.speedX
				fish:setImageFlip(gfx.kImageFlippedX)
			end
		end
	end

	-- Update all sprites
	gfx.sprite.update()
end
-- Start the game
setupGame()
