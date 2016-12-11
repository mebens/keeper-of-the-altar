Bullet = class("Bullet", PhysicalEntity)
Bullet.static.image = getRectImage(11, 1, 255, 240, 0)

function Bullet:initialize(x, y, angle, caliber, penetration, seeking)
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
  self.seeking = seeking
  self.seekDist = 30

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

  if penetration then self.maxPenetrations = penetration end
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
  if self.dead then return end
  PhysicalEntity.update(self, dt)

  if self.seekTarget then
    if self.seekTarget.dead then
      self.seekTarget = nil
    else
      local tangle = math.angle(self.x, self.y, self.seekTarget.x, self.seekTarget.y)
      self.angle = math.lerp(self.angle, tangle, math.min(4 * dt, 1))
    end
  elseif self.seeking then
    local dist = math.huge
    local enemy

    for e in Enemy.all:iterate() do
      if not e:isInstanceOf(Spawner) then
        local d = math.distance(self.x, self.y, e.x, e.y)

        if d < self.seekDist and d < dist then
          enemy = e
          dist = d
        end
      end
    end

    if enemy then self.seekTarget = enemy end
  end

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

    playRandom{"hit", "hit2", "hit3", "hit4"}
  elseif other:isInstanceOf(Walls) or other:isInstanceOf(Altar) or other:isInstanceOf(Brazier) then
    self:die()
  end
end

function Bullet:createSeekFixture()
  self.seekFixture = self:addShape(love.physics.newRectangleShape(60, 60))
  self.seekFixture:setSensor(true)
  self.seekFixture:setCategory(5)
  self.seekFixture:setMask(2, 5)
end
