Spawner = class("Spawner", Entity)

function Spawner:initialize(pos, etype, rate, count)
  Entity.initialize(self)
  self.position = pos
  self.type = etype
  self.rate = rate
  self.count = count or 0
  self.timer = 0
  self.spawned = 0
end

function Spawner:added()
  self.x = self.world.spawnerPositions[self.position].x
  self.y = self.world.spawnerPositions[self.position].y

  if self.position == "left" or self.position == "right" then
    self.xVariance = 0
    self.yVariance = 7 * TILE_SIZE
    --self.angle = self.position == "left" and math.tau or math.tau / 2
  else
    self.xVariance = 7 * TILE_SIZE
    self.yVariance = 0
    --self.angle = self.position == "top" and math.tau * 0.75 or math.tau / 4
  end

  Enemy.all:push(self)
end

function Spawner:removed()
  Enemy.all:remove(self)
end

function Spawner:update(dt)
  if self.timer > 0 then
    self.timer = self.timer - dt
  else
    local x = self.x - self.xVariance / 2 + self.xVariance * math.random()
    local y = self.y - self.yVariance / 2 + self.yVariance * math.random()

    if self.type == "knight" then
      self.world:add(Knight:new(x, y))
    end

    self.timer = self.rate
    self.spawned = self.spawned + 1

    if self.count > 0 and self.spawned >= self.count then
      self.world = nil
    end
  end
end

function Spawner:stop()
  self.world = nil
end

      