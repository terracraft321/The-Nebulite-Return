function init()
  script.setUpdateDelta(5)

  self.healingRate = config.getParameter("healRate", 1)
end

function update(dt)
  status.modifyResource("health", self.healingRate * dt)
end

function uninit()
  
end
