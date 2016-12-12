Player = class("Player", PhysicalEntity)
Player.static.width = 10
Player.static.height = 10
Player.static.coinParticle = getRectImage(1, 1)

Player.static.smgUpgrades = {
  { "Purchase Weapon", 0 },
  { "Dual Wield", 10 },
  { "Penetrative Bullets", 20 },
  { "More Damage", 30 }
}

Player.static.mgUpgrades = {
  { "Purchase Weapon", 10 },
  { "Dual Wield", 25 },
  { "Heavy Duty Bullets", 30 }
}

Player.static.sgUpgrades = {
  { "Purchase Weapon", 10 },
  { "Dual Wield", 25 },
  { "More Pellets", 25 },
  { "Heat-Seeking Pellets", 40 }
}

Player.static.laserUpgrades = {
  { "Purchase Weapon", 30 },
  { "Penetrative Beam", 30 },
  { "Dual Wield", 60 },
  { "Overheats Less", 80 }
}

Player.static.rpgUpgrades = {
  { "Purchase Weapon", 30 },
  { "Heat-Seeking Splitter Rocket", 40 },
  { "Dual Wield", 60 }
}

function Player:initialize(x, y)
  PhysicalEntity.initialize(self, x, y, "dynamic")
  self.respawnX = x
  self.respawnY = y
  self.layer = 4
  self.width = Player.width
  self.height = Player.height
  self.mgImg = assets.images.demonMg
  self.mg2Img = assets.images.demonMgDual
  self.speed = 1800 * 60 -- 1800 per frame at 60 fps
  self.maxHealth = 50
  self.health = self.maxHealth
  self.dead = true
  self.respawnTime = 3
  self.respawnTimer = self.respawnTime
  self.scale = 1

  self.weaponIndex = 1
  self.weapon = "smg"
  self.attackTimer = 0
  self.mgAttackTime = 0.2
  self.smgAttackTime = 0.04
  self.smgVariance = math.tau / 18
  self.sgAttackTime = 0.5
  self.sgVariance = math.tau / 10
  self.laser = Laser:new()
  self.laser2 = Laser:new()
  self.laserHeat = 0
  self.laserOverheatTime = 1
  self.laserOverheatTimer = 0
  self.rpgAttackTime = 0.8
  self:applySettings(1, 0, 0, 0, 0)

  self.muzzleFlashTime = 0.03
  self.muzzleFlashTimer = 0

  local ps = love.graphics.newParticleSystem(Player.coinParticle, 100)
  ps:setPosition(x, y)
  ps:setAreaSpread("normal", 1, 1)
  ps:setColors(255, 198, 0, 255, 255, 198, 0, 0)
  ps:setParticleLifetime(2.5, 3)
  ps:setLinearDamping(0.8, 1)
  ps:setSpeed(25, 40)
  ps:setSpread(math.tau / 3)
  self.coinPS = ps

  ps = love.graphics.newParticleSystem(Player.coinParticle, 200)
  ps:setPosition(x, y)
  ps:setSpread(math.tau)
  ps:setAreaSpread("normal", 1.5, 1.5)
  ps:setTangentialAcceleration(30, 50)
  ps:setSizes(2, 1.5)
  ps:setSpeed(1, 2)
  ps:setColors(41, 0, 80, 255, 126, 10, 128, 0)
  ps:setParticleLifetime(1.5, 2)
  ps:setEmitterLifetime(-1)
  ps:setEmissionRate(100)
  ps:start()
  self.spawnPS = ps
  playSound("spawn")
end

function Player:added()
  self:setupBody()
  self.fixture = self:addShape(love.physics.newRectangleShape(self.width, self.height))
  self.fixture:setCategory(2)
  self:setMass(1)
  self:setLinearDamping(20)

  self.light = self.world.lighting:add(self.x, self.y, 70)
  self.light.alpha = 125
  self.muzzleLight = self.world.lighting:add(self.x, self.y, 130, 10)
  self.muzzleLight.alpha = 0
  self.world:add(self.laser, self.laser2)

  self.laserSound = assets.sfx.laser:loop()
  self.laserSound:pause()
end

function Player:update(dt)
  self.coinPS:update(dt)
  self.spawnPS:update(dt)
  self.laserSound:pause()

  if self.respawnTimer > 0 then
    self.respawnTimer = self.respawnTimer - dt

    if self.respawnTimer <= 0 then
      self:spawn()
      self.scale = 1
    elseif self.respawnTimer <= 0.5 then
      self.scale = 1 - self.respawnTimer * 2
    end
  end

  self.light.x = self.x
  self.light.y = self.y
  self.muzzleLight.x = self.x
  self.muzzleLight.y = self.y

  if self.dead then return end
  PhysicalEntity.update(self, dt)
  self:setAngularVelocity(0)

  self.angle = math.angle(self.x, self.y, mouseCoords())
  local dir = self:getDirection()
  if dir then self:applyForce(self.speed * math.cos(dir) * dt, self.speed * math.sin(dir) * dt) end

  self.laser:reset()
  self.laser2:reset()

  if self.muzzleFlashTimer > 0 then
    self.muzzleFlashTimer = self.muzzleFlashTimer - dt

    if self.muzzleFlashTimer <= 0 then
      self.muzzleLight.alpha = 0
    end
  end

  if self.attackTimer > 0 then
    self.attackTimer = self.attackTimer - dt
  else
    if input.down("attack") then
      self:attack(dt)

      if self.weapon ~= "laser" then
        self.attackTimer = self[self.weapon .. "AttackTime"]
      end
    elseif self.laserHeat > 0 then
      self.laserHeat = self.laserHeat - dt
    end
  end

  if self.laserOverheatTimer > 0 then
    self.laserOverheatTimer = self.laserOverheatTimer - dt
    if self.laserOverheatTimer <= 0 then self.laserHeat = 0 end
  end

  for i = 1, 5 do
    if input.pressed("wep" .. tostring(i)) then
      self:switchWeapon(i)
    end
  end

  if input.pressed("prevweapon") then
    self:switchWeapon("down")
  end

  if input.pressed("nextweapon") then
    self:switchWeapon("up")
  end
end

function Player:attack(dt)
  local sx, sy = self.x + 5 * math.cos(self.angle), self.y + 5 * math.sin(self.angle)
  local dx1, dy1 = sx + math.cos(self.angle + math.tau / 4) * 3, sy + math.sin(self.angle + math.tau / 4) * 3
  local dx2, dy2 = sx - math.cos(self.angle + math.tau / 4) * 3, sy - math.sin(self.angle + math.tau / 4) * 3
  self.muzzleLight.alpha = 255
  self.muzzleFlashTimer = self.muzzleFlashTime
  self.muzzleLight.color[2] = 255
  self.muzzleLight.color[3] = 255

  if self.weapon == "mg" then
    if self.mgDual then
      self.world:add(Bullet:new(dx1, dy1, self.angle))
      self.world:add(Bullet:new(dx2, dy2, self.angle))
    else
      self.world:add(Bullet:new(sx, sy, self.angle, self.mgCaliber))
    end

    playRandom{"mg", "mg2", "mg3"}
    self.world:shake(0.1, 0.5)
  elseif self.weapon == "smg" then
    if self.smgDual then
      local angle1 = self.angle - self.smgVariance / 2 + self.smgVariance * math.random()
      local angle2 = self.angle - self.smgVariance / 2 + self.smgVariance * math.random()
      self.world:add(Bullet:new(dx1, dy1, angle1, self.smgCaliber, self.smgPenetration and 3 or 0))
      self.world:add(Bullet:new(dx2, dy2, angle2, self.smgCaliber, self.smgPenetration and 3 or 0))
    else
      local angle = self.angle - self.smgVariance / 2 + self.smgVariance * math.random()
      self.world:add(Bullet:new(sx, sy, angle, self.smgCaliber, self.smgPenetration and 3 or 0))
    end

    playRandom{"smg", "smg2", "smg3"}
  elseif self.weapon == "sg" then
    if self.sgDual then
      for i = 1, self.sgPellets do
        local angle1 = self.angle - self.sgVariance / 2 + self.sgVariance * math.random()
        local angle2 = self.angle - self.sgVariance / 2 + self.sgVariance * math.random()
        self.world:add(Bullet:new(dx1, dy1, angle1, "pellet", nil, self.sgSeeking))
        self.world:add(Bullet:new(dx2, dy2, angle2, "pellet", nil, self.sgSeeking))
      end
    else
      for i = 1, self.sgPellets do
        local angle = self.angle - self.sgVariance / 2 + self.sgVariance * math.random()
        self.world:add(Bullet:new(sx, sy, angle, "pellet", nil, self.sgSeeking))
      end
    end

    playRandom{"sg", "sg2", "sg3"}
    self.world:shake(0.2, 1)
  elseif self.weapon == "laser" then
    if self.laserOverheatTimer <= 0 then
      self.laserHeat = self.laserHeat + dt

      if self.laserHeat >= self.laserHeatLimit then
        playSound("laser-overheat")
        self.laserOverheatTimer = self.laserOverheatTime
      end

      if self.laserDual then
        self.laser:fire(dt, dx1, dy1, self.angle)
        self.laser2:fire(dt, dx2, dy2, self.angle)
      else
        self.laser:fire(dt, sx, sy, self.angle)
      end

      self.muzzleLight.alpha = math.random(170, 255)
      self.muzzleLight.color[2] = 120
      self.muzzleLight.color[3] = 120
      self.world:shake(0.1, 0.5)
      self.laserSound:play()
    else
      self.muzzleLight.alpha = 0
      self.muzzleFlashTimer = 0
    end
  elseif self.weapon == "rpg" then
    if self.rpgDual then
      self.world:add(Rocket:new(dx1, dy1, self.angle, self.rpgSeeking))
      self.world:add(Rocket:new(dx2, dy2, self.angle, self.rpgSeeking))
    else
      self.world:add(Rocket:new(sx, sy, self.angle, self.rpgSeeking))
    end

    self.world:shake(0.15, 1)
  end
end

function Player:draw()
  love.graphics.draw(self.spawnPS)
  love.graphics.draw(self.coinPS)

  if not self.dead or self.respawnTimer <= 0.5 or self.fallen then
    local img
    if self[self.weapon .. "Dual"] then
      img = self.mg2Img
    else
      img = self.mgImg
    end

    self:drawImage(img)
  end
end

function Player:die(noBlood)
  if self.dead then return end
  self.dead = true
  self.respawnTimer = self.respawnTime
  self.spawnPS:setPosition(self.respawnX, self.respawnY)
  self.spawnPS:start()
  self.light.alpha = 0
  tween(self.light, self.respawnTime * (2/3), { alpha = 125 })

  if not noBlood then
    self.world:add(BloodSpurt:new(self.x, self.y, math.tau * math.random(), 6, 6, 1))
  end

  self.x = self.respawnX
  self.y = self.respawnY
  playSound("spawn")
end

function Player:fall()
  self.dead = true
  self.fallen = true
  self.laser:reset()
  self.laser2:reset()

  self:animate(1, { scale = 0 }, ease.cubeOut, function()
    self.dead = false
    self.fallen = false
    self:die(true)
  end)
end

function Player:spawn()
  self.health = self.maxHealth
  self.x = self.respawnX
  self.y = self.respawnY
  self.dead = false
  self.spawnPS:stop()
end

function Player:damage(amount, enemy)
  if self.dead then return end
  self.health = self.health - amount

  if self.health <= 0 then
    self:die()
  end

  local angle = math.angle(self.x, self.y, enemy.x, enemy.y)
  self.world:add(BloodSpurt:new(self.x, self.y, -angle))
end

function Player:applySettings(smg, mg, sg, laser, rpg)
  smg = smg or self.smgLevel
  self.smgLevel = smg
  self.smgCaliber = "low"
  if smg >= 1 then self.smgUnlocked = true end
  if smg >= 2 then self.smgDual = true end
  if smg >= 3 then self.smgPenetration = true end
  if smg >= 4 then self.smgCaliber = "med" end

  mg = mg or self.mgLevel
  self.mgLevel = mg
  self.mgCaliber = "med"
  if mg >= 1 then self.mgUnlocked = true end
  if mg >= 2 then self.mgDual = true end
  if mg >= 3 then self.mgCaliber = "high" end

  sg = sg or self.sgLevel
  self.sgLevel = sg
  self.sgPellets = 15
  if sg >= 1 then self.sgUnlocked = true end
  if sg >= 2 then self.sgDual = true end
  if sg >= 3 then self.sgPellets = 25 end
  if sg >= 4 then self.sgSeeking = true end

  laser = laser or self.laserLevel
  self.laserLevel = laser
  self.laserHeatLimit = 3
  self.laser.maxPenetrations = 0
  if laser >= 1 then self.laserUnlocked = true end
  if laser >= 2 then
    self.laser.maxPenetrations = 5
    self.laser2.maxPenetrations = 5
  end
  if laser >= 3 then self.laserDual = true end
  if laser >= 4 then self.laserHeatLimit = 6 end

  rpg = rpg or self.rpgLevel
  self.rpgLevel = rpg
  if rpg >= 1 then self.rpgUnlocked = true end
  if rpg >= 2 then self.rpgSeeking = true end
  if rpg >= 3 then self.rpgDual = true end
end

function Player:upgradeTo(id, level)
  self[id .. "Level"] = level
  self:applySettings()
end

function Player:switchWeapon(index)
  local curwep = self.weapon

  if index == "up" then
    local st = math.min(self.weaponIndex + 1, 5)

    for i = st, 5 do
      self:switchWeapon(i)
      if curwep ~= self.weapon then break end
    end
  elseif index == "down" then
    local st = math.max(self.weaponIndex - 1, 1)

    for i = st, 1, -1 do
      self:switchWeapon(i)
      if curwep ~= self.weapon then break end
    end
  else
    if index == 1 then
      if self.smgUnlocked then self.weapon = "smg" end
    elseif index == 2 then
      if self.mgUnlocked then self.weapon = "mg" end
    elseif index == 3 then
      if self.sgUnlocked then self.weapon = "sg" end
    elseif index == 4 then
      if self.laserUnlocked then self.weapon = "laser" end
    elseif index == 5 then
      if self.rpgUnlocked then self.weapon = "rpg" end
    end

    if self.weapon ~= curwep then
      self.weaponIndex = index
    end
  end
end

function Player:getDirection()
  local xAxis = input.axisDown("left", "right")
  local yAxis = input.axisDown("up", "down")
  
  local xAngle = xAxis == 1 and 0 or (xAxis == -1 and math.tau / 2 or nil)
  local yAngle = yAxis == 1 and math.tau / 4 or (yAxis == -1 and math.tau * 0.75 or nil)
  
  if xAngle and yAngle then
    -- x = 1, y = -1 is a special case the doesn't fit
    if xAxis == 1 and yAxis == -1 then xAngle = math.tau end
    return (xAngle + yAngle) / 2
  else
    return xAngle or yAngle
  end
end

function Player:coinCollected(x, y)
  self.coinPS:setDirection(math.angle(0, 0, self.velx, self.vely))
  self.coinPS:moveTo(x, y)
  self.coinPS:emit(10)
  playRandom{"coin", "coin2", "coin3"}
end