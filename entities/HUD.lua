HUD = class("HUD", Entity)

function HUD:initialize()
  Entity.initialize(self)
  self.layer = 0
  self.coinImg = assets.images.coinHUD
  self.coinText = Text:new{0, x = 25, y = 5, font = assets.fonts.main[18], shadow = true}
  self.weaponText = Text:new{"", x = 6, y = 5, width = love.graphics.width - 12, font = assets.fonts.main[18], align = "right", shadow = true}

  self.ttText = Text:new{"", font = assets.fonts.main[12]}
  self.ttScissor = 0
  self.ttOpen = false

  self.purchaseDeniedTimer = 0
  self.upgradesVisible = true
  self.upgradesAlpha = 0
  self.upgradeItemPadding = 10
  self.upgradeScreenPadding = 40
  self.upgradeInnerPadding = 8
  self.upgradeY = 200
  self.upgradeHeight = 180
  self.upgrades = {}
  self.upgradesTitle = Text:new{
    "UPGRADES",
    x = 0,
    y = 135,
    width = love.graphics.width - self.upgradeScreenPadding + 4,
    font = assets.fonts.main[48],
    align = "right",
    shadow = true
  }

  self.buttonWidth = 100
  self.buttonHeight = 40
  self.readyBtn = self:makeButton("READY", "left")
  self.closeBtn = self:makeButton("CLOSE", "right")

  self:addUpgrade("smg", "SMG", 1)
  self:addUpgrade("mg", "Machine Gun", 0)
  self:addUpgrade("sg", "Shotgun", 0)
  self:addUpgrade("laser", "Laser", 0)
  self:addUpgrade("rpg", "RPG", 0)
end

function HUD:update(dt)
  self.coinText.text = self.world.coins
  self.weaponText.text = tostring(self.world.player.weaponIndex) .. ": " .. self.world.player.weapon

  if self.ttOpen then
    if self.ttScissor < 1 then
      self.ttScissor = self.ttScissor + dt * 3
    end

    if input.released("upgrade") then
      if self.ttID:isInstanceOf(Altar) then
        self:showPlayerUpgrades()
      elseif self.ttID == "brazier" then
        --
      end
    elseif input.released("repair") then

    end
  elseif self.ttScissor > 0 then
    self.ttScissor = math.max(self.ttScissor - dt * 3, 0)
  end

  local mx, my = love.mouse.getPosition()
  self.ttText.x = mx + 3
  self.ttText.y = my + 2

  if self.upgradesVisible then
    if self.upgradesAlpha < 255 then
      self.upgradesAlpha = math.min(self.upgradesAlpha + 510 * dt, 255)
    end

    local width = (love.graphics.width - (#self.upgrades - 1) * self.upgradeItemPadding - self.upgradeScreenPadding * 2) / #self.upgrades

    for i, v in ipairs(self.upgrades) do
      local x = self.upgradeScreenPadding + (i - 1) * (width + self.upgradeItemPadding)

      if mx > x and mx < x + width and my > self.upgradeY and my < self.upgradeY + self.upgradeHeight and input.released("upgrade") then
        --if self.world.coins >= tonumber(v.cost.text) then
          self.world:purchaseUpgrade(v.id)
          self:updateUpgrades()
        --else
        --  self.purchaseDeniedTimer = 0.2
        --  self.purchaseDeniedID = v.id
        --end
      end
    end

    for i = 1, 2 do
      local btn = i == 1 and self.readyBtn or self.closeBtn

      if mx > btn.x and mx < btn.x + self.buttonWidth and my > btn.y and my < btn.y + self.buttonHeight and input.released("upgrade") then
        if i == 1 then
          self:hidePlayerUpgrades()
          self.world:nextWave()
        else
          self:hidePlayerUpgrades()
        end
      end
    end
  elseif self.upgradesAlpha > 0 then
    self.upgradesAlpha = math.max(self.upgradesAlpha - 510 * dt, 0)
  end

  if self.purchaseDeniedTimer > 0 then
    self.purchaseDeniedTimer = self.purchaseDeniedTimer - dt
  end
end

function HUD:draw()
  love.graphics.draw(self.coinImg, 6, 8)
  self.coinText:draw()

  if self.world.player.weapon == "laser" then
    local gb = 255 - 255 * (self.world.player.laserHeat / self.world.player.laserHeatLimit)
    self.weaponText.color[2] = gb
    self.weaponText.color[3] = gb
  else
    self.weaponText.color[2] = 255
    self.weaponText.color[3] = 255
  end

  self.weaponText:draw()

  local mx, my = love.mouse.getPosition()

  if self.ttScissor > 0 then
    local width = self.ttText.fontWidth + 3
    local height = self.ttText.fontHeight + 2
    love.graphics.setColor(120, 120, 120, 180)
    love.graphics.rectangle("fill", mx, my, width * self.ttScissor, height)
    love.graphics.setColor(255, 255, 255)
    self.ttText.color[4] = 255 * self.ttScissor
    self.ttText:draw()
  end

  if self.upgradesAlpha > 0 then
    local width = (love.graphics.width - (#self.upgrades - 1) * self.upgradeItemPadding - self.upgradeScreenPadding * 2) / #self.upgrades
    self.upgradesTitle.color[4] = self.upgradesAlpha
    self.upgradesTitle:draw()

    for i, v in ipairs(self.upgrades) do
      local x = self.upgradeScreenPadding + (i - 1) * (width + self.upgradeItemPadding)
      local bgColor = 120

      if mx > x and mx < x + width and my > self.upgradeY and my < self.upgradeY + self.upgradeHeight then
        bgColor = 180
      end

      if self.purchaseDeniedTimer > 0 and self.purchaseDeniedID == v.id then
        love.graphics.setColor(bgColor, 0, 0, 180 * (self.upgradesAlpha / 255))
      else
        love.graphics.setColor(bgColor, bgColor, bgColor, 180 * (self.upgradesAlpha / 255))
      end
      love.graphics.rectangle("fill", x, 200, width, self.upgradeHeight)
      love.graphics.setColor(255, 255, 255, 255)
      v.title.color[4] = self.upgradesAlpha
      v.text.color[4] = self.upgradesAlpha
      v.cost.color[4] = self.upgradesAlpha
      --love.graphics.rectangle("line", v.title.x, v.title.y, v.title.width, v.title.fontHeight)
      v.title:draw()
      v.text:draw()
      v.cost:draw()
      local iw, ih = self.coinImg:getWidth(), self.coinImg:getHeight()
      love.graphics.setColor(255, 255, 255, self.upgradesAlpha)
      love.graphics.draw(self.coinImg, x + width / 2 - v.cost.fontWidth / 2 - iw / 2 - 8, v.cost.y + 1, 0, 0.8, 0.8)--, -iw / 2, -ih / 2)
    end

    for i = 1, 2 do
      local btn = i == 1 and self.readyBtn or self.closeBtn
      local bgColor = 120

      if mx > btn.x and mx < btn.x + self.buttonWidth and my > btn.y and my < btn.y + self.buttonHeight then
        bgColor = 180
      end

      love.graphics.setColor(bgColor, bgColor, bgColor, 180 * (self.upgradesAlpha / 255))
      love.graphics.rectangle("fill", btn.x, btn.y, self.buttonWidth, self.buttonHeight)
      love.graphics.setColor(255, 255, 255)
      btn.text.color[4] = self.upgradesAlpha
      btn.text:draw()
    end
  end

  love.graphics.setColor(255, 255, 255)
end

function HUD:displayTooltip(id, text, cost)
  if self.disableTooltips then return end
  self.ttID = id
  self.ttText.text = text
  self.ttOpen = true
  love.mouse.setVisible(false)
end

function HUD:closeTooltip()
  love.mouse.setVisible(true)
  self.ttOpen = false
end

function HUD:showPlayerUpgrades()
  self.disableTooltips = true
  self:closeTooltip()
  self.upgradesVisible = true
end

function HUD:hidePlayerUpgrades()
  self.disableTooltips = false
  self.upgradesVisible = false
end

function HUD:addUpgrade(id, title, level)
  local i = #self.upgrades + 1
  local totalUpgrades = 5 -- bit of a hack here
  local width = (love.graphics.width - (totalUpgrades - 1) * self.upgradeItemPadding - self.upgradeScreenPadding * 2) / totalUpgrades - self.upgradeInnerPadding * 2 
  local x = self.upgradeScreenPadding + (i - 1) * (width + self.upgradeItemPadding + self.upgradeInnerPadding * 2) + self.upgradeInnerPadding

  local t = {
    id = id,
    title = Text:new{title, x = x, y = self.upgradeY + self.upgradeInnerPadding * 2, width = width, font = assets.fonts.main[24], align = "center"},
    level = level,
    text = Text:new{"Fully Upgraded", x = x, y = self.upgradeY + self.upgradeInnerPadding, width = width, font = assets.fonts.main[12], align = "center"},
    cost = Text:new{0, x = x, width = width, font = assets.fonts.main[12], align = "center"}
  }

  t.text.y = t.title.y + t.title.fontHeight + 50
  t.cost.y = self.upgradeY + self.upgradeHeight - t.cost.fontHeight - self.upgradeInnerPadding
  self.upgrades[i] = t
end

function HUD:updateUpgrades()
  for _, v in pairs(self.upgrades) do
    v.level = self.world.player[v.id .. "Level"]
    local upgrade = Player[v.id .. "Upgrades"][v.level + 1]

    if upgrade then
      v.text.text = upgrade[1]
      v.cost.text = upgrade[2]
    else
      v.text.text = "Fully Upgraded"
      v.cost.text = 0
    end
  end
end

function HUD:makeButton(text, pos)
  local t = {
    text = Text:new{text, width = self.buttonWidth, font = assets.fonts.main[18], align = "center"},
    x = pos == "left" and self.upgradeScreenPadding or love.graphics.width - self.upgradeScreenPadding - self.buttonWidth,
    y = 500
  }

  t.text.x = t.x
  t.text.y = t.y + self.buttonHeight / 2 - t.text.fontHeight / 2
  return t
end
