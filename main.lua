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
local underwaterBackgroundSprite = nil
local aboveWaterBackroundSprite = nil
local sellAnimationSprite = nil
local balanceTextSprite = nil
local buttonSprite = nil

-- Sound
local abovewaterMusic = nil
local underwaterMusic = nil
local bubblesSound = nil
local windSound = nil
local waterSplashSound = nil
local popSound = nil

--Fish
local fishSprite = nil
local fishHooked = nil
local fishPreviouslyHooked = nil
local fishRarity = nil

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
local incorrectPresses = 0
local correctButtonData = nil
local currentMinigameFish = nil
local buttonPressed = true

Buttons = {
	Up = { rotation = 0, name = "Up" },
	Down = { rotation = 180, name = "Down" },
	Left = { rotation = -90, name = "Left" },
	Right = { rotation = 90, name = "Right" },
}

-- fish raritys
local NoFish = { data = { sellGifPath = "assets/Animations/nofish", priceMin = "0", priceMax = "0" }}
Fishys = {
	Common = {
		probability = 0.5,
		fish = {
			Cod = { probability = 100 / 100, imgPath = "assets/Fish/Common-Cod", sellGifPath = "assets/Animations/cod", catchDificulty = "2", priceMin = "1", priceMax = "6" },
		}
	},

	Rare = {
		probability = 0.2,
		fish = {
			Clownfish = { probability = 50 / 100, imgPath = "assets/Fish/Rare-Clownfish", sellGifPath = "assets/Animations/clownfish", catchDificulty = "4", priceMin = "4", priceMax = "12" },
			Bass = { probability = 50 / 100, imgPath = "assets/Fish/Rare-Bass", sellGifPath = "assets/Animations/bass", catchDificulty = "4", priceMin = "4", priceMax = "12" },
		}
	},

	Epic = {
		probability = 0.15,
		fish = {
			Pufferfish = { probability = 34 / 100, imgPath = "assets/Fish/Epic-Pufferfish", sellGifPath = "assets/Animations/pufferfish", catchDificulty = "7", priceMin = "10", priceMax = "18" },
			MoorishIdol = { probability = 33 / 100, imgPath = "assets/Fish/Epic-MoorishIdol", sellGifPath = "assets/Animations/moorishIdol", catchDificulty = "7", priceMin = "10", priceMax = "18" },
			Crab = { probability = 33 / 100, imgPath = "assets/Fish/Epic-Crab", sellGifPath = "assets/Animations/crab", catchDificulty = "7", priceMin = "10", priceMax = "18" },
		}
	},

	Legendary = {
		probability = 0.08,
		fish = {
			Octopus = { probability = 50 / 100, imgPath = "assets/Fish/Legendary-Octopus", sellGifPath = "assets/Animations/octopus", catchDificulty = "9", priceMin = "16", priceMax = "25" },
			Seahorse = { probability = 50 / 100, imgPath = "assets/Fish/Legendary-Seahorse", sellGifPath = "assets/Animations/seahorse", catchDificulty = "9", priceMin = "16", priceMax = "25" },
		}
	},

	Mythical = {
		probability = 0.04,
		fish = {
			Angler = { probability = 100 / 100, imgPath = "assets/Fish/Mythical-Angler", sellGifPath = "assets/Animations/angler", catchDificulty = "11", priceMin = "23", priceMax = "31" },
		}
	},

	Insane =  {
		probability = 0.02,
		fish = {
			Jellyfish = { probability = 100 / 100, imgPath = "assets/Fish/Insane-Jellyfish", sellGifPath = "assets/Animations/jellyfish", catchDificulty = "14", priceMin = "29", priceMax = "37" },
		}
	},

	Unknown = {
		probability = 0.01,
		fish = {
			Shark = { probability = 99 / 100, imgPath = "assets/Fish/Unknown-Shark", sellGifPath = "assets/Animations/shark", catchDificulty = "17", priceMin = "35", priceMax = "43" },
			SpongeBOB = { probability = 1 / 100, imgPath = "assets/Fish/Unknown-Spongebob", sellGifPath = "assets/Animations/spongebob", priceMin = "100000", catchDificulty = "30", priceMax = "1000000" },
		}
	}
}

local spawnedFish = {}


function getRandomFish()
	-- Random probability for rarity selection
	local rarityChance = math.random()
	local rarityTotal = 0

	-- Random probability for fish selection
	local chance = math.random()
	local total = 0

	-- Selects the rarity from the Fishys table and gets the data from it ( All the lines inbetween "fish = {" and "}" )
	for rarity, rarityData in pairs(Fishys) do
		rarityTotal += rarityData.probability
		if rarityChance <= rarityTotal then

			--Selects the fish from the selected table inside of the Fishys table then returns it to the spawnFish function
			for fish, data in pairs(rarityData.fish) do
				total += data.probability
				if chance <= total then
					return data, fish
				end
			end

		end
	end	
end

function spawnFish(count)
	for num = 1, count do
		--get random fish and its info
		local fishData, fishName = getRandomFish()
		--creates the sprite
		local fishImg = gfx.image.new(fishData.imgPath)
		fishSprite = spr.new(fishImg)
		fishSprite.data = fishData
		fishSprite.data.name = fishName
		--set center
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
		--random fish  swimming direction
		local direction = math.random()
		if direction > 0.5 then
			fishSprite.speedX = -fishSprite.speedX
			fishSprite:setImageFlip(gfx.kImageUnflipped)
		end
		-- finish adding the fish
		fishSprite:add()
		if fishData.name == "SpongeBOB" then
			print("SpongeBOB has spawned")
		end
		table.insert(spawnedFish, fishSprite)
	end
end

function collissionCheck()
	-- if a fish is already on the hook return in order to not allow 2 fish on the hook at once
	if fishHooked then
		return
	end
	-- goes through each fish in the spawnedFish table checking if any of them are overlapping with the fishing hook collission rect
	for _, fish in pairs(spawnedFish) do
		local overlappingSprites = fish:overlappingSprites()
		-- if the number of overlapping sprites are greater or equal to one, continue
		if #overlappingSprites >= 1 then
			--checks if the fish colliding with currently was just released from the hook to prevent not being able to relese the fish
			if fish == fishPreviouslyHooked then
				return
			else
				-- checks if the player is already attempting to catch a fish through the minigame (Prevents errors when multiple fish are overlapping the fishing hook rect when checked)
				if currentMinigameFish == nil then
					currentMinigameFish = fish
					-- gets the number of times you need to press the correct button and sets it as the difficulty
					local difficulty = tonumber(fish.data.catchDificulty)
					catchFishMiniGame(fish, difficulty)
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
			elseif xOffset < 25 then
				direction = math.random(2)
			end

			if yOffset > 215 then
				direction = 1
			elseif yOffset < 25 then
				direction = 3
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

		local currentScale = 1
		-- time limit to catch the fish
		timeLimit = playdate.timer.new(3000, function()
				-- runs when timer is out
				timeLimit:remove()
				timeLimit = nil
				buttonCheckTimer:remove()
				buttonCheckTimer = nil
				buttonSprite:remove()
				buttonSprite = nil
				currentMinigameFish = nil
				incorrectPresses = 0
				timesCompleated = 0
				-- repeats to animate fish swimming away
				swimAway = playdate.timer.keyRepeatTimerWithDelay(20, 20, function ()
				if swimAway then
					if currentScale <= 0 then
						fish:remove()
						swimAway:remove()
						swimAway = nil
						pauseGame = false
					end
				end
					fish:setScale(currentScale - 0.07, currentScale - 0.07)
					currentScale -= 0.07
					fish:setCollideRect(0, 0, fish:getSize())
				end)
		end)

		local function waitForButton()
			
			local current, pressed, released = playdate.getButtonState()
			if buttonPressed == false then
				if pressed ~= 0 and playdate.buttonJustPressed(string.lower(correctButtonData.name)) == false then
					buttonPressed = true
					-- wrong button pressed
					incorrectPresses += 1
					print("Incorrect button Pressed - Number of incorrect Presses: " .. incorrectPresses .. " - Fish: " .. fish.data.name)
					print("number of incorrect presses allowed: " .. fish.data.catchDificulty / 3)
					if incorrectPresses >= fish.data.catchDificulty / 3 then
						timeLimit:remove()
						timeLimit = nil
						buttonCheckTimer:remove()
						buttonCheckTimer = nil
						buttonSprite:remove()
						buttonSprite = nil
						currentMinigameFish = nil
						incorrectPresses = 0
						timesCompleated = 0
						-- repeats to animate fish swimming away
						swimAway = playdate.timer.keyRepeatTimerWithDelay(20, 20, function ()
						if swimAway then
							if currentScale <= 0 then
								fish:remove()
								swimAway:remove()
								swimAway = nil
								pauseGame = false
							end
						end
							fish:setScale(currentScale - 0.07, currentScale - 0.07)
							currentScale -= 0.07
							fish:setCollideRect(0, 0, fish:getSize())
						end)
					end
				end
				if playdate.buttonJustPressed(string.lower(correctButtonData.name)) then
						buttonPressed = true
						if buttonCheckTimer then
							buttonCheckTimer:remove()
						end
						if timeLimit then
							timeLimit:remove()
						end
						buttonCheckTimer = nil
						timeLimit = nil
						timesCompleated += 1
						buttonSprite:remove()
						buttonSprite = nil

						popSound = sound.fileplayer.new("assets/Audio/pop")
						popSound:setVolume(0.5)
						popSound:play()

						local minigameDone = false
						if timesCompleated >= difficulty then
							if minigameDone == false then
								minigameDone = true
								--finish minigame 
								
								currentMinigameFish = nil
								pauseGame = false
								timesCompleated = 0
								fishHooked = fish
								fishHooked.speedX = 0

								if width > height then
									fishHooked:setRotation(90)
								end
								fishHooked:setCollideRect(0, 0, fishHooked:getSize())
							end
						else
							print("Correct button pressed! Number of presses: " .. timesCompleated)
							catchFishMiniGame(fish, difficulty)
						end
						return
					end
				else
					buttonPressed = false
				end
		end
		-- continuously check if the correct button has been pressed
		buttonCheckTimer = playdate.timer.keyRepeatTimerWithDelay(2, 2, waitForButton)
end


function startFadeAnimation()
	windSound = sound.fileplayer.new("assets/Audio/wind")
	windSound:setVolume(0)
	windSound:play()
	if aboveWater then
		abovewaterMusic = sound.fileplayer.new("assets/Audio/abovewaterMusic")
		abovewaterMusic:setVolume(0.75)
		abovewaterMusic:play()
	end
	
	fadeAnimation()
end

function fadeAnimation()
	playdate.display.setRefreshRate(10)
	gfx.setColor(gfx.kColorBlack)
	gfx.sprite.removeAll()
	if aboveWater == true then
			if fadeAnimationSection == 1 then
				-- when fadeAnimationSection is equal to 1 it goes through this 
				-- untill the fadeAnimationIndex is less than 0 once it is
				-- it changes fadeAnimationSection equal to 2, which skips the first part and runs the else statement below
				local underwaterBackround = gfx.image.new("assets/Backrounds/FishyFishyUnderwater")
				underwaterBackgroundSprite = spr.new(underwaterBackround)
				underwaterBackgroundSprite:moveTo(200, 1200)
				underwaterBackgroundSprite:add()
				gfx.setDitherPattern(fadeAnimationIndex)
				underwaterMusic:setVolume(fadeAnimationIndex)
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
				if fadeAnimationIndex < 0.75 then
					abovewaterMusic:setVolume(fadeAnimationIndex)
				else
					abovewaterMusic:setVolume(0.75)
				end
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
			if fadeAnimationIndex < 0.75 then
				abovewaterMusic:setVolume(fadeAnimationIndex)
			else
				abovewaterMusic:setVolume(0.75)
			end
			gfx.fillRect(0, 0, 400, 240)
			fadeAnimationIndex -= 0.09
			if fadeAnimationIndex <= 0 then
				fadeAnimationSection = 2
			end
		else
			local underwaterBackround = gfx.image.new("assets/Backrounds/FishyFishyUnderwater")
			underwaterBackgroundSprite = spr.new(underwaterBackround)
			underwaterBackgroundSprite:moveTo(200, 1200)
			underwaterBackgroundSprite:add()
			gfx.setDitherPattern(fadeAnimationIndex)
			underwaterMusic:setVolume(fadeAnimationIndex)
			gfx.fillRect(0, 0, 400, 240)
			fadeAnimationIndex += 0.09
		end
	end
	if fadeAnimationIndex > 1 then
		windSound:stop()
		fadeAnimationDone = true
		aboveWaterBackroundSprite:remove()
		aboveWaterBackroundSprite = nil
		underwaterBackgroundSprite:remove()
		underwaterBackgroundSprite = nil
		--gfx.sprite.removeAll()
		setupGame()
	end
end

function sellAnimation()
	if sellAnimationDone == false then
		local files = playdate.file.listFiles(soldFish.data.sellGifPath)
		if files == nil then
			print("An error occured while trying to fetch sell animation path. Check to make sure the path and files exist.")
		end
		gfx.sprite.removeAll()
		local sellAnimationFrame = gfx.image.new(soldFish.data.sellGifPath .. "/animation" .. string.upper(soldFish.data.name) .. sellAnimationIndex)
		sellAnimationSprite = spr.new(sellAnimationFrame)
		sellAnimationSprite:moveTo(200, 120)
		sellAnimationSprite:add()

		if sellAnimationIndex == 20 and soldFish.data.name ~= "NoFish" then
			waterSplashSound = sound.fileplayer.new("assets/Audio/waterSplash")
			waterSplashSound:setVolume(0.3)
			waterSplashSound:play()
		end
		if #files == sellAnimationIndex and soldFish.data.name == "NoFish" then
			coinAnimationDone = true
			sellAnimationDone = true
			sellAnimationIndex = 1
		elseif #files == sellAnimationIndex then
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
	local coinSound = sound.fileplayer.new("assets/Audio/coins")
	coinSound:setVolume(0.25)
	coinSound:play()
	local sellPrice = math.random(soldFish.data.priceMin, soldFish.data.priceMax)
	balance += sellPrice
	print('selling done')
end

function setupGame()

	local gameData = playdate.datastore.read()
	-- If game data has never been saved, the read value will
	-- be 'nil', so check if the game data exists first
	if gameData then
		-- Populate game structures with the saved data
		balance = gameData.coinBalance
	end

	if aboveWater == true then
		playdate.display.setRefreshRate(10)
		underwaterMusic:pause()
		bubblesSound:pause()
		windSound:pause()
	end

	if underWater == true then
		playdate.display.setRefreshRate(30)
		-- Load images
		local underWaterBackround = gfx.image.new("assets/Backrounds/FishyFishyUnderwater")
		local fishingHook = gfx.image.new("assets/Misc/fishhook")

		-- pause, load and play music/sounds
		if abovewaterMusic then
			abovewaterMusic:pause()
		end
		underwaterMusic = sound.fileplayer.new("assets/Audio/underwaterMusic")
		bubblesSound = sound.fileplayer.new("assets/Audio/bubbles")
		underwaterMusic:play()
		bubblesSound:setVolume(0.75)
		bubblesSound:play()

		-- Create sprites from images
		fishingHookSprite = spr.new(fishingHook)
		local width, height = fishingHookSprite:getSize()
		fishingHookSprite:setCollideRect(2.5, 212.5, width - 5, 25)
		fishingHookSprite.collisionResponse = spr.kCollisionTypeOverlap
		fishingHookSprite:setGroups(1)
		fishingHookSprite:setCollidesWithGroups(2)
		underwaterBackgroundSprite = spr.new(underWaterBackround)

		-- Position sprites
		fishingHookSprite:moveWithCollisions(200, 50)
		underwaterBackgroundSprite:moveTo(200, 1200)

		-- Add sprites to display list (makes them visible)
		fishingHookSprite:add()
		underwaterBackgroundSprite:add()

		local randomFishcount = math.random(10, 20)
		spawnFish(randomFishcount)
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
			incorrectPresses = 0
			timesCompleated = 0
			fishHooked = nil
			print("fish realeased from the hook")
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
			startFadeAnimation()
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
			if fadeAnimationIndex > 0.25 then
				windSound:setVolume(1 - fadeAnimationIndex)
			else
				windSound:setVolume(0.75)
			end

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
			if fadeAnimationIndex > 0.25 then
				windSound:setVolume(1 - fadeAnimationIndex)
			else
				windSound:setVolume(0.75)
			end
		else
			if pauseGame == false then
				-- Move hook with arrow keys
				if playdate.buttonIsPressed(playdate.kButtonRight) then
					fishingHookSprite:moveWithCollisions(fishingHookSprite.x + 5, fishingHookSprite.y)
				elseif playdate.buttonIsPressed(playdate.kButtonLeft) then
					fishingHookSprite:moveWithCollisions(fishingHookSprite.x - 5, fishingHookSprite.y)
				end

				--Limits hook going off screen
				if fishingHookSprite.x >= 375 then
					fishingHookSprite:moveWithCollisions(374, fishingHookSprite.y)
				elseif fishingHookSprite.x <= 25 then
					fishingHookSprite:moveWithCollisions(26, fishingHookSprite.y)
				end

				--Check for collission with fishingHookSprite
				if fishHooked then
					fishHooked:moveWithCollisions(fishingHookSprite.x, 187.5)
					buttonCheck()
				else
					collissionCheck()
				end

				
				-- scroll underwaterbackground with crank
				local bgY1 = underwaterBackgroundSprite.y
				underwaterBackgroundSprite:moveBy(0, -2 + reeling)
				local bgY2 = underwaterBackgroundSprite.y - bgY1

					--limits scrolling underwaterbackground too far and moves fish with underwaterbackground
				if underwaterBackgroundSprite.y >= 1200 then
					underwaterBackgroundSprite:moveTo(200, 1199)
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
				elseif underwaterBackgroundSprite.y <= -960 then
					underwaterBackgroundSprite:moveTo(200, -959)
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
							--Keep fish with underwaterBackgroundSprite
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
				if underwaterBackgroundSprite.y >= 1199 then
					if fishHooked == nil then
						fishHooked = NoFish
						fishHooked.data.name = "NoFish"
					end
					soldFish = fishHooked
					fishHooked = nil
					bubblesSound:pause()
					underWater = false
					aboveWater = true
					fadeAnimationSection = 1
					fadeAnimationDone = false
					startFadeAnimation()
				end
			end
			-- Update all sprites
			gfx.sprite.update()
		end
	end
end

function saveGameData()
    -- Save game data into a table first
    local gameData = {
        coinBalance = balance
    }
    -- Serialize game data table into the datastore
    playdate.datastore.write(gameData)
end

-- Automatically save game data when the player chooses
-- to exit the game via the System Menu or Menu button
function playdate.gameWillTerminate()
    saveGameData()
end

-- Automatically save game data when the device goes
-- to low-power sleep mode because of a low battery
function playdate.gameWillSleep()
    saveGameData()
end

-- Start the game
setupGame()
