import("CoreLibs/graphics")
import("CoreLibs/sprites")

local gfx = playdate.graphics
local spr = gfx.sprite
local sound = playdate.sound

-- Variables for our sprites
local fishingHookSprite = nil
local underwaterBackroundSprite = nil
local aboveWaterBackroundSprite = nil

-- Sound

--Fish
local fishSprite = nil
local fishHooked = nil
local fishPreviouslyHooked = nil

-- variables for crank pos
local crankChange = 0

-- location
local aboveWater = false
local underWater = true

-- stats
local balance = 0

-- fish raritys
Fishys = {
	Cod = { probability = 50 / 100, imgPath = "assets/Fish/Common-Cod", sellGifPath = "assets/Animations/animationCOD", priceMin = "1", priceMax = "6" }, --Common
	Nemo = { probability = 20 / 100, imgPath = "assets/Fish/Rare-Nemo", sellGifPath = "", priceMin = "4", priceMax = "12" }, --Rare
	Pufferfish = { probability = 15 / 100, imgPath = "assets/Fish/Epic-Pufferfish", sellGifPath = "", priceMin = "10", priceMax = "18" }, --Epic
	Octopus = { probability = 8 / 100, imgPath = "assets/Fish/Legendary-Octopus", sellGifPath = "", priceMin = "16", priceMax = "25" }, --Legendary
	Angler = { probability = 4 / 100, imgPath = "assets/Fish/Mythical-Angler", sellGifPath = "", priceMin = "23", priceMax = "31" }, --Mythical
	Jellyfish = { probability = 2 / 100, imgPath = "assets/Fish/Insane-Jellyfish", sellGifPath = "", priceMin = "29", priceMax = "37" }, --Insane
	Shark = { probability = 10000 / 1000000, imgPath = "assets/Fish/Unknown-Shark", sellGifPath = "", priceMin = "35", priceMax = "43" }, --Unknown
	SpongeBOB = { probability = 1 / 1000000, imgPath = "assets/Fish/Unknown-Shark", sellGifPath = "", priceMin = "100000", priceMax = "1000000" }, --Unknown
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
		fishSprite.name = fishName
		--add collission
		fishSprite:setCollideRect(0, 0, fishSprite:getSize())
		fishSprite.collisionResponse = spr.kCollisionTypeOverlap
		fishSprite:setGroups(2)
		fishSprite:setCollidesWithGroups(1)
		--move to random spawn point
		local rndmX = math.random(50, 350)
		local rndmY = math.random(220, 2350)
		fishSprite:moveWithCollisions(rndmX, rndmY)
		--give and save random speed
		fishSprite.speedX = math.random(2, 3)
		fishSprite.speed = fishSprite.speedX
		--flip the image to make it face the correct way
		fishSprite:setImageFlip(gfx.kImageFlippedX)
		--coinflip fish direction
		local direction = math.random()
		if direction > 0.5 then
			fishSprite.speedX = -fishSprite.speedX
			fishSprite:setImageFlip(gfx.kImageUnflipped)
			
		end

		fishSprite:add()
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
			if fish == fishPreviouslyHooked then
				return
			else
				fishHooked = fish
				fishHooked.speedX = 0
				fishHooked:setRotation(90)
				fishHooked:setCollideRect(0, 0, fishHooked:getSize())
				return
			end
		end
	end
end

function setupGame()
	gfx.clear()

	if aboveWater == true then
		fishData = Fishys[fishHooked.name]
		print(fishData.sellGifPath)
		local sellAnimationImgTbl = gfx.imagetable.new(fishData.sellGifPath)
		local sellAnimation = gfx.animation.loop.new(sellAnimationImgTbl)
	end

	if underWater == true then
		-- Load images
		local underWaterBackround = gfx.image.new("assets/FishyFishyUnderwater")
		local fishingHook = gfx.image.new("assets/fishhook2")

		-- load and play music/sounds
		local underwaterMusic = sound.fileplayer.new("assets/Audio/underwaterMusic")
		local bubblesSound = sound.fileplayer.new("assets/Audio/bubbles")
		underwaterMusic:play()
		bubblesSound:setVolume(0.75)
		bubblesSound:play()

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

function buttonCheck()
    if playdate.buttonJustPressed("A") then
		fishHooked.speedX = fishHooked.speed
		fishHooked:setRotation(0)
		fishHooked:setCollideRect(0, 0, fishHooked:getSize())
		fishPreviouslyHooked = fishHooked
		fishHooked = nil
		print("fish off")
		--wait untill not colliding
		
    end
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
		if fishHooked then
			fishHooked:moveWithCollisions(fishingHookSprite.x, 187.5)
			buttonCheck()
		else
			collissionCheck()
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
					if fish == fishPreviouslyHooked then
						fishPreviouslyHooked = nil
					end
				elseif fish.x < 50 then
					fish.speedX = -fish.speedX
					fish:setImageFlip(gfx.kImageFlippedX)
					if fish == fishPreviouslyHooked then
						fishPreviouslyHooked = nil
					end
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
					if fish == fishPreviouslyHooked then
						fishPreviouslyHooked = nil
					end
				elseif fish.x < 50 then
					fish.speedX = -fish.speedX
					fish:setImageFlip(gfx.kImageFlippedX)
					if fish == fishPreviouslyHooked then
						fishPreviouslyHooked = nil
					end
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
					if fish == fishPreviouslyHooked then
						fishPreviouslyHooked = nil
					end
				elseif fish.x < 50 then
					fish.speedX = -fish.speedX
					fish:setImageFlip(gfx.kImageFlippedX)
					if fish == fishPreviouslyHooked then
						fishPreviouslyHooked = nil
					end
				end
			end
		end

		-- checks for selling
		if underwaterBackroundSprite.y >= 1199 and fishHooked then
			local fishData = Fishys[fishHooked.name]
			local sellPrice = math.random(fishData.priceMin, fishData.priceMax)
			print(sellPrice)
			underWater = false
			aboveWater = true
			setupGame()
		end

	end

	-- Update all sprites
	gfx.sprite.update()
end
-- Start the game
setupGame()
