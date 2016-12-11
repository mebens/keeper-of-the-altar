Brazier = class("Brazier", PhysicalEntity)
Brazier.static.width = 9
Brazier.static.height = 9

function Brazier:initialize(x, y, turret)
  PhysicalEntity.initialize(self, x, y, "static")
  self.layer = 6
  self.map = Spritemap(assets.images.brazier, 9, 9, self.fireAnimation, self)
  self:fireAnimation()
  self.width = Brazier.width
  self.height = Brazier.height
  self.fireTimer = 0
  self.fireTime = 1.5
  self.fireDist = 40
  self.turret = turret

  local ps = love.graphics.newParticleSystem(Altar.emberParticle, 300)
  ps:setPosition(x, y)
  ps:setAreaSpread("normal", 0.5, 0.5)
  ps:setTangentialAcceleration(-10, 10)
  ps:setRelativeRotation(true)
  ps:setColors(245, 85, 0, 220, 225, 70, 0, 50)
  ps:setSpread(math.tau)
  ps:setSizeVariation(0.5)
  ps:setSizes(1, 0.6, 0.1)
  ps:setLinearDamping(0.5, 1)
  ps:setSpeed(5, 10)
  ps:setParticleLifetime(3, 5)
  ps:setEmitterLifetime(-1)
  ps:setEmissionRate(10)
  ps:start()
  self.emberPS = ps
end

function Brazier:added()
  self:setupBody()
  self.fixture = self:addShape(love.physics.newRectangleShape(self.width, self.height))
  self.light = self.world.lighting:add(self.x, self.y, 70)
  self.light.color = { 230, 175, 125 }
  self.light.alpha = 150

  if self.turret then
    self:makeTurret()
  end
end

function Brazier:update(dt)
  PhysicalEntity.update(self, dt)
  self.map:update(dt)
  self.emberPS:update(dt)
  self.light.alpha = math.clamp(self.light.alpha - 16 + math.random(32), 191, 255)

  if self.turret then
    if self.fireTimer > 0 then
      self.fireTimer = self.fireTimer - dt
    else
      self.fireTimer = self.fireTime
      local enemy

      for e in Enemy.all:iterate() do
        if not e:isInstanceOf(Spawner) then
          local d = math.distance(self.x, self.y, e.x, e.y)

          if d < self.fireDist then
            enemy = e
            break
          end
        end
      end

      if enemy then
        self.world:add(Fireball:new(self.x, self.y, enemy))
      end
    end
  elseif not self.world.inWave then
    if self.fixture:testPoint(mouseCoords()) then
      self.world.hud:displayTooltip(self, "Create Turret", 15)
    elseif self.world.hud.ttID == self then
      self.world.hud:closeTooltip()
    end
  end
end

function Brazier:draw()
  self:drawMap()
  love.graphics.draw(self.emberPS)
end

function Brazier:fireAnimation()
  self.map:add("fire", shuffleTable{ 1, 2, 3, 4, 5, 6 }, 4, false)
  self.map:play("fire")
end

function Brazier:makeTurret()
  self.turret = true
  self.emberPS:setEmissionRate(20)
  self.emberPS:setSpeed(10, 15)
end