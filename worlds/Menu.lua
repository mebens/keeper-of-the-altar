Menu = class("Menu", World)

function Menu:initialize()
  World.initialize(self)
  self.title = Text:new{"Keeper of the Altar", x = 0, y = 320, width = love.graphics.width, font = assets.fonts.main[48], align = "center"}
  self.fadeAlpha = 255
  self.image = assets.images.menuHead
  self.image:setFilter("linear", "linear")
  self.scale = 0.9

  self.description = Text:new{
    "A keeper will rarely see any action. Not you.\nToday legions of knights in shining armour descend upon the dark lord's sanctuary.\n\nDefend his altar by any means necessary.",
    x = 100, y = 500, width = love.graphics.width - 200, font = assets.fonts.main[18], align = "center"
  }

  self.buttons = {}
  self.buttonY = 400
  self.buttonWidth = 150
  self.buttonHeight = 50

  self:addButton("Normal", "left", function()
    self:fadeOut(function() 
      ammo.world = Room:new()
    end)
  end)

  self:addButton("Sandbox", "center", function()
    self:fadeOut(function()
      ammo.world = Room:new(true)
    end)
  end)

  self:addButton("Quit", "right", function()
    love.event.quit()
  end)
end

function Menu:start()
  self:fadeIn()
  self:scaleUp()
end

function Menu:draw()
  World.draw(self)

  postfx.exclude()
  love.graphics.draw(self.image, love.graphics.width / 2, self.image:getHeight() / 2, 0, self.scale, self.scale, self.image:getWidth() / 2, self.image:getHeight() / 2)

  self.title:draw()
  self.description:draw()
  local mx, my = love.mouse.getPosition()
  mx, my = mx + love.graphics.width / 2, my + love.graphics.height / 2
  --love.graphics.setPointSize(20)
  --love.graphics.points(mx, my)

  for i, v in ipairs(self.buttons) do
    local bgColor = 120

    if mx > v.x and mx < v.x + self.buttonWidth and my > v.y and my < v.y + self.buttonHeight then
      bgColor = 180

      if mouse.down[1] then
        v.func()
        playSound("upgrade2")
      end
    end

    love.graphics.setColor(bgColor, bgColor, bgColor, 180)
    love.graphics.rectangle("fill", v.x, v.y, self.buttonWidth, self.buttonHeight)
    love.graphics.setColor(255, 255, 255)
    v.text:draw()
  end

  if self.fadeAlpha > 0 then
    love.graphics.setColor(0, 0, 0, self.fadeAlpha)
    love.graphics.rectangle("fill", 0, 0, love.graphics.width, love.graphics.height)
    love.graphics.setColor(255, 255, 255)
  end

  postfx.include()
end

function Menu:addButton(title, pos, func)
  local t = {
    text = Text:new{title, width = self.buttonWidth, font = assets.fonts.main[24], align = "center"},
    x = pos == "left" and 100 or (pos == "right" and love.graphics.width - 100 - self.buttonWidth or love.graphics.width / 2 - self.buttonWidth / 2),
    y = self.buttonY,
    func = func
  }

  t.text.x = t.x
  t.text.y = t.y + self.buttonHeight / 2 - t.text.fontHeight / 2
  self.buttons[#self.buttons + 1] = t
  return t
end

function Menu:fadeOut(func)
  tween(self, 0.5, { fadeAlpha = 255 }, nil, func)
end

function Menu:fadeIn(func)
  tween(self, 0.5, { fadeAlpha = 0 }, nil, func)
end

function Menu:scaleUp()
  tween(self, 4, { scale = 1.1 }, nil, self.scaleDown, self)
end

function Menu:scaleDown()
  tween(self, 4, { scale = 0.9 }, nil, self.scaleUp, self)
end

