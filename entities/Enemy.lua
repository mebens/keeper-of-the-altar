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
end

function Enemy:added()
  self:setupBody()
  self.fixture = self:addShape(love.physics.newRectangleShape(self.width, self.height))
  self:setMass(1)
  self:setLinearDamping(10)
  self.destX = self.world.width / 2
  self.destY = self.world.height / 2
  Enemy.all:push(self)
end

function Enemy:removed()
  self:destroy()
  Enemy.all:remove(self)
end

function Enemy:update(dt)
  if self.dead then
    self:destroy()
    self.world = nil
    DEBUG = os.time()
    return
  end

  PhysicalEntity.update(self, dt)
  self:setAngularVelocity(0)

  local speed = self.speed

  if self.slowdownTimer > 0 then
    speed = speed - self.slowdownSpeed * (self.slowdownTimer / self.slowdownTime)
    self.slowdownTimer = self.slowdownTimer - dt
  end

  self.angle = math.angle(self.x, self.y, self.destX, self.destY)
  self:applyForce(speed * math.cos(self.angle) * dt, speed * math.sin(self.angle) * dt)
end

function Enemy:draw()
  if self.map then self:drawMap() end
  if self.image then self:drawImage() end
end

function Enemy:bulletHit(bullet, contact)
  self.health = self.health - bullet.damage

  if self.health <= 0 then
    self:die()
    return
  end

  self.slowdownTimer = self.slowdownTime
end

function Enemy:laserDamage(damage)
  self.health = self.health - damage

  if self.health <= 0 then
    self:die() -- will need to gib
    return
  end

  self.slowdownTimer = 0.1
end

function Enemy:rocketDamage(damage)
  self.health = self.health - damage

  if self.health <= 0 then
    self:die() -- gib
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
