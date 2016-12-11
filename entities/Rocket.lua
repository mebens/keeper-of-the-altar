Rocket = class("Rocket", PhysicalEntity)
Rocket.static.lightImg = makeLightImage(150, 20)


function Rocket:initialize(x, y, angle, splitter)
  PhysicalEntity.initialize(self, x, y, "dynamic")
  self.layer = 7
  self.normalSpeed = 300
  self.speed = 100
  self.image = assets.images.rocket
  self.width = self.image:getWidth()
  self.height = self.image:getHeight()
  self.angle = angle
  self.damage = 500
  self.radius = 60
  self.lightTime = 0.05
  self.lightTimer = 0

  self.splitter = splitter
  self.splitTimer = 0.4
  self.splitRange = math.tau / 6

  local ps = love.graphics.newParticleSystem(assets.images.smoke, 500)
  ps:setPosition(x, y)
  ps:setSpread(math.tau / 16)
  ps:setDirection(-angle)
  ps:setLinearDamping(10, 20)
  ps:setColors(255, 255, 255, 150, 255, 255, 255, 50, 255, 255, 255, 0)
  ps:setParticleLifetime(0.8, 1.2)
  ps:setSizes(1, 0.8)
  ps:setSizeVariation(0.5)
  ps:setEmitterLifetime(-1)
  ps:setEmissionRate(100)
  ps:start()
  self.smokePS = ps
end

function Rocket:added()
  self:setupBody()
  self:setBullet(true)
  self.fixture = self:addShape(love.physics.newRectangleShape(self.width, self.height))
  self.fixture:setSensor(true)
  self.fixture:setCategory(5)
  self.fixture:setMask(2, 5)
  self:animate(0.5, { speed = self.normalSpeed })
  self.light = self.world.lighting:addImage(Rocket.lightImg, self.x, self.y, 120)
  self.light.alpha = 0
  self.sound = playRandom{"rpg", "rpg2"}
end

function Rocket:update(dt)
  self.smokePS:update(dt)
  self.light.x = self.x
  self.light.y = self.y

  if self.lightTimer > 0 then
    self.lightTimer = self.lightTimer - dt

    if self.lightTimer <= 0 then
      self.light.alpha = 0
    end
  end

  if self.dead then
    if self.smokePS:getCount() == 0 then
      self.world = nil
      self.world.lighting:remove(self.light)
    end

    return
  end

  PhysicalEntity.update(self, dt)

  if self.splitter then
    if self.splitTimer > 0 then
      self.splitTimer = self.splitTimer - dt
    else
      self:split()
    end
  end

  self.smokePS:moveTo(self.x, self.y)
  self.smokePS:setSpeed(100 * (self.speed / self.normalSpeed))
  self.velx = self.speed * math.cos(self.angle)
  self.vely = self.speed * math.sin(self.angle)
end

function Rocket:draw()
  love.graphics.draw(self.smokePS)
  if not self.dead then self:drawImage() end
end

function Rocket:die()
  self.dead = true
  self:destroy()
  self.smokePS:stop()
  self.sound:stop()
end

function Rocket:explode()
  local dist

  for e in Enemy.all:iterate() do
    if not e:isInstanceOf(Spawner) then
      dist = math.distance(self.x, self.y, e.x, e.y) 
      if dist <= self.radius then e:rocketDamage((1 - dist / self.radius) * self.damage) end
    end
  end

  self.lightTimer = self.lightTime
  self.light.alpha = 255
  self.smokePS:setSpeed(300)
  self.smokePS:setLinearDamping(5, 10)
  self.smokePS:setSpread(math.tau)
  self.smokePS:emit(300)
  self.smokePS:setParticleLifetime(2, 3)
  self.world:shake(0.3, 2)
  playRandom{"explosion", "explosion2", "explosion3", "explosion4"}
  self:die()
end

function Rocket:split()
  for i = 1, 10 do
    self.world:add(SeekerRocket:new(self.x, self.y, self.angle - self.splitRange / 2 + self.splitRange * math.random()))
  end

  self:die()
end

function Rocket:collided(other, fixt, otherFixt, contact)
  if other:isInstanceOf(Enemy) or other:isInstanceOf(Walls) or other:isInstanceOf(Altar) or other:isInstanceOf(Brazier) then
    self:explode()
  end
end
