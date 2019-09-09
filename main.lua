local WIDTH, HEIGHT = 1024, 768

local SIZE = math.min(WIDTH, HEIGHT) / 2

local panx = 0
local pany = 0
local panz = 1

local scale = 1

local xvel = 0
local yvel = 0
local zvel = 0

local universe

local draw_threshold = 10 

function love.load()
    love.window.setTitle("Mima")

    -- Set up the display
    --WIDTH, HEIGHT = love.window.getDesktopDimensions()
    love.window.setFullscreen(false)
    love.window.setMode(WIDTH, HEIGHT)
    love.mouse.setVisible(false)

    love.math.setRandomSeed(0)

    universe = make_multiverse()
end

function make_seed()
    return love.math.random(0, 2^53 - 1)
end

function make_size(variability)
    local a = SIZE / variability
    local b = SIZE - a

    return a + b * love.math.random()
end

function draw(d)
    -- Don't draw if it's off-screen
    local x1, y1 = love.graphics.transformPoint(-d.size, -d.size)
    local x2, y2 = love.graphics.transformPoint(d.size, d.size)
    if x2 < 0 or x1 > WIDTH or y2 < 0 or y1 > HEIGHT then
        return
    end

    -- Set a colour
    local c = d.colour
    if c == nil then
        c = {1, 1, 1}
    end

    -- Draw a dot if it's small
    effective_size = (d.size * 2) / scale * panz
    if effective_size <= 1 then
        c[4] = effective_size / 2
        love.graphics.setColor(c)
        love.graphics.circle("fill", 0, 0, scale / panz)
        return
    elseif effective_size <= draw_threshold then
        c[4] = 0.5 + (effective_size / draw_threshold) / 2
        love.graphics.setColor(c)
        love.graphics.circle("fill", 0, 0, d.size)
        return
    end

    -- Expand if it's not expanded yet
    if d.expanded == nil and d.expand ~= nil then
        love.math.setRandomSeed(d.seed)
        d:expand()
        d.expanded = true
    end

    -- Draw it
    d:draw()
end

function draw_building(b)
    -- Half-bright
    c = {
        b.colour[1] / 2,
        b.colour[2] / 2,
        b.colour[3] / 2,
    }
    love.graphics.setColor(c)
    love.graphics.rectangle("fill", -b.size/4, b.size / 4, b.size / 2, -3 * b.size / 4)

    love.graphics.setColor(b.colour)
    love.graphics.line(
        -b.size/4, 0,
        -b.size/4, -b.size / 2,
        b.size/4, -b.size / 2,
        b.size/4, 0
    )
end

function make_building(c)
    return {
        size = make_size(10),
        draw = draw_building,
        colour = c,
    }
end

function draw_planet(p)
    -- Half-bright
    c = {
        p.colour[1] / 2,
        p.colour[2] / 2,
        p.colour[3] / 2,
    }
    love.graphics.setColor(c)
    love.graphics.circle("fill", 0 ,0, p.size)

    love.graphics.setColor(p.colour)
    love.graphics.circle("line", 0 ,0, p.size)

    -- Buildings
    for _, b in ipairs(p.buildings) do
        love.graphics.push()
        love.graphics.rotate(b.a)
        love.graphics.translate(0, -p.size)
        scale = scale * 10
        love.graphics.scale(1/10)
        draw(b.building)
        scale = scale / 10
        love.graphics.pop()
    end
end

function expand_planet(p)
    for i = 1, 100 + love.math.random() * 100 do
        p.buildings[#p.buildings + 1] = {
            a = math.pi * 2 * love.math.random(),
            building = make_building(p.colour),
        }
    end
end

function make_planet()
    return {
        seed = make_seed(),
        size = make_size(10),
        draw = draw_planet,
        expand = expand_planet,
        colour = {love.math.random(), love.math.random(), love.math.random()},
        buildings = {},
    }
end

function draw_star(s)
    c = s.colour
    c[4] = 0.5

    love.graphics.setColor(c)
    love.graphics.circle("fill", 0 ,0, s.size)

    c[4] = 1
    love.graphics.setColor(c)
    love.graphics.circle("line", 0 ,0, s.size)
end

function make_star()
    return {
        size = make_size(20),
        draw = draw_star,
        colour = {1, love.math.random(), 0},
    }
end

function draw_solar_system(ss)
    -- Suns
    love.graphics.push()
    scale = scale * 10
    love.graphics.scale(1/10)
    if #ss.suns == 1 then
        ss.suns[1]:draw()
    else
        local a = math.pi * 2 / #ss.suns

        for i = 1, #ss.suns do
            love.graphics.push()
            love.graphics.translate(SIZE * math.cos(a * i), SIZE * math.sin(a * i))
            draw(ss.suns[i])
            love.graphics.pop()
        end
    end
    scale = scale / 10
    love.graphics.pop()

    -- Planets
    for _, p in ipairs(ss.planets) do
        -- Orbit
        --love.graphics.setColor(1, 1, 1, 0.1)
        --love.graphics.circle("line", 0, 0, p.d)

        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.push()
        love.graphics.translate(p.d * math.cos(p.a), p.d * math.sin(p.a))
        scale = scale * 100
        love.graphics.scale(1/100)
        draw(p.planet)
        scale = scale / 100
        love.graphics.pop()
    end
end

function expand_solar_system(ss)
    for i = 1, 1 + love.math.random() * 2 do
        ss.suns[#ss.suns + 1] = make_star()
    end

    for i = 1, love.math.random() * 10 do
        ss.planets[#ss.planets + 1] = {
            a = math.pi * 2 * love.math.random(),
            d = (ss.size / 2) + (ss.size / 2 * love.math.random()),
            planet = make_planet(),
        }
    end
end

function make_solar_system()
    return {
        seed = make_seed(),
        size = make_size(2),
        expand = expand_solar_system,
        draw = draw_solar_system,
        suns = {},
        planets = {},
    }
end

function draw_galaxy(g)
    -- Cloud
    --love.graphics.setColor(1, 1, 1, 0.1)
    --love.graphics.circle("fill", 0, 0, g.size)

    -- Systems
    for _, s in ipairs(g.systems) do
        love.graphics.push()
        love.graphics.translate(s.d * math.cos(s.a), s.d * math.sin(s.a))
        scale = scale * 10000
        love.graphics.scale(1/10000)
        draw(s.system)
        scale = scale / 10000
        love.graphics.pop()
    end
end

function expand_galaxy(g)
    -- How many arms?
    local a = (math.pi * 2) / love.math.random(2, 5)
    if love.math.random() < 0.5 then
        a = -a
    end

    -- Make it twisty!
    a = a + love.math.random() * love.math.random()

    for i = 1, g.size * math.pi * 2 do
        local size = i / (math.pi * 2)

        g.systems[#g.systems + 1] = {
            a = a * i,
            d = size - love.math.random() * love.math.random() * size,
            system = make_solar_system(),
        }
    end
end

function make_galaxy()
    return {
        seed = make_seed(),
        size = make_size(1000),
        expand = expand_galaxy,
        draw = draw_galaxy,
        systems = {},
    }
end

function draw_universe(u)
    -- Background
    love.graphics.setColor(0, 0, 0, 0)
    love.graphics.circle("fill", 0, 0, u.size)

    -- Systems
    for _, g in ipairs(u.galaxies) do
        love.graphics.push()
        love.graphics.translate(g.d * math.cos(g.a), g.d * math.sin(g.a))
        scale = scale * 100
        love.graphics.scale(1/100)
        draw(g.galaxy)
        scale = scale / 100
        love.graphics.pop()
    end
end

function expand_universe(u)
    for i = 1, u.size do
        u.galaxies[#u.galaxies + 1] = {
            a = math.pi * 2 * love.math.random(),
            d = u.size - (u.size * love.math.random() * love.math.random()),
            galaxy = make_galaxy(),
        }
    end
end

function make_universe()
    return {
        seed = make_seed(),
        size = SIZE,
        draw = draw_universe,
        expand = expand_universe,
        galaxies = {},
    }
end

function draw_multiverse(m)
    -- Cloud
    love.graphics.setColor(0, 0, 1, 0.1)
    love.graphics.circle("fill", 0, 0, m.size)

    -- Universes
    for _, u in ipairs(m.universes) do
        love.graphics.push()
        love.graphics.translate(u.d * math.cos(u.a), u.d * math.sin(u.a))
        scale = scale * 100
        love.graphics.scale(1/100)
        draw(u.universe)
        scale = scale / 100
        love.graphics.pop()
    end
end

function expand_multiverse(m)
    for i = 1, m.size / 4 do
        m.universes[#m.universes + 1] = {
            a = math.pi * 2 * love.math.random(),
            d = m.size - (m.size * love.math.random() * love.math.random()),
            universe = make_universe(),
        }
    end
end

function make_multiverse()
    return {
        seed = make_seed(),
        size = SIZE,
        draw = draw_multiverse,
        expand = expand_multiverse,
        universes = {},
    }
end

function love.update(dt)
    panx = panx + xvel * dt * 250 / panz
    pany = pany + yvel * dt * 250 / panz
    panz = panz + zvel * (panz / 2) * dt
end

function love.draw()
    love.graphics.clear()

    love.graphics.push()
    love.graphics.translate(WIDTH/2, HEIGHT/2)
    scale = 1
    love.graphics.scale(panz)
    love.graphics.translate(panx, pany)
    draw(universe)
    love.graphics.pop()
end

function love.keypressed(key)
    if key == "q" or key == "escape" then
        love.event.quit()
    end

    -- Left
    if key == "a" then
        xvel = xvel + 1
    end

    -- Right
    if key == "d" then
        xvel = xvel - 1
    end

    -- Up
    if key == "w" then
        yvel = yvel + 1
    end

    -- Down
    if key == "s" then
        yvel = yvel - 1
    end

    -- In
    if key == "up" then
        zvel = zvel + 1
    end

    -- Out
    if key == "down" then
        zvel = zvel - 1
    end
end

function love.keyreleased(key)
    -- Left
    if key == "a" then
        xvel = xvel - 1
    end

    -- Right
    if key == "d" then
        xvel = xvel + 1
    end

    -- Up
    if key == "w" then
        yvel = yvel - 1
    end

    -- Down
    if key == "s" then
        yvel = yvel + 1
    end

    -- In
    if key == "up" then
        zvel = zvel - 1
    end

    -- Out
    if key == "down" then
        zvel = zvel + 1
    end
end
