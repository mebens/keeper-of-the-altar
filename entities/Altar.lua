Altar = class("Altar", PhysicalEntity)
Altar.static.width = 27
Altar.static.height = 27
Altar.static.emberParticle = getRectImage(2, 1)

function Altar:initialize(x, y)
  PhysicalEntity.initialize(self, x, y, "static")
  self.layer = 6
  self.width = Altar.width
  self.height = Altar.height
  self.maxHealth = 2000
  self.health = self.maxHealth
  self.pulseFactor = 0
  self.pulseDir = 1

  self.map = Spritemap:new(assets.images.altar, 27, 27, self.fireAnimation, self)
  self.map:add("calm", { 9, 10, 11, 12, 13, 14, 15, 16 }, 4, true)

  local ps = love.graphics.newParticleSystem(Altar.emberParticle, 300)
  ps:setPosition(x, y)
  ps:setAreaSpread("normal", 2, 2)
  ps:setTangentialAcceleration(-20, 20)
  ps:setRelativeRotation(true)
  ps:setColors(245, 85, 0, 220, 225, 70, 0, 50)
  ps:setSpread(math.tau)
  ps:setSizeVariation(0.5)
  ps:setSizes(1, 0.6, 0.1)
  ps:setLinearDamping(0.5, 1)
  ps:setSpeed(20, 30)
  ps:setParticleLifetime(3, 5)
  ps:setEmitterLifetime(-1)
  ps:setEmissionRate(10)
  self.emberPS = ps
end

function Altar:added()
  self:setupBody()
  self.fixture = self:addShape(love.physics.newRectangleShape(self.width, self.height))
  self.light = self.world.lighting:add(self.x, self.y, 150)
  self:switchMode("calm")
end

function Altar:update(dt)
  PhysicalEntity.update(self, dt)
  self.map:update(dt)
  self.emberPS:update(dt)

  if self.mode == "calm" then
    self.pulseFactor = self.pulseFactor + dt * self.pulseDir

    if self.pulseFactor >= 2 then
      self.pulseFactor = 2
      self.pulseDir = -1
    elseif self.pulseFactor <= 0 then
      self.pulseFactor = 0
      self.pulseDir = 1
    end

    self.light.alpha = 255 - 125 * self.pulseFactor / 2

    if self.fixture:testPoint(mouseCoords()) then
      self.world.hud:displayTooltip(self, "The Altar")
    elseif self.world.hud.ttID == self then
      self.world.hud:closeTooltip()
    end
  else
    self.light.alpha = math.clamp(self.light.alpha - 16 + math.random(32), 191, 255)
  end
end

function Altar:draw()
  self:drawMap()
  love.graphics.draw(self.emberPS)
end

function Altar:die()
  if self.dead then return end
  self.dead = true
  playSound("altar-death")
  self.world:gameOver()
end

function Altar:damage(amount)
  self.health = math.max(self.health - amount, 0)

  if self.health == 0 then
    self:die()
  end
end

function Altar:switchMode(mode)
  if mode == "fire" then
    self:fireAnimation()
    self.light.color = { 230, 175, 125 }
    self.emberPS:start()
    self:fireBurst()
  else
    if self.mode == "fire" then self:fireBurst() end
    self.map:play("calm")
    tween(self.light.color, 1, { 170, 100, 200 })
    self.emberPS:stop()
  end

  self.mode = mode
end

function Altar:fireBurst()
  self.emberPS:setSpeed(50, 80)
  self.emberPS:emit(200)
  self.emberPS:setSpeed(20, 30)
  playRandom({"altar-burst", "altar-burst2"}, 0.7)
end

function Altar:fireAnimation()
  self.map:add("fire", shuffleTable{ 1, 2, 3, 4, 5, 6, 7, 8 }, 4, false)
  self.map:play("fire")
end
