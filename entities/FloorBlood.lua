FloorBlood = class("FloorBlood", Entity)

function FloorBlood:initialize(width, height)
  Entity.initialize(self)
  self.layer = 10
  self.canvas = love.graphics.newCanvas(width, height)
end

function FloorBlood:draw()
  love.graphics.setColor(160, 160, 160)
  love.graphics.draw(self.canvas)
end

function FloorBlood:bleed(x, y, size, scatter)
  self.canvas:renderTo(function()
    love.graphics.setPointSize(size)
    love.graphics.setColor(math.random(190, 130), 0, 0)
    love.graphics.points(x, y)
    love.graphics.setPointSize(1)
    scatter = scatter or 2
    size = size / 2 + scatter
    
    for i = 1, math.random(2, 5) * scatter do
      love.graphics.setColor(math.random(190, 130), 0, 0)
      love.graphics.points(math.random(x - size, x + size), math.random(y - size, y + size))
    end
    
    love.graphics.setColor(math.random(230, 200), 0, 0)
    love.graphics.points(x, y)
  end)
  
  love.graphics.setColor(255, 255, 255)
end

