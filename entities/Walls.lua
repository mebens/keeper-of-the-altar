Walls = class("Walls", PhysicalEntity)

function Walls:initialize(xml, width, height)
  PhysicalEntity.initialize(self, 0, 0, "static")
  self.layer = 2
  self.width = width
  self.height = height
  self.map = Tilemap:new(assets.images.tiles, TILE_SIZE, TILE_SIZE, width, height)
  self.xml = xml
  self.color = { 180, 180, 180 }
end

function Walls:added()
  self:setupBody()
  if self.xml then self:loadFromXML(self.xml) end
end

function Walls:loadFromXML(xml)
  local elem = findChild(xml, "Walls")
  
  for _, v in ipairs(findChildren(elem, "tile")) do
    self.map:set(tonumber(v.attr.x), tonumber(v.attr.y), tonumber(v.attr.id) + 1)
  end
  
  elem = findChild(xml, "Collision")
  
  for _, v in ipairs(findChildren(elem, "rect")) do
    local w, h = tonumber(v.attr.w), tonumber(v.attr.h)
    local fixt = self:addShape(love.physics.newRectangleShape(tonumber(v.attr.x) + w / 2, tonumber(v.attr.y) + h / 2, w, h))
    fixt:setCategory(16)
  end
end

function Walls:draw()
  love.graphics.setColor(self.color)
  self.map:draw(self.x, self.y)
end
