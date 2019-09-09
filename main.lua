local WIDTH, HEIGHT = 1024, 768

local SIZE = math.min(WIDTH, HEIGHT) / 2

local zoom = 1

local scale = 1

local vel = 0

local universe

function love.load()
    love.window.setTitle("Mima")

    -- Set up the display
    --WIDTH, HEIGHT = love.window.getDesktopDimensions()
    love.window.setFullscreen(false)
    love.window.setMode(WIDTH, HEIGHT)
    love.mouse.setVisible(false)

    love.math.setRandomSeed(10)

    universe = make_universe()
end

function make_size(variability)
    local a = SIZE / variability
    local b = SIZE - a

    return b * love.math.random() + a
end

function draw(d)
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

    effective_size = (d.size * 2) / scale * zoom
    if effective_size <= 1 then
        c[4] = effective_size / 2
        love.graphics.setColor(c)
        love.graphics.circle("fill", 0, 0, scale / zoom)
        return
    elseif effective_size <= 10 then
        c[4] = 0.5 + (10 - effective_size) / 20
        love.graphics.setColor(c)
        love.graphics.circle("fill", 0, 0, d.size)
        return
    end

    d:draw()
end

function draw_planet(p)
    c = p.colour
    c[4] = 0.5

    love.graphics.setColor(c)
    love.graphics.circle("fill", 0 ,0, p.size)

    c[4] = 1
    love.graphics.setColor(c)
    love.graphics.circle("line", 0 ,0, p.size)
end

function make_planet()
    return {
        size = make_size(10),
        draw = draw_planet,
        colour = {love.math.random(), love.math.random(), love.math.random()},
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
        size = make_size(100),
        draw = draw_star,
        colour = {1, love.math.random(), 0},
    }
end

function draw_solar_system(ss)
    -- Suns
    love.graphics.push()
    scale = scale * 50
    love.graphics.scale(1/50)
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
    scale = scale / 50
    love.graphics.pop()

    -- Planets
    for _, p in ipairs(ss.planets) do
        -- Orbit
        love.graphics.setColor(1, 1, 1, 0.1)
        love.graphics.circle("line", 0, 0, p.d)

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

function make_solar_system()
    ss = {
        size = make_size(2),
        draw = draw_solar_system,
        suns = {},
        planets = {},
    }

    for i = 1, 1 + love.math.random() * 2 do
        ss.suns[#ss.suns + 1] = make_star()
    end

    for i = 1, love.math.random() * 10 do
        ss.planets[#ss.planets + 1] = {
            a = math.pi * 2 * love.math.random(),
            d = ss.size * love.math.random(),
            planet = make_planet(),
        }
    end

    return ss
end

function draw_galaxy(g)
    -- Cloud
    love.graphics.setColor(1, 1, 1, 0.1)
    love.graphics.circle("fill", 0, 0, g.size)

    -- Systems
    for _, s in ipairs(g.systems) do
        love.graphics.push()
        love.graphics.translate(s.d * math.cos(s.a), s.d * math.sin(s.a))
        scale = scale * 100
        love.graphics.scale(1/100)
        draw(s.system)
        scale = scale / 100
        love.graphics.pop()
    end
end

function make_galaxy()
    g = {
        size = make_size(20),
        draw = draw_galaxy,
        systems = {},
    }

    for i = 1, 50 + love.math.random() * 50 do
        g.systems[#g.systems + 1] = {
            a = math.pi * 2 * love.math.random(),
            d = g.size * love.math.random(),
            system = make_solar_system(),
        }
    end

    return g
end

function draw_universe(u)
    -- Cloud
    love.graphics.setColor(0, 0, 1, 0.1)
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

function make_universe()
    u = {
        size = SIZE,
        draw = draw_universe,
        galaxies = {},
    }

    for i = 1, 500 + love.math.random() * 500 do
        u.galaxies[#u.galaxies + 1] = {
            a = math.pi * 2 * love.math.random(),
            d = u.size - (u.size * love.math.random() * love.math.random()),
            galaxy = make_galaxy(),
        }
    end

        u.galaxies[#u.galaxies + 1] = {
            a = 0,
            d = 0,
            galaxy = make_galaxy(),
        }

    return u
end

function love.update(dt)
    if vel > 0 then
        zoom = zoom + (zoom / 2) * dt
    elseif vel < 0 then
        zoom = zoom - (zoom / 2) * dt
    end
end

function love.draw()
    love.graphics.clear()

    love.graphics.push()
    love.graphics.translate(WIDTH/2, HEIGHT/2)
    scale = 1
    love.graphics.scale(zoom)
    universe.draw(universe)
    love.graphics.pop()
end

function love.keypressed(key)
    if key == "q" or key == "escape" then
        love.event.quit()
    end

    if key == "up" then
        vel = vel + 1
    elseif key == "down" then
        vel = vel - 1
    end
end

function love.keyreleased(key)
    if key == "up" then
        vel = vel - 1
    elseif key == "down" then
        vel = vel + 1
    end
end
