SeekerRocket = class("SeekerRocket", PhysicalEntity)
SeekerRocket.static.lightImg = makeLightImage(100, 10)

function SeekerRocket:initialize(x, y, angle)
  PhysicalEntity.initialize(self, x, y, "dynamic")
  self.layer = 7
  self.normalSpeed = 300
  self.speed = 70
  self.image = assets.images.rocket
  self.scale = 0.5
  self.width = self.image:getWidth() * 0.5
  self.height = self.image:getHeight() * 0.5
  self.angle = angle
  self.damage = 200
  self.radius = 30
  self.seekDist = 40
  self.lightTime = 0.05
  self.lightTimer = 0

  local ps = love.graphics.newParticleSystem(assets.images.smoke, 150)
  ps:setPosition(x, y)
  ps:setSpread(math.tau / 20)
  ps:setDirection(-angle)
  ps:setLinearDamping(8, 16)
  ps:setColors(255, 255, 255, 150, 255, 255, 255, 50, 255, 255, 255, 0)
  ps:setParticleLifetime(0.8, 1.2)
  ps:setSizes(0.5, 0.4)
  ps:setSizeVariation(0.5)
  ps:setEmitterLifetime(-1)
  ps:setEmissionRate(70)
  ps:start()
  self.smokePS = ps
end

function SeekerRocket:added()
  self:setupBody()
  self:setBullet(true)
  self.fixture = self:addShape(love.physics.newRectangleShape(self.width, self.height))
  self.fixture:setSensor(true)
  self.fixture:setCategory(5)
  self.fixture:setMask(2, 5)
  self:animate(0.5, { speed = self.normalSpeed })
  self.light = self.world.lighting:addImage(SeekerRocket.lightImg, self.x, self.y, 100)
  self.light.alpha = 0
  self.sound = playRandom({"seekrpg", "seekrpg2"}, 0.3)
end

function SeekerRocket:update(dt)
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

  if not self.target then
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

    if enemy then self.target = enemy end
  end

  if self.target then
    if self.target.dead then
      self.target = nil
    else
      local tangle = math.angle(self.x, self.y, self.target.x, self.target.y)
      self.angle = math.lerp(self.angle, tangle, math.min(4 * dt, 1))
    end
  end

  self.smokePS:moveTo(self.x, self.y)
  self.smokePS:setSpeed(60 * (self.speed / self.normalSpeed))
  self.velx = self.speed * math.cos(self.angle)
  self.vely = self.speed * math.sin(self.angle)
end

function SeekerRocket:draw()
  love.graphics.draw(self.smokePS)
  if not self.dead then self:drawImage() end
end

function SeekerRocket:die()
  self.dead = true
  self:destroy()
  self.smokePS:stop()
  self.sound:stop()
end

function SeekerRocket:explode()
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
  self.smokePS:emit(80)
  self.smokePS:setParticleLifetime(2, 3)
  self.world:shake(0.2, 2)
  playRandom({"explosion", "explosion2", "explosion3", "explosion4"}, 0.5)
  self:die()
end

function SeekerRocket:collided(other, fixt, otherFixt, contact)
  if other:isInstanceOf(Enemy) or other:isInstanceOf(Walls) or other:isInstanceOf(Altar) or other:isInstanceOf(Brazier) then
    self:explode()
  end
end
