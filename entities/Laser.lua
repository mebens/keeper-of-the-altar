Laser = class("Laser", Entity)
Laser.static.particle = getRectImage(3, 1)

function Laser:initialize()
  Entity.initialize(self)
  self.layer = 7
  self.angle = 0
  self.firing = false
  self.fireDistance = 1000
  self.dps = 400
  self.maxPenetrations = 0

  local ps = love.graphics.newParticleSystem(Laser.particle, 1000)
  ps:setSpread(math.tau)
  ps:setSpeed(100, 150)
  ps:setLinearDamping(30, 40)
  ps:setColors(255, 0, 0, 255, 255, 0, 0, 0)
  ps:setParticleLifetime(0.2)
  ps:setRelativeRotation(true)
  ps:setSizeVariation(0.5)
  ps:setSizes(1, 0.6, 0.1)
  self.ps = ps
  self.particleDelay = 0.1
  self.particleTimer = 0
end

function Laser:update(dt)
  self.ps:update(dt)

  if self.firing then
    if self.particleTimer > 0 then
      self.particleTimer = self.particleTimer - dt
    else
      local x1, y1, ps = self.x, self.y, self.ps
      local dist = math.distance(x1, y1, self.x2, self.y2)
      local cos, sin = dist * math.cos(self.angle), dist * math.sin(self.angle)
      self.particleTimer = self.particleDelay

      for i = 1, 100 do
        ps:moveTo(x1 + cos * i / 100, y1 + sin * i / 100)
        ps:emit(3)
      end
    end
  end
end

function Laser:draw()
  if self.firing then
    love.graphics.setColor(255, 0, 0)
    love.graphics.setLineWidth(1)
    love.graphics.line(self.x, self.y, self.x2, self.y2)
  end

  love.graphics.draw(self.ps)
end

function Laser:fire(dt, x, y, angle)
  local x2 = x + self.fireDistance * math.cos(angle)
  local y2 = y + self.fireDistance * math.sin(angle)
  self.x = x
  self.y = y
  self.angle = angle
  self.firing = true

  local penetrations = 0

  self.world:rayCast(x, y, x2, y2, function(fixt, xc, yc, xn, yn, frac)
    local e = fixt:getUserData()

    if e:isInstanceOf(Walls) or e:isInstanceOf(Altar) then
      self.x2 = xc
      self.y2 = yc
      return 0
    elseif e:isInstanceOf(Enemy) then
      e:laserDamage(self.dps * dt)

      if penetrations < self.maxPenetrations then
        penetrations = penetrations + 1
        return math.distance(xc, yc, x2, y2)
      else
        self.x2 = xc
        self.y2 = yc
        return 0
      end
    else

      return math.distance(xc, yc, x2, y2)
    end
  end)

  if not self.x2 then
    self.x2 = x2
    self.y2 = y2
  end
end

function Laser:reset()
  self.firing = false
  self.x2 = nil
  self.y2 = nil
end

