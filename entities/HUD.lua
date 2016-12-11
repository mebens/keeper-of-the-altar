HUD = class("HUD", Entity)

function HUD:initialize()
  Entity.initialize(self)
  self.layer = 0
  self.fadeAlpha = 255
  self.coinImg = assets.images.coinHUD
  self.coinText = Text:new{0, x = 25, y = 5, font = assets.fonts.main[18], shadow = true}
  self.weaponText = Text:new{x = 6, y = 5, width = love.graphics.width - 12, font = assets.fonts.main[18], align = "right", shadow = true}

  self.weaponList = Text:new{x = 6, y = 30, width = love.graphics.width - 12, font = assets.fonts.main[12], align = "right", shadow = true}

  self.ttText = Text:new{"", font = assets.fonts.main[12]}
  self.ttScissor = 0
  self.ttOpen = false

  self.purchaseDeniedTimer = 0
  self.upgradesVisible = false
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

  self:addUpgrade("smg", "SMG", 1)
  self:addUpgrade("mg", "Machine Gun", 0)
  self:addUpgrade("sg", "Shotgun", 0)
  self:addUpgrade("laser", "Laser", 0)
  self:addUpgrade("rpg", "RPG", 0)

  self.buttonWidth = 150
  self.buttonHeight = 40
  self.readyBtn = self:makeButton("NEXT WAVE", "center")
  self.closeBtn = self:makeButton("CLOSE", "left")
  self.menuBtn = self:makeButton("EXIT TO MENU", "right")

  self.altarWidth = 300
  self.altarHeight = 22
  self.altarText = Text:new{x = love.graphics.width / 2 - self.altarWidth / 2, width = self.altarWidth, font = assets.fonts.main[18], align = "center", shadow = true}
  self.altarText.y = self.altarText.fontHeight / 2 - 1

  self.bigText = Text:new{x = 0, width = love.graphics.wdith, font = assets.fonts.main[48], align = "center", shadow = true}
  self.bigText.y = love.graphics.height / 2 - self.bigText.fontHeight
  self.bigText.color[4] = 0  
  self.bigTextTimer = 0

  self.instructions = Text:new{x = 100, y = 600, width = love.graphics.width - 200, font = assets.fonts.main[18], align = "center", shadow = true}
  self.instructions.color[4] = 0
  self.instructionsTimer = 0
end

function HUD:update(dt)
  self.coinText.text = self.world.coins
  self.weaponText.text = tostring(self.world.player.weaponIndex) .. ": " .. self.world.player.weapon
  self.altarText.text = self.world.altar.health

  local txt = ""

  for i, v in ipairs{"smg", "mg", "sg", "laser", "rpg"} do
    if self.world.player.weapon ~= v and self.world.player[v .. "Unlocked"] then
      txt = txt .. tostring(i) .. ": " .. string.upper(v) .. "\n"
    end
  end

  self.weaponList.text = txt

  if self.ttOpen then
    if self.ttScissor < 1 then
      self.ttScissor = self.ttScissor + dt * 3
    end

    if input.released("upgrade") then
      if self.ttID:isInstanceOf(Altar) then
        self:showPlayerUpgrades()
      elseif self.ttID:isInstanceOf(Brazier) then --and self.world.coins >= self.ttCost then
        self.ttID:makeTurret()
        self:closeTooltip()
        self.world.coins = self.world.coins - self.ttCost
        playSound("upgrade")
      end
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
        if self.world.coins >= tonumber(v.cost.text) then
          self.world:purchaseUpgrade(v.id)
          self:updateUpgrades()
          playSound("upgrade")
        else
         self.purchaseDeniedTimer = 0.2
         self.purchaseDeniedID = v.id
        end
      end
    end

    for i = 1, 3 do
      local btn = i == 1 and self.readyBtn or (i == 2 and self.closeBtn or self.menuBtn)

      if mx > btn.x and mx < btn.x + self.buttonWidth and my > btn.y and my < btn.y + self.buttonHeight and input.released("upgrade") then
        if i == 1 then
          self:hidePlayerUpgrades()
          self.world:nextWave()
          playSound("upgrade2")
        elseif i == 2 then
          self:hidePlayerUpgrades()
          playSound("upgrade2")
        else
          self:fadeOut()
          delay(0.5, function() ammo.world = Menu:new() end)
          playSound("upgrade2")
        end
      end
    end
  elseif self.upgradesAlpha > 0 then
    self.upgradesAlpha = math.max(self.upgradesAlpha - 510 * dt, 0)
  end

  if self.purchaseDeniedTimer > 0 then
    self.purchaseDeniedTimer = self.purchaseDeniedTimer - dt
  end

  if self.bigTextTimer > 0 then
    self.bigTextTimer = self.bigTextTimer - dt

    if self.bigTextTimer <= 0 then
      self.bigText.color[4] = 0

      if self.bigTextCallback then
        self.bigTextCallback()
        self.bigTextCallback = nil
      end
    end
  end

  if self.instructionsTimer > 0 then
    self.instructionsTimer = self.instructionsTimer - dt

    if self.instructionsTimer <= 0 then
      self:hideInstructions()
    end
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
  self.weaponList:draw()

  love.graphics.setColor(100, 100, 100, 150)
  love.graphics.rectangle("fill", love.graphics.width / 2 - self.altarWidth / 2, 8, self.altarWidth, self.altarHeight)
  love.graphics.setColor(95, 10, 10, 255)
  local ratio = self.world.altar.health / self.world.altar.maxHealth
  love.graphics.rectangle("fill", love.graphics.width / 2 - self.altarWidth / 2, 8, self.altarWidth * ratio, self.altarHeight)
  love.graphics.setColor(255, 255, 255, 255)
  self.altarText:draw()

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

    for i = 1, 3 do
      local btn = i == 1 and self.readyBtn or (i == 2 and self.closeBtn or self.menuBtn)
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

  if self.fadeAlpha > 0 then
    love.graphics.setColor(0, 0, 0, self.fadeAlpha)
    love.graphics.rectangle("fill", 0, 0, love.graphics.width, love.graphics.height)
    love.graphics.setColor(255, 255, 255)
  end

  if self.instructions.color[4] > 0 then self.instructions:draw() end
  if self.bigTextTimer > 0 then self.bigText:draw() end
  love.graphics.setColor(255, 255, 255)
end

function HUD:fadeIn()
  if self.fadeTween then self.fadeTween:stop() end
  self.fadeTween = self:animate(0.5, { fadeAlpha = 0 })
end

function HUD:fadeOut()
  if self.fadeTween then self.fadeTween:stop() end
  self.fadeTween = self:animate(0.5, { fadeAlpha = 255 })
end

function HUD:display(text, time, callback)
  self:closeTooltip()
  self.bigText.text = text
  self.bigText.color[4] = 255
  self.bigTextTimer = time
  self.bigTextCallback = callback
end

function HUD:showInstructions(text, time)
  self.instructions.text = text
  if self.instructionsTween then self.instructionsTween:stop() end
  self.instructionsTween = tween(self.instructions.color, 0.25, { [4] = 255 })
  self.instructionsTimer = time
end

function HUD:hideInstructions()
  self.instructionsTimer = 0
  if self.instructionsTween then self.instructionsTween:stop() end

  if self.instructions.color[4] > 0 then
    self.instructionsTween = tween(self.instructions.color, 0.25, { [4] = 0 })
  end
end

function HUD:displayTooltip(id, text, cost)
  if self.disableTooltips then return end
  self.ttID = id

  if cost then
    self.ttText.text = text .. " (" .. tostring(cost) .. "G)"
  else
    self.ttText.text = text
  end

  self.ttCost = cost
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
  playSound("upgrade-screen")
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
    x = pos == "left" and 100 or (pos == "right" and love.graphics.width - 100 - self.buttonWidth or love.graphics.width / 2 - self.buttonWidth / 2),
    y = 500
  }

  t.text.x = t.x
  t.text.y = t.y + self.buttonHeight / 2 - t.text.fontHeight / 2
  return t
end
