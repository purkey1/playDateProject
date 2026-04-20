import("CoreLibs/graphics")
import("CoreLibs/sprites")
import "CoreLibs/timer"

local animation = playdate.graphics.animation
local gfx = playdate.graphics
local spr = gfx.sprite
local sound = playdate.sound

--settings
local pauseGame = false

-- Timers
local buttonCheckTimer = nil
local timeLimit = nil
local swimAway = nil

-- Variables for our sprites
local fishingHookSprite = nil
local underwaterBackroundSprite = nil
local aboveWaterBackroundSprite = nil
local sellAnimationSprite = nil
local balanceTextSprite = nil
local buttonSprite = nil

-- Sound
local underwaterMusic = nil
local bubblesSound = nil

--Fish
local fishSprite = nil
local fishHooked = nil
local fishPreviouslyHooked = nil

-- variables for crank pos
local crankChange = 0

-- location
local aboveWater = false
local underWater = true

--transitions
local fadeAnimationDone = true
local fadeAnimationIndex = 1
local fadeAnimationSection = 1

-- selling Fish Animation
local sellAnimationDone = false
local coinAnimationDone = false
local sellAnimationIndex = 1
local soldFish = nil

-- selling
local sellingDone = false
local blanceIndex = 0

-- stats
local balance = 0

-- catch fish minigame
local timesCompleated = 0
local correctButtonData = nil
local correctButtonPressed = false
local currentMinigameFish = nil

Buttons = {
	Up = { rotation = 0, name = "Up" },
	Down = { rotation = 180, name = "Down" },
	Left = { rotation = -90, name = "Left" },
	Right = { rotation = 90, name = "Right" },
}


-- fish raritys
Fishys = {
	Cod = { probability = 50 / 100, imgPath = "assets/Fish/Common-Cod", sellGifPath = "assets/Animations/cod", priceMin = "1", priceMax = "6" },                      --Common
	Clownfish = { probability = 20 / 100, imgPath = "assets/Fish/Rare-Clownfish", sellGifPath = "assets/Animations/clownfish", priceMin = "4", priceMax = "12" },     --Rare
	Pufferfish = { probability = 15 / 100, imgPath = "assets/Fish/Epic-Pufferfish", sellGifPath = "assets/Animations/pufferfish", priceMin = "10", priceMax = "18" }, --Epic
	Octopus = { probability = 8 / 100, imgPath = "assets/Fish/Legendary-Octopus", sellGifPath = "assets/Animations/octopus", priceMin = "16", priceMax = "25" },      --Legendary
	Angler = { probability = 4 / 100, imgPath = "assets/Fish/Mythical-Angler", sellGifPath = "assets/Animations/angler", priceMin = "23", priceMax = "31" },          --Mythical
	Jellyfish = { probability = 2 / 100, imgPath = "assets/Fish/Insane-Jellyfish", sellGifPath = "assets/Animations/jellyfish", priceMin = "29", priceMax = "37" },   --Insane
	Shark = { probability = 10000 / 1000000, imgPath = "assets/Fish/Unknown-Shark", sellGifPath = "assets/Animations/shark", priceMin = "35", priceMax = "43" },      --Unknown
	SpongeBOB = { probability = 1 / 1000000, imgPath = "assets/Fish/Unknown-Shark", sellGifPath = "", priceMin = "100000", priceMax = "1000000" },                    --Unknown
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
		--set center
		local width, height = fishSprite:getSize()
		fishSprite:setCenter(0.5, 0.5)
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
		if fishName == "SpongeBOB" then
			print("SpongeBOB has spawned")
		end
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
				if currentMinigameFish == nil then
					currentMinigameFish = fish
					catchFishMiniGame(fish, 100)
				end
			end
		end
	end
end

function catchFishMiniGame(fish, difficulty)
	pauseGame = true

	
	
	ButtonOptions = {
		"Up",
		"Down",
		"Left",
		"Right",
	}

		--Gets random button from buttons list
		local correctButton = ButtonOptions[math.random(1, 4)]
		correctButtonData = Buttons[correctButton]
		--makes the image and sprite
		local buttonImage = gfx.image.new("assets/Misc/DpadButton")
		buttonSprite = spr.new(buttonImage)
		buttonSprite:add()
		buttonSprite:setRotation(correctButtonData.rotation)

			--gets an offset that is max 25 pixles and min 5 pixles away
			local randomXoffset = 0
			local randomYoffset = 0

			local width, height = fish:getSize()
			local halfWidth = width / 2
			local halfHeight = height / 2

			randomXoffset = math.random(40)
			randomYoffset = math.random(40)

			if randomXoffset < halfWidth then
				randomXoffset = halfWidth + 25
			end

			if randomYoffset < halfHeight then
				randomXoffset = halfWidth + 25
			end

			local xOffset = fish.x + randomXoffset
			local yOffset = fish.y + randomYoffset

			local direction = math.random(4)

			if xOffset > 375 then
				direction = math.random(3, 4)
				print("Moved 1")
			elseif xOffset < 25 then
				direction = math.random(2)
				print("Moved 2")
			end

			if yOffset > 215 then
				direction = 1
				print("Moved 3")
			elseif yOffset < 25 then
				direction = 3
				print("Moved 4")
			end

		--moves the sprite using the offset with random posotive or negative
		if direction == 1 then
			buttonSprite:moveTo(fish.x + randomXoffset, fish.y + randomYoffset)
		elseif direction == 2 then
			buttonSprite:moveTo(fish.x + randomXoffset, fish.y - randomYoffset)
		elseif direction == 3 then
			buttonSprite:moveTo(fish.x - randomXoffset, fish.y - randomYoffset)
		else
			buttonSprite:moveTo(fish.x - randomXoffset, fish.y + randomYoffset)
		end

		-- Wait for the correct button to be pressed before moving only

		timeLimit = playdate.timer.new(5000, function()
				timeLimit = nil
				buttonCheckTimer:remove()
				buttonCheckTimer = nil
				buttonSprite:remove()
				buttonSprite = nil
				currentMinigameFish = nil
				print("time ran out")
				--local width, height = fish:getSize()
				swimAway = playdate.timer.keyRepeatTimerWithDelay(20, 20, function ()
					local width, height = fish:getSize()
					if swimAway then
					if width <= 0 then
						fish:remove()
						swimAway:remove()
						swimAway = nil
						pauseGame = false
					elseif height <= 0 then
						fish:remove()
						swimAway:remove()
						swimAway = nil
						pauseGame = false
					end
				end
					fish:setSize(width - 4, height - 4)
					fish:setCollideRect(0, 0, fish:getSize())
				end)
		end)

		local function waitForButton()

			if playdate.buttonJustPressed(string.lower(correctButtonData.name)) then
				if buttonCheckTimer then
					buttonCheckTimer:remove()
				end
				if timeLimit then
					timeLimit:remove()
				end
				correctButtonPressed = true
				buttonCheckTimer = nil
				timeLimit = nil
				timesCompleated += 1

				buttonSprite:remove()
				buttonSprite = nil

				local minigameDone = false
				if timesCompleated == difficulty then
					if minigameDone == false then
						minigameDone = true
						--finish minigame 
						
						currentMinigameFish = nil
						pauseGame = false
						timesCompleated = 0
						fishHooked = fish
						fishHooked.speedX = 0
						if fish.name ~= "Jellyfish" then
							fishHooked:setRotation(90)
						end
						fishHooked:setCollideRect(0, 0, fishHooked:getSize())
					end
				else
					catchFishMiniGame(fish, difficulty)
				end
				return
			end
		end

		buttonCheckTimer = playdate.timer.keyRepeatTimerWithDelay(2, 2, waitForButton)
end

function fadeAnimation()
	playdate.display.setRefreshRate(10)
	gfx.setColor(gfx.kColorBlack)
	gfx.sprite.removeAll()
	if aboveWater == true then
			if fadeAnimationSection == 1 then
				-- when fadeAnimationSection is equal to 1 it goes through this 
				--untill the fadeAnimationIndex is less than 0 once it is
				--it changes fadeAnimationSection equal to 2, which skips the first part and runs the else statement below
				local underwaterBackround = gfx.image.new("assets/Backrounds/FishyFishyUnderwater")
				underwaterBackroundSprite = spr.new(underwaterBackround)
				underwaterBackroundSprite:moveTo(200, 1200)
				underwaterBackroundSprite:add()
				gfx.setDitherPattern(fadeAnimationIndex)
				gfx.fillRect(0, 0, 400, 240)
				fadeAnimationIndex -= 0.09
				if fadeAnimationIndex <= 0 then
					fadeAnimationSection = 2
				end
			else
				local sellBackround = gfx.image.new("assets/Backrounds/frame1BASE")
				aboveWaterBackroundSprite = spr.new(sellBackround)
				aboveWaterBackroundSprite:moveTo(200, 120)
				aboveWaterBackroundSprite:add()
				gfx.setDitherPattern(fadeAnimationIndex)
				gfx.fillRect(0, 0, 400, 240)
				fadeAnimationIndex += 0.09
			end
	elseif underWater == true then
		if fadeAnimationSection == 1 then
			-- when fadeAnimationSection is equal to 1 it goes through this 
			--untill the fadeAnimationIndex is less than 0 once it is
			--it changes fadeAnimationSection equal to 2, which skips the first part and runs the else statement below
			local sellBackround = gfx.image.new("assets/Backrounds/frame1BASE")
			aboveWaterBackroundSprite = spr.new(sellBackround)
			aboveWaterBackroundSprite:moveTo(200, 120)
			aboveWaterBackroundSprite:add()
			gfx.setDitherPattern(fadeAnimationIndex)
			gfx.fillRect(0, 0, 400, 240)
			fadeAnimationIndex -= 0.09
			if fadeAnimationIndex <= 0 then
				fadeAnimationSection = 2
			end
		else
			local underwaterBackround = gfx.image.new("assets/Backrounds/FishyFishyUnderwater")
			underwaterBackroundSprite = spr.new(underwaterBackround)
			underwaterBackroundSprite:moveTo(200, 1200)
			underwaterBackroundSprite:add()
			gfx.setDitherPattern(fadeAnimationIndex)
			gfx.fillRect(0, 0, 400, 240)
			fadeAnimationIndex += 0.09
		end
	end
	if fadeAnimationIndex > 1 then
		fadeAnimationDone = true
		aboveWaterBackroundSprite = nil
		underwaterBackroundSprite = nil
		gfx.sprite.removeAll()
		setupGame()
	end
end

function sellAnimation()
	if sellAnimationDone == false then
		local sellingFish = Fishys[soldFish.name]
		local files = playdate.file.listFiles(sellingFish.sellGifPath)
		gfx.sprite.removeAll()
		local sellAnimationFrame = gfx.image.new(sellingFish.sellGifPath .. "/animation" .. string.upper(soldFish.name) .. sellAnimationIndex)
		sellAnimationSprite = spr.new(sellAnimationFrame)
		sellAnimationSprite:moveTo(200, 120)
		sellAnimationSprite:add()
		if #files == sellAnimationIndex then
			sellAnimationDone = true
			sellAnimationIndex = 1
		end
		sellAnimationIndex += 1
	else
		if coinAnimationSprite then
			coinAnimationSprite:remove()
		end
		local files = playdate.file.listFiles("assets/Animations/coin")
		local coinAnimationFrame = gfx.image.new("assets/Animations/coin/animationCOIN" .. sellAnimationIndex)
		coinAnimationSprite = spr.new(coinAnimationFrame)
		coinAnimationSprite:moveTo(200, 120)
		coinAnimationSprite:add()
		if #files == sellAnimationIndex then
			coinAnimationDone = true
			sellFish()
			sellAnimationIndex = 1
		end
		sellAnimationIndex += 1
	end
	if balanceTextSprite then
	balanceTextSprite:remove()
	balanceTextSprite = nil
	end
	balanceTextSprite = spr.spriteWithText("Balance: " .. "*" .. balance .. "*", 100, 20)
	balanceTextSprite:setCenter(0, 0)
	balanceTextSprite:moveTo(5, 5)
	balanceTextSprite:add()
end

function sellFish()
	local sellingFish = Fishys[soldFish.name]
	local coinSound = sound.fileplayer.new("assets/Audio/coins")
	coinSound:setVolume(0.75)
	coinSound:play()
	local sellPrice = math.random(sellingFish.priceMin, sellingFish.priceMax)
	balance += sellPrice
end

function setupGame()
	gfx.clear()

	if aboveWater == true then
		playdate.display.setRefreshRate(10)
		underwaterMusic:pause()
		bubblesSound:pause()


	end

	if underWater == true then
		playdate.display.setRefreshRate(30)
		-- Load images
		local underWaterBackround = gfx.image.new("assets/Backrounds/FishyFishyUnderwater")
		local fishingHook = gfx.image.new("assets/Misc/fishhook")

		-- load and play music/sounds
		underwaterMusic = sound.fileplayer.new("assets/Audio/underwaterMusic")
		bubblesSound = sound.fileplayer.new("assets/Audio/bubbles")
		underwaterMusic:play()
		bubblesSound:setVolume(0.75)
		bubblesSound:play()

		-- Create sprites from images
		fishingHookSprite = spr.new(fishingHook)
		local width, height = fishingHookSprite:getSize()
		fishingHookSprite:setCollideRect(2.5, 187.5, width - 5, 50)
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
		spawnFish(100)
		print("Spawned: " .. randomFishcount .. " fish")
	end
	print("all sprites loaded")
end

function buttonCheck()
	if underWater then
		if playdate.buttonJustPressed("A") then
			fishHooked.speedX = fishHooked.speed
			fishHooked:setRotation(0)
			fishHooked:setCollideRect(0, 0, fishHooked:getSize())
			fishPreviouslyHooked = fishHooked
			fishHooked = nil
			print("fish off")
		end
	else
		if playdate.buttonJustPressed("down") then
			soldFish = nil
			fishHooked = nil
			fishPreviouslyHooked = nil
			fadeAnimationSection = 1
			fadeAnimationDone = false
			fadeAnimationIndex = 1
			sellAnimationDone = false
			sellAnimationIndex = 1
			coinAnimationDone = false
			aboveWater = false
			underWater = true
			fadeAnimation()
		end
	end
end

function playdate.update()
	-- Clear screen
	--gfx.clear()
	playdate.timer.updateTimers()

	--get crank pos
	crankChange = playdate.getCrankChange()
	local reeling = crankChange / 2

	if aboveWater == true then
		if fadeAnimationDone == false then
			gfx.sprite.update()
			fadeAnimation()
		elseif coinAnimationDone == false then
			sellAnimation()
			gfx.sprite.update()
			
		else
			buttonCheck()
			gfx.sprite.update()
		end
	end

	if underWater == true then
		if fadeAnimationDone == false then
			gfx.sprite.update()
			fadeAnimation()
		else
			if pauseGame == false then
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
					soldFish = fishHooked
					fishHooked = nil
					underwaterMusic:pause()
					bubblesSound:pause()
					underWater = false
					aboveWater = true
					fadeAnimationSection = 1
					fadeAnimationDone = false
					fadeAnimation()
				end
			end
			-- Update all sprites
			gfx.sprite.update()
		end
	end
end

-- Start the game
setupGame()
