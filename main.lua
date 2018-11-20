debug = true

-- Background tile
bgTile = nil

-- Player array
player = {
    img = nil,
    x = 20,
    y = 20,
    speed = 250,
    rotate = false,
}

-- Bullet configuration
bulletConf = {
    img = nil,
    timeBetween = 0.3,
    timer = nil,
    speed = 300,
}
bulletConf.timer = bulletConf.timeBetween
-- Array for bullets
bullets = {}

-- Target array
target = {
    img = nil,
    x = 50,
    y = 50,
}
-- Possible target locations
-- TODO: Empty from the beginning
targetLocs = {
    {
        x = 10,
        y = 10,
    },
    {
        x = 100,
        y = 10,
    },
}

-- All platform locations and lengths
platforms = {
    -- Ground
    {
        x = 0,
        y = 480,
        c = 16,
    },
    -- Left
    {
        x = 64,
        y = 416,
        c = 3,
    },
    -- Middle
    {
        x = 208,
        y = 352,
        c = 3,
    },
    -- Right
    {
        x = 352,
        y = 288,
        c = 3,
    },
    -- Middle
    {
        x = 208,
        y = 224,
        c = 3,
    },
    -- Left
    {
        x = 64,
        y = 160,
        c = 3,
    },
    -- Middle
    {
        x = 208,
        y = 96,
        c = 3,
    },
    -- Right
    {
        x = 352,
        y = 32,
        c = 3,
    },
}
-- Platform tile
platformImg = nil

-- Collision detection function from https://love2d.org/wiki/BoundingBox.lua
-- Returns true if two boxes overlap, false if they don't
-- x1,y1 are the top-left coords of the first box, while w1,h1 are its width and height
-- x2,y2,w2 & h2 are the same, but for the second box
function CheckCollision(x1, y1, w1, h1, x2, y2, w2, h2)
    return x1 < x2 + w2 and
        x2 < x1 + w1 and
        y1 < y2 + h2 and
        y2 < y1 + h1
end

function love.load()
    -- Set window size
    love.window.setMode(512, 512)

    -- Load image assets
    bgTile = love.graphics.newImage('assets/background.png')
    player.img = love.graphics.newImage('assets/player.png')
    target.img = love.graphics.newImage('assets/target.png')
    bulletConf.img = love.graphics.newImage('assets/bullet.png')
    platformImg = love.graphics.newImage('assets/platform.png')

    -- Calculate player start position
    player.x = (love.graphics.getWidth() / 2) - (player.img:getWidth() / 2)
    player.y = (love.graphics.getHeight() - platformImg:getHeight()) - player.img:getHeight()
end

function love.update(dt)
    local currX, currY = player.x, player.y
    local goalX, goalY = player.x, player.y

    if love.keyboard.isDown('left') then
        goalX = goalX - (player.speed * dt)
    end

    if love.keyboard.isDown('right') then
        goalX = goalX + (player.speed * dt)
    end

    if love.keyboard.isDown('up') then
        goalY = goalY - (player.speed * dt)
    end

    if love.keyboard.isDown('down') then
        goalY = goalY + (player.speed * dt)
    end

    if goalX < currX then
        player.rotate = true
    elseif goalX > currX then
        player.rotate = false
    end

    for i, platform in ipairs(platforms) do
        local pWidth = platformImg:getWidth() * platform.c
        if goalX < 0 then
            goalX = 0
        elseif goalX > (love.graphics.getWidth() - player.img:getWidth()) then
            goalX = love.graphics.getWidth() - player.img:getWidth()
        elseif CheckCollision(goalX, player.y, player.img:getWidth(), player.img:getHeight(), platform.x, platform.y, pWidth, platformImg:getHeight()) then
            if player.rotate then
                goalX = platform.x + pWidth
            else
                goalX = platform.x - player.img:getWidth()
            end
        end

        if goalY < 0 then
            goalY = 0
        elseif goalY > (love.graphics.getHeight() - player.img:getHeight()) then
            goalY = love.graphics.getHeight() - player.img:getHeight()
        elseif CheckCollision(goalX, goalY, player.img:getWidth(), player.img:getHeight(), platform.x, platform.y, pWidth, platformImg:getHeight()) then
            if goalY > currY then
                goalY = platform.y - player.img:getHeight()
            else
                goalY = platform.y + platformImg:getHeight()
            end
        end
    end

    player.x = goalX
    player.y = goalY

    bulletConf.timer = bulletConf.timer - (1 * dt)

    if love.keyboard.isDown('space')
        and bulletConf.timer < 0
    then
        -- Create some bullets
        newBullet = {
            x = nil,
            y = player.y + ((player.img:getHeight() / 2) - (bulletConf.img:getHeight() / 2)),
            rotate = player.rotate,
        }
        if newBullet.rotate then
            newBullet.x = player.x
        else
            newBullet.x = player.x + (player.img:getWidth() / 2)
        end
        table.insert(bullets, newBullet)
        bulletConf.timer = bulletConf.timeBetween
    end

    -- update the positions of bullets
    for i, bullet in ipairs(bullets) do
        if bullet.rotate then
            bullet.x = bullet.x - (bulletConf.speed * dt)
        else
            bullet.x = bullet.x + (bulletConf.speed * dt)
        end

        -- remove bullets when they pass off the screen
        if (bullet.x + bulletConf.img:getWidth()) < 0
            or bullet.x > love.graphics.getWidth()
        then
            table.remove(bullets, i)
        else
            -- remove bullets that collide with platforms
            for j, platform in ipairs(platforms) do
                if CheckCollision(bullet.x, bullet.y, bulletConf.img:getWidth(), bulletConf.img:getHeight(), platform.x, platform.y, (platformImg:getWidth() * platform.c), platformImg:getHeight()) then
                    table.remove(bullets, i)
                end
            end
        end
    end
end

function love.keypressed(key)
    if key == 'escape' then
        love.event.push('quit')
    end
end

function love.draw(dt)
    -- Render tiled background image
    local bgW = bgTile:getWidth()
    local bgH = bgTile:getHeight()
    for i = 0, (love.graphics.getWidth() / bgW) do
        for j = 0, (love.graphics.getHeight() / bgH) do
            love.graphics.draw(bgTile, i * bgW, j * bgH)
        end
    end

    -- Render player
    if player.rotate then
        love.graphics.draw(player.img, player.x, player.y, 0, -1, 1, player.img:getWidth(), 0)
    else
        love.graphics.draw(player.img, player.x, player.y)
    end

    -- Render target
    love.graphics.draw(target.img, target.x, target.y)

    -- Render bullets
    for i, bullet in ipairs(bullets) do
        if bullet.rotate then
            love.graphics.draw(bulletConf.img, bullet.x, bullet.y, 0, -1, 1, bulletConf.img:getWidth(), 0)
        else
            love.graphics.draw(bulletConf.img, bullet.x, bullet.y)
        end
    end

    -- Render platforms
    local pImgW = platformImg:getWidth()
    for i, platform in ipairs(platforms) do
        for j = 0, (platform.c - 1) do
            love.graphics.draw(platformImg, (j * pImgW) + platform.x, platform.y)
        end
    end

    if debug then
        love.graphics.print({
            {0, 0, 0},
            'FPS: ' .. tostring(love.timer.getFPS())
        }, 0, 0)
        love.graphics.print({
            {0, 0, 0},
            'WxH: ' .. tostring(love.graphics.getWidth()) .. 'x' .. tostring(love.graphics.getHeight())
        }, 0, 12)
        love.graphics.print({
            {0, 0, 0},
            'X,Y: ' .. tostring(math.floor(player.x)) .. ',' .. tostring(math.floor(player.y))
        }, 0, 24)
        love.graphics.print({
            {0, 0, 0},
            'BULL.: ' .. tostring(table.getn(bullets))
        }, 0, 36)
        love.graphics.print({
            {0, 0, 0},
            'PLAT.: ' .. tostring(table.getn(platforms))
        }, 0, 48)
    end
end
