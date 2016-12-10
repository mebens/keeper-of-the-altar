Player = class("Player", PhysicalEntity)
Player.static.width = 10
Player.static.height = 10

function Player:initialize(x, y)
  PhysicalEntity.initialize(self, x, y, "dynamic")
  self.layer = 4
  self.width = Player.width
  self.height = Player.height
  self.image = assets.images.demonMg
  self.speed = 1800 * 60 -- 1800 per frame at 60 fps
  self.health = 100
  self.lives = 2

  self.weapon = "sg"
  self.attackTimer = 0
  self.mgAttackTime = 0.2
  self.smgAttackTime = 0.04
  self.smgVariance = math.tau / 18
  self.sgAttackTime = 0.5
  self.sgVariance = math.tau / 10
  self.sgPellets = 15
end

function Player:added()
  self:setupBody()
  self.fixture = self:addShape(love.physics.newRectangleShape(self.width, self.height))
  self.fixture:setCategory(2)
  self:setMass(1)
  self:setLinearDamping(20)

  self.light = self.world.lighting:add(self.x, self.y, 70)
  self.light.alpha = 125
end

function Player:update(dt)
  PhysicalEntity.update(self, dt)
  self:setAngularVelocity(0)

  self.angle = math.angle(self.x, self.y, mouseCoords())
  local dir = self:getDirection()
  if dir then self:applyForce(self.speed * math.cos(dir) * dt, self.speed * math.sin(dir) * dt) end

  if self.attackTimer > 0 then
    self.attackTimer = self.attackTimer - dt
  elseif input.down("attack") then
    self:attack()
    self.attackTimer = self[self.weapon .. "AttackTime"]
  end

  self.light.x = self.x
  self.light.y = self.y
end

function Player:attack()
  if self.weapon == "mg" then
    self.world:add(Bullet:new(self.x + 5 * math.cos(self.angle), self.y + 5 * math.sin(self.angle), self.angle, "med"))
  elseif self.weapon == "smg" then
    local angle = self.angle - self.smgVariance / 2 + self.smgVariance * math.random()
    self.world:add(Bullet:new(self.x + 5 * math.cos(self.angle), self.y + 5 * math.sin(self.angle), angle, "low"))
  elseif self.weapon == "sg" then
    for i = 1, self.sgPellets do
      local angle = self.angle - self.sgVariance / 2 + self.sgVariance * math.random()
      self.world:add(Bullet:new(self.x + 5 * math.cos(self.angle), self.y + 5 * math.sin(self.angle), angle, "pellet"))
    end
  end
end

function Player:draw()
  self:drawImage()
end

function Player:getDirection()
  local xAxis = input.axisDown("left", "right")
  local yAxis = input.axisDown("up", "down")
  
  local xAngle = xAxis == 1 and 0 or (xAxis == -1 and math.tau / 2 or nil)
  local yAngle = yAxis == 1 and math.tau / 4 or (yAxis == -1 and math.tau * 0.75 or nil)
  
  if xAngle and yAngle then
    -- x = 1, y = -1 is a special case the doesn't fit
    if xAxis == 1 and yAxis == -1 then xAngle = math.tau end
    return (xAngle + yAngle) / 2
  else
    return xAngle or yAngle
  end
end