Fireball = class("Fireball", PhysicalEntity)

function Fireball:initialize(x, y, enemy)
  PhysicalEntity.initialize(self, x, y, "dynamic")
  self.target = enemy
  self.speed = 300
  self.radius = 4
  self.damageRadius = 25
  self.damage = 200

  self.lightTime = 0.05
  self.lightTimer = 0

  local ps = love.graphics.newParticleSystem(assets.images.smoke, 300)
  ps:setPosition(x, y)
  ps:setAreaSpread("normal", 0.5, 0.5)
  ps:setColors(175, 25, 0, 60, 180, 25, 30, 10)
  ps:setSizes(0.6, 0.2)
  ps:setSpread(math.tau / 16)
  ps:setEmitterLifetime(-1)
  ps:setParticleLifetime(0.5, 0.8)
  ps:setSpeed(10, 20)
  ps:setLinearDamping(10, 15)
  ps:setEmissionRate(80)
  ps:start()
  self.ps = ps
end

function Fireball:added()
  self:setupBody()
  self:setBullet(true)
  self.fixture = self:addShape(love.physics.newCircleShape(self.radius))
  self.fixture:setSensor(true)
  self.fixture:setCategory(5)
  self.fixture:setMask(2, 5)
  self.sound = playRandom({"seekrpg", "seekrpg2"}, 0.5)
  self.explodeLight = self.world.lighting:addImage(SeekerRocket.lightImg, self.x, self.y, 100)
  self.explodeLight.alpha = 0
end

function Fireball:update(dt)
  self.ps:moveTo(self.x, self.y)
  self.ps:update(dt)

  if self.lightTimer > 0 then
    self.lightTimer = self.lightTimer - dt

    if self.lightTimer <= 0 then
      self.explodeLight.alpha = 0
      --self.world.lighting:remove(self.explodeLight)
    end
  end

  if self.dead then
    if self.ps:getCount() == 0 then
      self.world = nil
      self:destroy()
    end

    return
  end

  PhysicalEntity.update(self, dt)
  
  if self.target then
    if self.target.dead then
      self.target = nil
    else
      local tangle = math.angle(self.x, self.y, self.target.x, self.target.y)
      self.angle = math.lerp(self.angle, tangle, math.min(6 * dt, 1))
      self.velx = self.speed * math.cos(self.angle)
      self.vely = self.speed * math.sin(self.angle)
    end
  end
end

function Fireball:draw()
  -- love.graphics.setBlendMode("multiply")
  love.graphics.draw(self.ps)
end

function Fireball:die()
  self.dead = true
  self.ps:setSpread(math.tau)
  self.ps:setSpeed(100, 300)
  self.ps:emit(200)
  self.ps:stop()
  self.explodeLight.alpha = 150
  self.explodeLight.x = self.x
  self.explodeLight.y = self.y
  self.lightTimer = self.lightTime

  local dist
  for e in Enemy.all:iterate() do
    if not e:isInstanceOf(Spawner) then
      dist = math.distance(self.x, self.y, e.x, e.y) 
      if dist <= self.damageRadius then e:rocketDamage((1 - dist / self.damageRadius) * self.damage) end
    end
  end
end

function Fireball:collided(other)
  if other:isInstanceOf(Enemy) or other:isInstanceOf(Walls) then
    self:die()
  end
end
