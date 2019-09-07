local WIDTH, HEIGHT = 800, 600

local SIZE = math.min(WIDTH, HEIGHT) / 2

local zoom = 1

local vel = 0

local universe

function love.load()
    love.window.setTitle("Mima")

    -- Set up the display
    --WIDTH, HEIGHT = love.window.getDesktopDimensions()
    love.window.setFullscreen(false)
    love.window.setMode(WIDTH, HEIGHT)
    love.mouse.setVisible(false)

    love.math.setRandomSeed(2)

    universe = make_universe()
end

function make_size(variability)
    local a = SIZE / variability
    local b = SIZE - a

    return a * love.math.random() + b
end

function draw_planet(p)
    c = p.colour
    c[4] = 0.5

    love.graphics.setColor(c, 0.5)
    love.graphics.circle("fill", 0 ,0, p.size)

    c[4] = 1
    love.graphics.setColor(c, 1)
    love.graphics.circle("line", 0 ,0, p.size)
end

function make_planet()
    return {
        size = make_size(5),
        draw = draw_planet,
        colour = {love.math.random(), love.math.random(), love.math.random()},
    }
end

function draw_star(s)
    c = s.colour
    c[4] = 0.5

    love.graphics.setColor(c, 0.5)
    love.graphics.circle("fill", 0 ,0, s.size)

    c[4] = 1
    love.graphics.setColor(c, 1)
    love.graphics.circle("line", 0 ,0, s.size)
end

function make_star()
    return {
        size = make_size(10),
        draw = draw_star,
        colour = {1, love.math.random(), 0},
    }
end

function draw_solar_system(ss)
    -- Suns
    love.graphics.push()
    love.graphics.scale(1/50)
    if #ss.suns == 1 then
        ss.suns[1].draw(ss.suns[1])
    else
        local a = math.pi * 2 / #ss.suns

        for i = 1, #ss.suns do
            love.graphics.push()
            love.graphics.translate(SIZE * math.cos(a * i), SIZE * math.sin(a * i))
            ss.suns[i].draw(ss.suns[i])
            love.graphics.pop()
        end
    end
    love.graphics.pop()

    -- Planets
    local d = ss.size / #ss.planets
    local a = math.pi * 2 / #ss.planets

    for i = 1, #ss.planets do
        -- Orbit
        love.graphics.setColor(1, 1, 1, 0.1)
        love.graphics.circle("line", 0, 0, d * i)

        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.push()
        love.graphics.translate(d * i * math.cos(a * i), d * i * math.sin(a * i))
        love.graphics.scale(1/100)
        ss.planets[i].draw(ss.planets[i])
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
        ss.planets[#ss.planets + 1] = make_planet()
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
        love.graphics.scale(1/100)
        s.system.draw(s.system)
        love.graphics.pop()
    end
end

function make_galaxy()
    g = {
        size = make_size(1),
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
        love.graphics.scale(1/100)
        g.galaxy.draw(g.galaxy)
        love.graphics.pop()
    end
end

function make_universe()
    u = {
        size = make_size(1),
        draw = draw_universe,
        galaxies = {},
    }

    for i = 1, 5 + love.math.random() * 50 do
        u.galaxies[#u.galaxies + 1] = {
            a = math.pi * 2 * love.math.random(),
            d = u.size * love.math.random(),
            galaxy = make_galaxy(),
        }
    end

    return u
end

function love.update(dt)
    if vel > 0 then
        zoom = zoom + (zoom / 10) * dt
    elseif vel < 0 then
        zoom = zoom + (zoom / 10) * dt
    end
end

function love.draw()
    love.graphics.clear()

    love.graphics.push()
    love.graphics.translate(WIDTH/2, HEIGHT/2)
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
