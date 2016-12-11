Player = class("Player", PhysicalEntity)
Player.static.width = 10
Player.static.height = 10
Player.static.coinParticle = getRectImage(1, 1)

Player.static.smgUpgrades = {
  { "Purchase Weapon", 10 },
  { "Dual Wield", 50 },
  { "Penetrative Bullets", 200 },
  { "More Damage", 400 }
}

Player.static.mgUpgrades = {
  { "Purchase Weapon", 50 },
  { "Dual Wield", 200 },
  { "Heavy Duty Bullets", 400 }
}

Player.static.sgUpgrades = {
  { "Purchase Weapon", 50 },
  { "Dual Wield", 200 },
  { "More Pellets", 400 },
  { "Heat-Seeking Pellets", 800 }
}

Player.static.laserUpgrades = {
  { "Purchase Weapon", 200 },
  { "Penetrative Beam", 400 },
  { "Dual Wield", 600 },
  { "Overheats Less", 600 }
}

Player.static.rpgUpgrades = {
  { "Purchase Weapon", 300 },
  { "Heat-Seeking Splitter Rocket", 600 },
  { "Dual Wield", 800 }
}

function Player:initialize(x, y)
  PhysicalEntity.initialize(self, x, y, "dynamic")
  self.layer = 4
  self.width = Player.width
  self.height = Player.height
  self.image = assets.images.demonMg
  self.speed = 1800 * 60 -- 1800 per frame at 60 fps
  self.health = 100
  self.lives = 2

  self.weaponIndex = 1
  self.weapon = "smg"
  self.attackTimer = 0
  self.mgAttackTime = 0.2
  self.smgAttackTime = 0.04
  self.smgVariance = math.tau / 18
  self.sgAttackTime = 0.5
  self.sgVariance = math.tau / 10
  self.laser = Laser:new()
  self.laserHeat = 0
  self.laserOverheatTime = 1
  self.laserOverheatTimer = 0
  self.rpgAttackTime = 0.8
  self:applySettings(1, 0, 0, 0, 0)

  local ps = love.graphics.newParticleSystem(Player.coinParticle, 100)
  ps:setPosition(x, y)
  ps:setAreaSpread("normal", 1, 1)
  ps:setColors(255, 198, 0, 255, 255, 198, 0, 0)
  ps:setParticleLifetime(2.5, 3)
  ps:setLinearDamping(0.8, 1)
  ps:setSpeed(25, 40)
  ps:setSpread(math.tau / 3)
  self.coinPS = ps
end

function Player:added()
  self:setupBody()
  self.fixture = self:addShape(love.physics.newRectangleShape(self.width, self.height))
  self.fixture:setCategory(2)
  self:setMass(1)
  self:setLinearDamping(20)

  self.light = self.world.lighting:add(self.x, self.y, 70)
  self.light.alpha = 125
  self.world:add(self.laser)
end

function Player:update(dt)
  PhysicalEntity.update(self, dt)
  self:setAngularVelocity(0)

  self.angle = math.angle(self.x, self.y, mouseCoords())
  local dir = self:getDirection()
  if dir then self:applyForce(self.speed * math.cos(dir) * dt, self.speed * math.sin(dir) * dt) end

  self.laser:reset()

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

  if input.pressed("prevweapon") and self.weaponIndex > 1 then
    self:switchWeapon(self.weaponIndex - 1)
  end

  if input.pressed("nextweapon") and self.weaponIndex < 5 then
    self:switchWeapon(self.weaponIndex + 1)
  end

  self.light.x = self.x
  self.light.y = self.y
  self.coinPS:update(dt)
end

function Player:attack(dt)
  if self.weapon == "mg" then
    self.world:add(Bullet:new(self.x + 5 * math.cos(self.angle), self.y + 5 * math.sin(self.angle), self.angle, self.mgCaliber))
  elseif self.weapon == "smg" then
    local angle = self.angle - self.smgVariance / 2 + self.smgVariance * math.random()
    self.world:add(Bullet:new(
      self.x + 5 * math.cos(self.angle),
      self.y + 5 * math.sin(self.angle),
      angle,
      self.smgCaliber,
      self.smgPenetration and 3 or 0
    ))
  elseif self.weapon == "sg" then
    for i = 1, self.sgPellets do
      local angle = self.angle - self.sgVariance / 2 + self.sgVariance * math.random()
      self.world:add(Bullet:new(self.x + 5 * math.cos(self.angle), self.y + 5 * math.sin(self.angle), angle, "pellet", nil, self.sgSeeking))
    end
  elseif self.weapon == "laser" then
    if self.laserOverheatTimer <= 0 then
      self.laserHeat = self.laserHeat + dt

      if self.laserHeat >= self.laserHeatLimit then
        self.laserOverheatTimer = self.laserOverheatTime
      end

      self.laser:fire(dt, self.x, self.y, self.angle)
    end
  elseif self.weapon == "rpg" then
    self.world:add(Rocket:new(self.x + 5 * math.cos(self.angle), self.y + 5 * math.sin(self.angle), self.angle, self.rpgSeeking))
  end
end

function Player:draw()
  love.graphics.draw(self.coinPS)
  self:drawImage()
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
  self.laserHeatLimit = 2
  self.laser.maxPenetrations = 0
  if laser >= 1 then self.laserUnlocked = true end
  if laser >= 2 then self.laser.maxPenetrations = 5 end
  if laser >= 3 then self.laserDual = true end
  if laser >= 4 then self.laserHeatLimit = 5 end

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
  self.weaponIndex = index

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
end