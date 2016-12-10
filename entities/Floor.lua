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
  
  for _, v in ipairs(findChildren(elem, "tile")) do
    self.map:set(tonumber(v.attr.x), tonumber(v.attr.y), tonumber(v.attr.id) + 1)
  end
end

function Floor:draw()
  love.graphics.setColor(self.color)
  self.map:draw(self.x, self.y)
end
