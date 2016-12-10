Bullet = class("Bullet", PhysicalEntity)
Bullet.static.image = getRectImage(11, 1, 255, 240, 0)

function Bullet:initialize(x, y, angle, caliber)
  PhysicalEntity.initialize(self, x, y, "dynamic")
  self.layer = 7
  self.speed = 800
  self.velx = self.speed * math.cos(angle)
  self.vely = self.speed * math.sin(angle)
  self.image = Bullet.image
  self.width = self.image:getWidth()
  self.height = self.image:getHeight()
  self.angle = angle
  self.penetrations = 0
  self.caliber = caliber or "med"

  if self.caliber == "low" then
    self.baseDamage = 30
    self.maxPenetrations = 0
    self.scaleX = 0.7
  elseif self.caliber == "med" then
    self.baseDamage = 50
    self.maxPenetrations = 3
  elseif self.caliber == "high" then
    self.baseDamage = 100
    self.maxPenetrations = 7
  elseif self.caliber == "pellet" then
    self.baseDamage = 30
    self.maxPenetrations = 1
    self.scaleX = 0.4
    self.baseSpeed = math.random(400, 800)
    self.speed = self.baseSpeed
    self.slowdown = 300
    self.slowdownAccel = 2400
  end

  self.damage = self.baseDamage
end

function Bullet:added()
  self:setupBody()
  self:setBullet(true)
  self.fixture = self:addShape(love.physics.newRectangleShape(self.width, self.height))
  self.fixture:setSensor(true)
  self.fixture:setCategory(5)
  self.fixture:setMask(2, 5)
end

function Bullet:update(dt)
  PhysicalEntity.update(self, dt)

  if self.caliber == "pellet" then
    self.speed = self.speed - self.slowdown * dt
    self.damage = self.baseDamage * (self.speed / self.baseSpeed)
    self.velx = self.speed * math.cos(self.angle)
    self.vely = self.speed * math.sin(self.angle)
    self.slowdown = self.slowdown + self.slowdownAccel * dt

    if self.speed < 30 then
      self:die()
    end
  end
end

function Bullet:draw()
  if not self.dead then self:drawImage() end
end

function Bullet:die()
  if self.dead then return end
  self.dead = true
  self:destroy()
  self.world = nil
end

function Bullet:collided(other, fixt, otherFixt, contact)
  if other:isInstanceOf(Enemy) then
    other:bulletHit(self, contact)
    self.penetrations = self.penetrations + 1

    if self.penetrations >= self.maxPenetrations then
      self:die()
    else
      self.damage = self.damage - self.baseDamage * 0.7 / self.maxPenetrations
    end
  else
    self:die()
  end
end
