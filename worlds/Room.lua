Room = class("Room", PhysicalWorld)

function Room:initialize()
  PhysicalWorld.initialize(self)
  self.coins = 0
  self.inWave = false
  self.totalWaves = 1
  self.camera.x = love.graphics.width / 2
  self.camera.y = love.graphics.height / 2

  self:setupLayers{
    [0] = { 1, pre = postfx.exclude, post = postfx.include }, -- hud
    [1] = 1, -- lighting
    [2] = 1, -- walls
    [3] = 1, -- particle effects
    [4] = 1, -- player
    [5] = 1, -- enemies
    [6] = 1, -- objects
    [7] = 1, -- projectiles
    [8] = 1, -- coins
    [9] = 1, -- bodies
    [10] = 1, -- blood
    [11] = 1 -- floor
  }

  local xmlFile = love.filesystem.read("room.oel")
  self.xml = slaxml:dom(xmlFile).root
  self.width = tonumber(self.xml.attr.width)
  self.height = tonumber(self.xml.attr.height)

  local ent = findChild(self.xml, "Entities")
  local pobj = findChild(ent, "Player")
  self.player = Player:new(tonumber(pobj.attr.x) + Player.width / 2, tonumber(pobj.attr.y) + Player.height / 2)

  local aobj = findChild(ent, "Altar")
  self.altar = Altar:new(tonumber(aobj.attr.x) + Altar.width / 2, tonumber(aobj.attr.y) + Altar.height / 2)

  self:add(self.player, self.altar)

  self.walls = Walls:new(self.xml, self.width, self.height)
  self.floor = Floor:new(self.xml, self.width, self.height)
  self.lighting = Lighting:new(self.width, self.height)
  self.floorBlood = FloorBlood:new(self.width, self.height)
  self.hud = HUD:new()
  self:add(self.walls, self.floor, self.lighting, self.hud, self.floorBlood)

  self.spawnerPositions = {}
  self.spawnerMargin = TILE_SIZE * 3

  for _, v in pairs(findChildren(ent, "SpawnerPos")) do
    local pos = v.attr.position
    local t = { x = v.attr.x, y = v.attr.y }

    if pos == "left" then
      t.x = t.x - self.spawnerMargin
    elseif pos == "right" then
      t.x = t.x + self.spawnerMargin
    elseif pos == "top" then
      t.y = t.y - self.spawnerMargin
    elseif pos == "bottom" then
      t.y = t.y + self.spawnerMargin
    end

    self.spawnerPositions[pos] = t
  end
end

function Room:start()
  self:startWave(1)
end

function Room:update(dt)
  PhysicalWorld.update(self, dt)

  if self.inWave then
    if self.wait == "enemies" then
      if Enemy.all.length == 0 then self.wait = 0 end
    elseif self.wait > 0 then
      self.wait = self.wait - dt
    else
      local index, rep

      if self.waveNum < self.totalWaves then
        index, rep = self["wave" .. self.waveNum](self, self.waveIndex, self.waveReps)
      else
        index, rep = self:waveFinal(self.waveIndex, self.waveReps)
      end

      if index == nil then
        self:endWave()
      else
        self.waveIndex = index
      end

      if rep then
        self.waveReps = self.waveReps + 1
      else
        self.waveReps = 0
      end
    end
  end
end

function Room:startWave(num)
  self.inWave = true
  self.waveIndex = 1
  self.waveReps = 0
  self.wait = 0
  self.waveNum = num
  self.altar:switchMode("fire")
end

function Room:nextWave()
  self:startWave(math.min(self.waveNum + 1, self.totalWaves))
end

function Room:endWave()
  self.inWave = false
  self.altar:switchMode("calm")
  self.hud:updateUpgrades()
end

function Room:coinCollected()
  self.coins = self.coins + 1
end

function Room:purchaseUpgrade(id)
  local level = self.player[id .. "Level"]
  local upgrade = Player[id .. "Upgrades"][level + 1]

  if upgrade then
    self.player:upgradeTo(id, level + 1)
    self.coins = self.coins - upgrade[2]
  end
end

function Room:waveFinal(i, r)
  if i == 1 then
    self:add(Spawner:new("left", "knight", 0.5, 10))
    self.wait = "enemies"
    return 2, false
  else
    return nil, true
  end
end
