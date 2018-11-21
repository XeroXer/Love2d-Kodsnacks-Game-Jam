blockSize = 32

-- Background tile
bgTile = nil

-- Player array
player = {
    img = nil,
    x = nil,
    y = nil,
    speed = 250,
    rotate = false,
    gravity = 150,
    jump = 0,
    jumpSpeed = 1200,
}

-- Bullet configuration
bulletConf = {
    img = nil,
    timeBetween = 0.3,
    timer = nil,
    speed = 500,
}
bulletConf.timer = bulletConf.timeBetween
-- Array for bullets
bullets = {}

-- Target array
target = {
    img = nil,
    x = nil,
    y = nil,
}
-- Possible target locations
targetLocs = {}

-- All platform locations and lengths
platforms = {
    -- Ground
    {
        x = 0,
        y = (20 * blockSize),
        c = 17,
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
    love.window.setMode((17 * blockSize), (21 * blockSize))

    -- Load image assets
    bgTile = love.graphics.newImage('assets/background.png')
    player.img = love.graphics.newImage('assets/player.png')
    target.img = love.graphics.newImage('assets/target.png')
    bulletConf.img = love.graphics.newImage('assets/bullet.png')
    platformImg = love.graphics.newImage('assets/platform.png')

    -- Calculate player start position
    player.x = (love.graphics.getWidth() / 2) - (player.img:getWidth() / 2)
    player.y = love.graphics.getHeight() - (blockSize * 2)

    -- Calculate target locations
    j = 1
    for i = 1, 19, 2 do
        targetLocs[j] = {
            x = 0,
            y = (i * blockSize) + (blockSize / 2),
        }
        j = j + 1
        targetLocs[j] = {
            x = (16 * blockSize),
            y = (i * blockSize) + (blockSize / 2),
        }
        j = j + 1
    end

    -- Get first position of target
    local targetPos = targetLocs[love.math.random(#targetLocs)]
    target.x = targetPos.x
    target.y = targetPos.y

    -- Calculate platform locations

    local j = 2
    for i = 2, 18, 4 do
        platforms[j] = {
            x = (2 * blockSize),
            y = (i * blockSize),
            c = 3,
        }
        j = j + 1
        platforms[j] = {
            x = (12 * blockSize),
            y = (i * blockSize),
            c = 3,
        }
        j = j + 1
    end
    for i = 4, 16, 4 do
        platforms[j] = {
            x = (7 * blockSize),
            y = (i * blockSize),
            c = 3,
        }
        j = j + 1
    end
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

    -- gravity
    goalY = goalY + (player.gravity * dt)

    if player.jump > 0 then
        goalY = goalY - (player.jump * dt)
        player.jump = player.jump - player.gravity
    end
    if love.keyboard.isDown('up') and goalY > currY then
        local collision = false
        for i, platform in ipairs(platforms) do
            if CheckCollision(currX, goalY, player.img:getWidth(), player.img:getHeight(), platform.x, platform.y, (platformImg:getWidth() * platform.c), platformImg:getHeight()) then
                collision = true
            end
        end
        if collision then
            player.jump = player.jumpSpeed
        end
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

            -- remove bullets and targets that collide with each other
            if CheckCollision(bullet.x, bullet.y, bulletConf.img:getWidth(), bulletConf.img:getHeight(), target.x, target.y, target.img:getWidth(), target.img:getHeight()) then
                table.remove(bullets, i)

                -- Get next position of target
                local targetPos = targetLocs[love.math.random(#targetLocs)]
                target.x = targetPos.x
                target.y = targetPos.y
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

    -- local debugInfos = {
    --     'FPS: ' .. tostring(love.timer.getFPS()),
    --     'WxH: ' .. tostring(love.graphics.getWidth()) .. 'x' .. tostring(love.graphics.getHeight()),
    --     'WxH: ' .. tostring(love.graphics.getWidth() / blockSize) .. 'x' .. tostring(love.graphics.getHeight() / blockSize),
    -- }
    -- for i, debugInfo in ipairs(debugInfos) do
    --     love.graphics.print({{1, 0, 0}, debugInfo}, 0, (i * 12) - 12)
    -- end
end
