CorpseLayer = class("CorpseLayer", Entity)

function CorpseLayer:initialize(width, height)
  Entity.initialize(self)
  self.layer = 9
  self.canvas = love.graphics.newCanvas(width, height)
end

function CorpseLayer:drawMap(obj)
  self.canvas:renderTo(function()
    obj:drawMap()
  end)
end

function CorpseLayer:draw()
  love.graphics.setColor(200, 200, 200)
  love.graphics.draw(self.canvas)
end