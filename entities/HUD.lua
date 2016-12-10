HUD = class("HUD", Entity)

function HUD:initialize()
  Entity.initialize(self)
  self.layer = 0
  self.coinImg = assets.images.coinHUD
  self.coinText = Text:new{0, x = 25, y = 5, font = assets.fonts.main[18]}
end

function HUD:update(dt)
  self.coinText.text = self.world.coins
end

function HUD:draw()
  love.graphics.draw(self.coinImg, 6, 8)
  self.coinText:draw()

  -- local mx, my = love.mouse.getPosition()
  -- local imgW = assets.images.crosshair:getWidth()
  -- local imgH = assets.images.crosshair:getHeight()
  
  -- love.graphics.setColor(20, 20, 20)
  -- love.graphics.draw(assets.images.crosshair, mx, my, 0, 1, 1, imgW / 2, imgH / 2)
  -- love.graphics.setColor(255, 255, 255)
  -- love.graphics.draw(assets.images.crosshair, mx - 1, my - 1, 0, 1, 1, imgW / 2, imgH / 2)
end
