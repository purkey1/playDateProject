import("CoreLibs/graphics")
import("CoreLibs/sprites")

local gfx = playdate.graphics
local spr = gfx.sprite

-- Variables for our sprites
local fishingHookSprite = nil
local underwaterBackroundSprite = nil

--Fish
local fishSprite = nil
local fishHooked = nil

-- variables for crank pos
local crankChange = 0
local currentRotation = 90

-- out of the water
local aboveWater = false
local underWater = true
local balance = 0

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
			fishHooked = fish
		end
	end
end

function setupGame()
	if aboveWater == true then
		local aboveWaterBackround = gfx.image.new("assets/FishyFishyAbovewater")
	end
	
	if underWater == true then
		-- Load images
		local underWaterBackround = gfx.image.new("assets/FishyFishyUnderwater")
		local fishingHook = gfx.image.new("assets/fishhook2")

		-- Create sprites from images
		fishingHookSprite = spr.new(fishingHook)
		local width, height = fishingHookSprite:getSize()
		fishingHookSprite:setCollideRect(2.5, 187.5, width-5, 50)
		fishingHookSprite.collisionResponse = spr.kCollisionTypeOverlap
		fishingHookSprite:setGroups(1)
		fishingHookSprite:setCollidesWithGroups(2)
		underwaterBackroundSprite = spr.new(underWaterBackround)

		-- Position sprites
		fishingHookSprite:moveWithCollisions(200, 50)
		underwaterBackroundSprite:moveTo(200, 1200)

		-- Add sprites to display list (makes them visible)
		fishingHookSprite:add()
		underwaterBackroundSprite:add()

		local randomFishcount = math.random(10, 20)
		spawnFish(randomFishcount)
		print("Spawned: " .. randomFishcount .. " fish")
	end
	print("all sprites loaded")
end

function playdate.update()
	-- Clear screen
	gfx.clear()

	--get crank pos
	crankChange = playdate.getCrankChange()
	local reeling = crankChange / 2

	if underWater == true then
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
		if fishHooked then
			fishHooked:moveWithCollisions(fishingHookSprite.x, 187.5)
			fishHooked.speedX = 0
			fishHooked:setRotation(90)
			fishHooked:setCollideRect(0, 0, fishHooked:getSize())
		end
		

		-- scroll underwaterbackround with crank
		local bgY1 = underwaterBackroundSprite.y
		underwaterBackroundSprite:moveBy(0, -2 + reeling)
		local bgY2 = underwaterBackroundSprite.y - bgY1

		--limits scrolling underwaterbackround too far and moves fish with underwaterbackround
		if underwaterBackroundSprite.y >= 1200 then
			underwaterBackroundSprite:moveTo(200, 1199)
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
		elseif underwaterBackroundSprite.y <= -960 then
			underwaterBackroundSprite:moveTo(200, -959)
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
				if fishHooked ~= fish then
				--Keep fish with underwaterBackroundSprite
				fish:moveBy(0, bgY2)
				end

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
	end

	-- Update all sprites
	gfx.sprite.update()
end
-- Start the game
setupGame()
