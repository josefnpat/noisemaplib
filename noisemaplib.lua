local noisemaplib = {}

-- based on https://www.redblobgames.com/maps/terrain-from-noise/

noisemaplib.colors = {
  OCEAN =                       {.047,.219,.317},
  BEACH =                       {.960,.920,.520},
  SCORCHED =                    {.794,.337,.133},
  BARE =                        {.886,.748,.392},
  TUNDRA =                      {.789,.703,.482},
  SNOW =                        {.880,.847,.762},
  TEMPERATE_DESERT =            {.703,.653,.524},
  SHRUBLAND =                   {.551,.703,.524},
  TAIGA =                       {.524,.703,.651},
  GRASSLAND =                   {.319,.754,.493},
  TEMPERATE_DECIDUOUS_FOREST =  {.195,.617,.364},
  TEMPERATE_RAIN_FOREST =       {.760,.474,.236},
  SUBTROPICAL_DESERT =          {.740,.743,.648},
  TROPICAL_SEASONAL_FOREST =    {.376,.789,.323},
  TROPICAL_RAIN_FOREST =        {.216,.863,.133},
}

noisemaplib.drawThemes = {
  elevation = function(elevation,moisture)
    return {elevation,elevation,elevation,1}
  end,
  moisture = function(elevation,moisture)
    return {moisture,moisture,moisture,1}
  end,
  earth = function(elevation,moisture)
    -- adapted from https://www.redblobgames.com/maps/terrain-from-noise/
    if elevation < 0.1 then
      return noisemaplib.colors.OCEAN
    end
    if elevation < 0.12 then
      return noisemaplib.colors.BEACH
    end
    if elevation > 0.8 then
      if moisture < 0.1 then
        return noisemaplib.colors.SCORCHED
      end
      if moisture < 0.2 then
        return noisemaplib.colors.BARE
      end
      if moisture < 0.5 then
        return noisemaplib.colors.TUNDRA
      end
      return noisemaplib.colors.SNOW
    end
    if elevation > 0.6 then
      if moisture < 0.33 then
        return noisemaplib.colors.TEMPERATE_DESERT
      end
      if moisture < 0.66 then
        return noisemaplib.colors.SHRUBLAND
      end
      return noisemaplib.colors.TAIGA
    end
    if elevation > 0.3 then
      if moisture < 0.16 then
        return noisemaplib.colors.TEMPERATE_DESERT
      end
      if moisture < 0.50 then
        return noisemaplib.colors.GRASSLAND
      end
      if moisture < 0.83 then
        return noisemaplib.colors.TEMPERATE_DECIDUOUS_FOREST
      end
      return noisemaplib.colors.TEMPERATE_RAIN_FOREST
    end
    if moisture < 0.16 then
      return noisemaplib.colors.SUBTROPICAL_DESERT
    end
    if moisture < 0.33 then
      return noisemaplib.colors.GRASSLAND
    end
    if moisture < 0.66 then
      return noisemaplib.colors.TROPICAL_SEASONAL_FOREST
    end
    return noisemaplib.colors.TROPICAL_RAIN_FOREST
  end,
}

noisemaplib.drawFunction = {
  default = function(x,y,ox,oy)
    love.graphics.rectangle('fill',ox+x,oy+y,1,1)
  end,
}

noisemaplib.centerDists = {
  default = function(distance)
    return 1
  end,
  valley = function(distance)
    return distance
  end,
  island = function(distance)
    return 1-distance
  end,
  ring = function(distance)
    return math.sin(distance*math.pi)
  end,
}

function noisemaplib.new(init)
  init = init or {}
  local self = {}

  self._width = init.width or 640
  self._height = init.height or 640
  self._elevationScale = init.elevationScale or 1/200
  self._moistureScale = init.moistureScale or 1/100
  self._octaves = init.octaves or 3
  self._powel = init.powel or 2
  self._min = init.min or 0
  self._centerDist = init.centerDist or noisemaplib.centerDists.default
  self._drawTheme = init.drawTheme or noisemaplib.drawThemes.earth
  self._drawFunction = init.drawFunction or noisemaplib.drawFunction.default

  self.get = noisemaplib.get
  self.draw = noisemaplib.draw

  self._seed = init.seed or love.math.random()*1000

  local min,max = math.huge,-math.huge

  local data = {}
  for x = 1,self._width do
    data[x] = {}
    for y = 1,self._height do

      local mx = x*self._moistureScale
      local my = y*self._moistureScale
      local moisture = love.math.noise(mx,my,self._seed)

      local lx = x*self._elevationScale
      local ly = y*self._elevationScale
      local sumelevation = 0
      for i = 1,self._octaves do
        local divisor = 1/i
        sumelevation = sumelevation + divisor*love.math.noise(i*i*lx,i*i*ly,self._seed)
      end
      local elevation = math.pow(sumelevation,self._powel)

      min = math.min(min,sumelevation)
      max = math.max(max,sumelevation)

      local distScale
      if self._centerDist then
        local cx,cy = x-self._width/2,y-self._height/2
        local distance = math.sqrt(cx^2 + cy^2)
        local size = math.min(self._width,self._height)
        local distanceScaled = distance/(size/2)
        distScale = self._centerDist(math.min(1,distanceScaled))
      else
        distScale = 1
      end

      data[x][y] = {
        elevation=elevation*distScale,
        moisture=moisture
      }
    end
  end

  -- normalize
  self._data = {}
  for x = 1,self._width do
    self._data[x] = {}
    for y = 1,self._height do
      local sum = (data[x][y].elevation-min)/(max-min)
      self._data[x][y] = {
        elevation = math.max(self._min,sum),
        moisture = data[x][y].moisture,
      }
    end
  end

  return self
end

function noisemaplib:get(x,y)
  return self._data[x] and self._data[x][y] or nil
end

function noisemaplib:draw(ox,oy)
  ox = ox or 0
  oy = oy or 0
  for x = 1,self._width do
    for y = 1,self._height do
      local data = self._data[x][y]
      local color = self._drawTheme(data.elevation,data.moisture)
      assert(color)
      love.graphics.setColor(color)
      self._drawFunction(x,y,ox,oy)
    end
  end
  love.graphics.setColor(1,1,1,1)
end

return noisemaplib
