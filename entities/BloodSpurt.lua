BloodSpurt = class("BloodSpurt", PhysicalEntity)

function BloodSpurt:initialize(x, y, angle, size, scatter, speedFactor)
  PhysicalEntity.initialize(self, x, y, "dynamic")
  self.angle = angle
  self.size = size or 2
  self.sizeExpansion = 10
  self.scatter = scatter or 3
  self.scatterExpansion = 12
  self.interval = 1
  self.impulse = math.random(30, 60) * (speedFactor or 1)
  self.lastX = self.x
  self.lastY = self.y
  self.visible = false
end

function BloodSpurt:added()
  self:setupBody()
  self.fixture = self:addShape(love.physics.newCircleShape(self.size / 2))
  self.fixture:setMask(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15) -- all except 16, walls
  self.fixture:setRestitution(1)
  self:setMass(0.1)
  self:setLinearDamping(50)
  self:applyLinearImpulse(self.impulse * math.cos(self.angle), self.impulse * math.sin(self.angle))
  self.world.floorBlood:bleed(self.x, self.y, self.size, self.scatter)
end

function BloodSpurt:update(dt)
  PhysicalEntity.update(self, dt)
  self.size = self.size + self.sizeExpansion * dt
  self.scatter = self.scatter + self.scatterExpansion * dt
  local dist = math.distance(self.x, self.y, self.lastX, self.lastY)
  
  if dist >= self.interval * 2 then
    local angle = math.angle(self.x, self.y, self.lastX, self.lastY)
    
    for i = 1, math.floor(dist / self.interval - 1) do
      self.world.floorBlood:bleed(
        self.x + math.cos(angle) * self.interval * i,
        self.y + math.sin(angle) * self.interval * i,
        self.size,
        self.scatter
      )
    end
  end
  
  if dist >= self.interval then
    self.world.floorBlood:bleed(self.x, self.y, self.size, self.scatter)
    self.lastX = self.x
    self.lastY = self.y
  end
  
  if math.distance(0, 0, self.velx, self.vely) < 4 then
    self.world = nil
  end
end