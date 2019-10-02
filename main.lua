noisemaplib = require"noisemaplib"

-- https://gist.github.com/jdev6/1e7ff30671edf88d03d4
function randomchoice(t) --Selects a random item from a table
    local keys = {}
    for key, value in pairs(t) do
        keys[#keys+1] = key --Store keys in another table
    end
    index = keys[math.random(1, #keys)]
    return t[index]
end

function love.load()
  map_x = 8
  map_y = 8
  map_w = love.graphics.getWidth()-map_x*2
  map_h = love.graphics.getHeight()-map_y*2
  map = noisemaplib.new{
    width=map_w,
    height=map_h,
    centerDist=randomchoice(noisemaplib.centerDists),
  }
end

function love.draw()
  love.graphics.rectangle("line",
    map_x+0.5,
    map_y+0.5,
    map_w+1.5,
    map_h+1.5)
  map:draw(map_x,map_y)

  local str = ""

  local mx,my = love.mouse.getPosition()
  local dx,dy = mx-map_x,my-map_y
  local target = map:get(dx,dy)
  if target then
    local e = math.floor(target.elevation*100)/100
    local m = math.floor(target.moisture*100)/100
    str = str .. "x:"..dx..", y:"..dy..", e:"..e..", m:"..m
  end

  love.graphics.print(str)
end

function love.keypressed(key)
  if key == "g" then
    love.load()
  end
end

function love.resize()
  love.load()
end
