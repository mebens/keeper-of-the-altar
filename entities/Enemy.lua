Enemy = class("Enemy", PhysicalEntity)
Enemy.static.all = LinkedList:new("_nextEnemy", "_prevEnemy")

function Enemy:initialize(x, y)
  PhysicalEntity.initialize(self, x, y, "dynamic")
  self.layer = 5
  self.speed = 600 * 60
  self.health = 100
  self.slowdownSpeed = 400 * 60
  self.slowdownTimer = 0
  self.slowdownTime = 0.6
  self.attackTimer = 0
end

function Enemy:added()
  self:setupBody()
  self.fixture = self:addShape(love.physics.newRectangleShape(self.width, self.height))
  self:setMass(1)
  self:setLinearDamping(10)
  self.destX = self.world.width / 2
  self.destY = self.world.height / 2
  Enemy.all:push(self)
  if self.map then self.map:play("move") end
end

function Enemy:removed()
  self:destroy()
  Enemy.all:remove(self)
end

function Enemy:update(dt)
  if self.dead then
    self:destroy()
    self.world = nil
    return
  end

  PhysicalEntity.update(self, dt)
  self:setAngularVelocity(0)

  local speed = self.speed

  if self.slowdownTimer > 0 then
    speed = speed - self.slowdownSpeed * (self.slowdownTimer / self.slowdownTime)
    self.slowdownTimer = self.slowdownTimer - dt
  end

  if self.attackTimer > 0 then
    self.attackTimer = self.attackTimer - dt
  end

  local angle = nil

  if self.attack == "altar" then
    local dist = math.distance(self.x, self.y, self.destX, self.destY)

    if dist > self.attackRange + 15 then
      angle = math.angle(self.x, self.y, self.destX, self.destY)
    elseif self.attackTimer <= 0 then
      self.world.altar:damage(self.damage, self)
      self.attackTimer = self.attackTime
      if self.map then self.map:play("attack") end
    end
  elseif self.attack == "player" then
    local dist = math.distance(self.x, self.y, self.world.player.x, self.world.player.y)

    if dist > 60 then
      self.attack = nil
    elseif dist > self.attackRange then
      angle = math.angle(self.x, self.y, self.world.player.x, self.world.player.y)
    elseif self.attackTimer <= 0 then
      self.world.player:damage(self.damage, self)
      self.attackTimer = self.attackTime
      if self.map then self.map:play("attack") end
    end
  else
    angle = math.angle(self.x, self.y, self.destX, self.destY)   
  end

  if angle then
    self.angle = angle
    self:applyForce(speed * math.cos(angle) * dt, speed * math.sin(angle) * dt)

    if self.map and self.map.current ~= "move" then
      self.map:play("move")
    end
  end

  if self.map then self.map:update(dt) end
end

function Enemy:draw()
  if self.map then self:drawMap() end
  if self.image then self:drawImage() end
end

function Enemy:bulletHit(bullet, contact)
  self.health = self.health - bullet.damage
  self.world:add(BloodSpurt:new(self.x, self.y, bullet.angle, 2))

  if self.health <= 0 then
    self:die()
    return
  end

  self.slowdownTimer = self.slowdownTime
end

function Enemy:laserDamage(damage)
  self.health = self.health - damage

  if self.health <= 0 then
    self.world:add(BloodSpurt(self.x, self.y, math.tau * math.random(), 6, 6, 1))
    self:die() -- will need to gib
    return
  end

  self.slowdownTimer = 0.1
end

function Enemy:rocketDamage(damage)
  self.health = self.health - damage

  if self.health <= 0 then
    self.world:add(BloodSpurt(self.x, self.y, math.tau * math.random(), 6, 6, 1))
    self:die()
    return
  end

  self.slowdownTimer = self.slowdownTime
end

function Enemy:die()
  if self.dead then return end
  self.world:add(Coin:new(self.x, self.y))
  self.dead = true
  self.world = nil
end

function Enemy:collided(other)
  if other:isInstanceOf(Altar) then
    self.attack = "altar"
  elseif other:isInstanceOf(Player) then
    self.attack = "player"
  end
end
