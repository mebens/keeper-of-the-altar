Menu = class("Menu", World)

function Menu:initialize()
  World.initialize(self)
  self.title = Text:new{"LD37", x = 0, y = 200, width = love.graphics.width, font = assets.fonts.main[48], align = "center"}
  self.fadeAlpha = 255

  self.buttons = {}
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
end

function Menu:draw()
  World.draw(self)

  postfx.exclude()
  self.title:draw()
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
    y = 500,
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

