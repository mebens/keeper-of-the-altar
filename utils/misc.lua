function playSound(sound, volume, pan)
  if type(sound) == "string" then sound = assets.sfx[sound] end
  return sound:play(volume, pan)
end

function playRandom(sounds, volume, pan)
  return playSound(sounds[math.random(1, #sounds)], volume, pan)
end

function mouseCoords()
  local x, y = love.mouse.getPosition()
  return x / postfx.scale, y / postfx.scale
end

function getRectImage(width, height, r, g, b, a)
  r = r or 255
  g = g or 255
  b = b or 255
  a = a or 255
  
  local data = love.image.newImageData(width, height)
  data:mapPixel(function() return r, g, b, a end)
  return love.graphics.newImage(data)
end

function drawArc(x, y, r, angle1, angle2, segments)
  local i = angle1
  local j = 0
  local step = math.tau / segments
  
  while i < angle2 do
    j = angle2 - i < step and angle2 or i + step
    love.graphics.line(x + (math.cos(i) * r), y - (math.sin(i) * r), x + (math.cos(j) * r), y - (math.sin(j) * r))
    i = j
  end  
end

function Entity:drawImage(image, x, y, color, ox, oy)
  image = image or self.image
  color = color or self.color
  if color then love.graphics.setColor(color) end
  local imageScale = self.imageScale or 1
  local scale = imageScale * (self.scale or 1)
  angle = self.angle
  if self.drawPerpAngle then angle = angle + math.tau / 4 end

  love.graphics.draw(
    image,
    x or self.x,
    y or self.y,
    angle,
    self.scaleX or scale,
    self.scaleY or scale,
    ox or image:getWidth() / 2,
    oy or image:getHeight() / 2
  )
end

function Entity:drawMap(map, x, y, color, ox, oy)
  map = map or self.map
  color = color or self.color
  angle = self.angle
  if self.drawPerpAngle then angle = angle + math.tau / 4 end
  if color then love.graphics.setColor(color) end
  local imageScale = self.imageScale or 2
  local scale = imageScale * (self.scale or 1)
  
  map:draw(
    x or self.x,
    y or self.y,
    angle,
    self.scaleX or scale,
    self.scaleY or scale,
    ox or map.width / 2,
    oy or map.height / 2
  )
end
