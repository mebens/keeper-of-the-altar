Lighting = class("Lighting", Entity)

function makeLightImage(radius, inner, intensity)
  local data = love.image.newImageData(radius * 2, radius * 2)
  inner = inner or 0
  intensity = intensity or 1
  
  data:mapPixel(function(x, y)
    local dist = math.distance(radius, radius, x, y)
    return 255, 255, 255, (dist <= radius and math.min(255, math.scale(dist, inner, radius, 255 * intensity, 0)) or 0)
  end)
  
  return love.graphics.newImage(data)
end


function Lighting:initialize(width, height)
  Entity.initialize(self)
  self.layer = 1
  self.visible = true
  self.width = width
  self.height = height
  self.canvas = love.graphics.newCanvas(love.graphics.width, love.graphics.height)
  self.lights = LinkedList:new()
  self.ambient = 20
end

function Lighting:draw()
  self.world.camera:unset()

  self.canvas:renderTo(function()
    love.graphics.clear(self.ambient, self.ambient, self.ambient)
  end)

  for light in self.lights:iterate() do
    if light.alpha > 0 then
      self.world.camera:set()
      love.graphics.setCanvas(self.canvas)
      love.graphics.setColor(light.color[1], light.color[2], light.color[3], light.alpha)
      love.graphics.draw(light.image, light.x - light.radius, light.y - light.radius)
      self.world.camera:unset()
    end
  end

  love.graphics.setColor(255, 255, 255)
  love.graphics.setBlendMode("alpha")
  love.graphics.setCanvas(postfx.alternate)
  love.graphics.draw(postfx.canvas, 0, 0)
  love.graphics.setBlendMode("multiply")
  love.graphics.draw(self.canvas, 0, 0)
  love.graphics.setBlendMode("alpha")
  postfx.swap()
  self.world.camera:set()
end

function Lighting:add(x, y, radius, innerRadius, intensity)
  local t = {
    x = x,
    y = y,
    color = { 255, 255, 255 },
    alpha = 255,
    radius = radius,
    image = makeLightImage(radius, innerRadius, intensity),
    type = "circle"
  }
  
  self.lights:push(t)
  return t
end

function Lighting:addImage(img, x, y, radius)
  local t = {
    x = x,
    y = y,
    radius = radius,
    color = { 255, 255, 255 },
    alpha = 255,
    image = img
  }

  self.lights:push(t)
  return t
end

function Lighting:remove(t)
  self.lights:remove(t)
end

function Lighting:clear()
  self.lights:clear()
end