Room = class("Room", PhysicalWorld)

function Room:initialize(sandbox)
  PhysicalWorld.initialize(self)
  self.sandbox = sandbox
  self.coins = 10
  self.inWave = false
  self.totalWaves = 10
  self.shakeTimer = 0
  self.shakeAmount = 0
  self.camera.x = love.graphics.width / 2
  self.camera.y = love.graphics.height / 2
  self.showGuide = not sandbox

  self:setupLayers{
    [0] = { 1, pre = postfx.exclude, post = postfx.include }, -- hud
    [1] = 1, -- lighting
    [2] = 1, -- walls
    [3] = 1, -- particle effects
    [4] = 1, -- player
    [5] = 1, -- enemies
    [6] = 1, -- objects
    [7] = 1, -- projectiles
    [8] = 1, -- coins
    [9] = 1, -- bodies
    [10] = 1, -- blood
    [11] = 1 -- floor
  }

  local xmlFile = love.filesystem.read("room.oel")
  self.xml = slaxml:dom(xmlFile).root
  self.width = tonumber(self.xml.attr.width)
  self.height = tonumber(self.xml.attr.height)

  local ent = findChild(self.xml, "Entities")
  local pobj = findChild(ent, "Player")
  self.player = Player:new(tonumber(pobj.attr.x) + Player.width / 2, tonumber(pobj.attr.y) + Player.height / 2)

  local aobj = findChild(ent, "Altar")
  self.altar = Altar:new(tonumber(aobj.attr.x) + Altar.width / 2, tonumber(aobj.attr.y) + Altar.height / 2)

  self:add(self.player, self.altar)
  self.walls = Walls:new(self.xml, self.width, self.height)
  self.floor = Floor:new(self.xml, self.width, self.height)
  self.fallZone = FallZone:new(self.xml)
  self.lighting = Lighting:new(self.width, self.height)
  self.corpseLayer = CorpseLayer:new(self.width, self.height)
  self.floorBlood = FloorBlood:new(self.width, self.height)
  self.hud = HUD:new()
  self:add(self.walls, self.floor, self.fallZone, self.lighting, self.hud, self.corpseLayer, self.floorBlood)

  self.spawnerPositions = {}
  self.spawnerMargin = TILE_SIZE * 3

  for _, v in pairs(findChildren(ent, "SpawnerPos")) do
    local pos = v.attr.position
    local t = { x = v.attr.x, y = v.attr.y }

    if pos == "left" then
      t.x = t.x - self.spawnerMargin
    elseif pos == "right" then
      t.x = t.x + self.spawnerMargin
    elseif pos == "top" then
      t.y = t.y - self.spawnerMargin
    elseif pos == "bottom" then
      t.y = t.y + self.spawnerMargin
    end

    self.spawnerPositions[pos] = t
  end

  for _, v in pairs(findChildren(ent, "Brazier")) do
    self:add(Brazier:new(tonumber(v.attr.x) + Brazier.width / 2, tonumber(v.attr.y) + Brazier.height / 2, self.sandbox))
  end
end

function Room:start()
  if self.sandbox then
    self.player:applySettings(4, 3, 4, 4, 3)
    delay(0.5, function()
      self:startWave(1)
    end)
  end

  self.hud:fadeIn()
  self.hud:updateUpgrades()

  if self.showGuide then
    delay(3, function()
      if self.inWave then return end
      self.hud:showInstructions("Use WASD to move", 3)

      delay(3, function()
        if self.inWave then return end
        self.hud:showInstructions("LMB to shoot", 2.5)

        delay(2.5, function() 
          if self.inWave then return end
          self.hud:showInstructions("Mouse wheel and numbers 1-5 to switch weapons", 4.5)

          delay(5, function()
            if self.inWave then return end
            self.hud:showInstructions("Click on the altar to upgrade your gear and start the next wave", 4.5)

            delay(4.5, function()
              if self.inWave then return end
              self.hud:showInstructions("Collect coins from slain enemies to purchase upgrades", 4)

              delay(4, function()
                if self.inWave then return end
                self.hud:showInstructions("You can also upgrade braziers to turrets by clicking on them", 4)

                delay(4.5, function()
                  if self.inWave then return end
                  self.hud:showInstructions("Protect your lord's altar at all costs!", 4)
                end)
              end)
            end)
          end)
        end)
      end)
    end)
  end
end

function Room:update(dt)
  PhysicalWorld.update(self, dt)

  if self.shakeTimer > 0 then
    self.shakeTimer = self.shakeTimer - dt
    
    if self.camera.x == love.graphics.width / 2 then
      self.camera.x = love.graphics.width / 2 + self.shakeAmount * (1 - 2 * math.random(0, 1))
      self.camera.y = love.graphics.height / 2 + self.shakeAmount * (1 - 2 * math.random(0, 1))
    else
      self.camera.x = love.graphics.width / 2
      self.camera.y = love.graphics.height / 2
    end
  else
    self.camera.x = love.graphics.width / 2
    self.camera.y = love.graphics.height / 2
  end

  if self.inWave then
    if self.wait == "enemies" then
      self.deathTimer = self.deathTimer + dt

      if Enemy.all.length == 0 or self.deathTimer > 30 then
        self.wait = 0
        self.deathTimer = 0
      end
    elseif self.wait > 0 then
      self.wait = self.wait - dt
    else
      local index, rep

      if self.waveNum < self.totalWaves and not self.sandbox then
        index, rep = self["wave" .. self.waveNum](self, self.waveIndex, self.waveReps)
      else
        index, rep = self:waveFinal(self.waveIndex, self.waveReps)
      end

      if index == nil then
        self:endWave()
      else
        self.waveIndex = index
      end

      if rep then
        self.waveReps = self.waveReps + 1
      else
        self.waveReps = 0
      end
    end
  end
end

function Room:shake(time, amount)
  amount = amount or 2

  if self.shakeTimer <= 0 or amount >= self.shakeAmount then
    self.shakeTimer = time
    self.shakeAmount = amount
  end
end

function Room:startWave(num)
  self.hud.disableTooltips = true
  self.hud:hideInstructions()

  self.hud:display("Wave " .. num, 2, function()
    self.inWave = true
    self.waveIndex = 1
    self.waveReps = 0
    self.wait = 0
    self.waveNum = num
    self.deathTimer = 0
    self.altar:switchMode("fire")
    self.player.health = self.player.maxHealth
  end)
end

function Room:nextWave()
  self:startWave((self.waveNum or 0) + 1)
end

function Room:endWave()
  self.hud.disableTooltips = false
  self.inWave = false
  self.altar:switchMode("calm")
  self.hud:updateUpgrades()
end

function Room:gameOver()
  self.hud:fadeOut()
  self.hud:showInstructions("Your lord's altar was destroyed", 3)
  self.hud:display("GAME OVER", 3, function() 
    ammo.world = Menu:new()
  end)
end

function Room:coinCollected()
  self.coins = self.coins + 1
end

function Room:purchaseUpgrade(id)
  local level = self.player[id .. "Level"]
  local upgrade = Player[id .. "Upgrades"][level + 1]

  if upgrade then
    self.player:upgradeTo(id, level + 1)
    self.coins = self.coins - upgrade[2]
  end
end

local function dir(axis)
  if axis == "x" then
    return math.random(1, 2) == 1 and "left" or "right"
  elseif axis == "y" then
    return math.random(1, 2) == 1 and "top" or "bottom"
  else
    local r = math.random(1, 4)

    if r == 1 then
      return "top"
    elseif r == 2 then
      return "bottom"
    elseif r == 3 then
      return "left"
    elseif r == 4 then
      return "right"
    end
  end
end

function Room:wave1(i, r)
  if i == 1 then
    self:add(Spawner:new(dir("y"), 0.8, 15))
    self.wait = "enemies"
    return 2
  else
    return nil
  end
end

function Room:wave2(i, r)
  if i == 1 then
    self:add(Spawner:new(dir("x"), 0.5, 25))
    self.wait = "enemies"
    return 2
  else
    return nil
  end
end

function Room:wave3(i, r)
  if i == 1 then
    self:add(Spawner:new(dir("y"), 1, 20))
    self.wait = 5
    return 2
  elseif i == 2 then
    self:add(Spawner:new("left", 2, 10))
    self.wait = "enemies"
    return 3
  else
    return nil
  end
end

function Room:wave4(i, r)
  if i == 1 then
    self:add(Spawner:new("left", 1.5, 15))
    self:add(Spawner:new("right", 1.5, 15))
    self.wait = "enemies"
    return 2
  elseif i == 2 then
    self:add(Spawner:new(dir("y"), 0.2, 8))
    self.wait = "enemies"
    return 3
  else
    return nil
  end
end

function Room:wave5(i, r)
  if i == 1 then
    self:add(Spawner:new("left", 0.1, 6))
    self.wait = 3
    return 2
  elseif i == 2 then
    self:add(Spawner:new("top", 0.1, 6))
    self.wait = 3
    return 3
  elseif i == 3 then
    self:add(Spawner:new("right", 0.1, 6))
    self.wait = 3
    return 4
  elseif i == 4 then
    self:add(Spawner:new("bottom", 0.1, 6))
    self.wait = 3
    return 5
  elseif i == 5 then
    self:add(Spawner:new("left", 0.1, 3))
    self:add(Spawner:new("top", 0.1, 3))
    self:add(Spawner:new("right", 0.1, 3))
    self:add(Spawner:new("bottom", 0.1, 3))
    self.wait = "enemies"
    return 6
  else
    return nil
  end
end

function Room:wave6(i, r)
  if i == 1 then
    self:add(Spawner:new(dir(), 0.5, 10))
    self:add(Spawner:new(dir(), 0.5, 10))
    self.wait = "enemies"

    if r < 3 then
      return 1, true
    else
      return 2
    end
  else
    return nil
  end
end

function Room:wave7(i, r)
  if i == 1 then
    self:add(Spawner:new(dir(), 0.05, 20))
    self.wait = "enemies"

    if r < 3 then
      return 1, true
    else
      return 2
    end
  else
    return nil
  end
end

function Room:wave8(i, r)
  if i == 1 then
    self:add(Spawner:new(dir(), 0.1, 6))
    self.wait = 3

    if r < 3 then
      return 1, true
    else
      return 2
    end
  elseif i == 2 then
    self:add(Spawner:new(dir(), 0.05, 20))
    self:add(Spawner:new(dir(), 2, 10))
    self.wait = "enemies"
    return 3
  else
    return nil
  end
end

function Room:wave9(i, r)
  if i == 1 then
    self:add(Spawner:new("top", 0.4, 30))
    self.wait = "enemies"
    return 2
  elseif i == 2 then
    self:add(Spawner:new("bottom", 0.4, 30))
    self.wait = "enemies"
    return 3
  else
    return nil
  end
end

function Room:waveFinal(i, r)
  if i == 1 then
    self:finalSpawn()

    if r < 10 then
      return 1, true
    else
      return 2
    end
  elseif i == 2 then
    self.wait = "enemies"
    return 3
  else
    return nil
  end
end

function Room:finalSpawn()
  local r = math.random(1, 10)

  if r == 1 then
    local a = math.random(5, 8)
    self:add(Spawner:new("left", 0.1, a))
    self:add(Spawner:new("top", 0.1, a))
    self:add(Spawner:new("right", 0.1, a))
    self:add(Spawner:new("bottom", 0.1, a))
    self.wait = "enemies"
  elseif r == 2 then
    local a = math.random(5, 8)
    self:add(Spawner:new(dir(), 0.1, a))
    self:add(Spawner:new(dir(), 0.1, a))
    self:add(Spawner:new(dir(), 0.1, a))
    self:add(Spawner:new(dir(), 0.1, a))
    self.wait = "enemies"
  elseif r == 3 then
    self:add(Spawner:new(dir(), 0.05, 25))
    self:add(Spawner:new("top", 0.8, 6))
    self:add(Spawner:new("bottom", 0.8, 6))
    self.wait = "enemies"
  elseif r == 4 then
    self:add(Spawner:new(dir(), 0.3, 10))
    self.wait = 0.1
  elseif r == 5 then
    self:add(Spawner:new(dir(), 0.05, 8))
    self.wait = 0.1
  elseif r == 6 then
    self:add(Spawner:new("top", 0.6, 8))
    self:add(Spawner:new("bottom", 0.6, 8))
    self.wait = 1
  elseif r == 7 then
    local a = math.random(30, 45)
    self:add(Spawner:new(dir(), 0.2, a))
    self.wait = "enemies"
  elseif r == 8 then
    local a = math.random(8, 12)
    self:add(Spawner:new("left", 0.05, a))
    self:add(Spawner:new("top", 0.05, a))
  elseif r == 9 then
    local a = math.random(8, 12)
    self:add(Spawner:new("right", 0.05, a))
    self:add(Spawner:new("bottom", 0.05, a))
  elseif r == 10 then
    self:add(Spawner:new("left", 0.5, 10))
    self:add(Spawner:new("top", 0.4, 10))
    self:add(Spawner:new("right", 0.6, 10))
    self:add(Spawner:new("bottom", 0.5, 10))
    self.wait = "enemies"
  end
end
