Floor = class("Floor", Entity)

function Floor:initialize(xml, width, height)
  Entity.initialize(self)
  self.layer = 11
  self.width = width
  self.height = height
  self.map = Tilemap:new(assets.images.tiles, TILE_SIZE, TILE_SIZE, width, height)
  self.color = { 255, 255, 255 }
  if xml then self:loadFromXML(xml) end
end

function Floor:loadFromXML(xml)
  local elem = findChild(xml, "Floor")
  local id
  local baseStone = { 1, 6, 7, 8, 9, 10 }
  local stoneLen = #baseStone
  local altStone = { 18, 19, 20 }
  local altLen = #altStone
  local altStone2 = { 28, 29, 30 }
  local altLen2 = #altStone2

  for _, v in ipairs(findChildren(elem, "tile")) do
    id = tonumber(v.attr.id) + 1

    if id == 1 then
      id = baseStone[math.random(stoneLen)]
    elseif id == 20 then
      id = altStone[math.random(altLen)]
    elseif id == 30 then
      id = altStone2[math.random(altLen2)]
    end

    self.map:set(tonumber(v.attr.x), tonumber(v.attr.y), id)
  end
end

function Floor:draw()
  love.graphics.setColor(self.color)
  self.map:draw(self.x, self.y)
end
