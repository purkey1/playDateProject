import "CoreLibs/graphics"
import "CoreLibs/sprites"

local gfx = playdate.graphics
local spr = gfx.sprite

-- Variables for our sprites
local fishingHookSprite = nil
local backroundSprite = nil

--Fish
local codSprite = nil

-- variables for crank pos
local crankChange = 0
local isDocked = true

-- fish raritys
Fishys = {
    Cod = { probability =     40/100 }, --Common
    Nemo = { probability =    25/100 }, --Rare
    Epic = { probability =    15/100 }, --Epic
    Octopus = { probability = 10/100 }, --Legendary
    Angler = { probability =   6/100 }, --Mythical
    Insane = { probability =   3/100 }, --Insane
    Unknown = { probability =  1/100 }, --Unknown
}

function getRandomFish()
        local probability = math.random(1, 100)
        RandomFish = nil
        --Get the fish matching probability
        if probability < 0 and probability > 41 then
            return "Cod"
        elseif probability < 40 and probability > 66 then
            RandomFish = "Nemo"
        elseif probability < 65 and probability > 81 then
            RandomFish = "Epic"
        elseif probability < 80 and probability > 91 then
            RandomFish = "Octopus"
        elseif probability < 90 and probability > 97 then
                RandomFish = "Angler"
        elseif probability < 96 and probability > 100 then
                RandomFish = "Insane"
        elseif probability == 100 then
                RandomFish = "Unknown"
        end
        
end

function setupGame()
    -- Load images
    local backround = gfx.image.new("assets/FishyFishyUnderwater")
    local fishingHook = gfx.image.new("assets/fishhook2")

    local cod = gfx.image.new("assets/Fish/Common-Cod")
    

    
    -- Check if images loaded
    if not fishingHook or not backround then
        print("ERROR: Could not load images!")
        return
    end
    
    -- Create sprites from images
    fishingHookSprite = spr.new(fishingHook)
    backroundSprite = spr.new(backround)

    codSprite = spr.new(cod)
    
    -- Position sprites
    fishingHookSprite:moveTo(200,50)
    backroundSprite:moveTo(200, 1200)
    
    
    -- Add sprites to display list (makes them visible)
    fishingHookSprite:add()
    backroundSprite:add()
    print("all sprites loaded")
end


function playdate.update()
    -- Clear screen
    gfx.clear()
    local fish = getRandomFish()
    print(fish)
    
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
