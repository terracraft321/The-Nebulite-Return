require "/scripts/vec2.lua"

function init()
  self.targetSpeed = vec2.mag(mcontroller.velocity())
  self.controlForce = config.getParameter("baseHomingControlForce") * self.targetSpeed
  
  self.targets = world.entityQuery(mcontroller.position(), 50, {
      withoutEntityId = projectile.sourceEntity(),
      includedTypes = {"player"},
      order = "nearest"
    })
    
  for _, target in ipairs(self.targets) do
    if entity.entityInSight(target) then
      local targetPos = world.entityPosition(target)
      local myPos = mcontroller.position()
      local dist = world.distance(targetPos, myPos)

      mcontroller.approachVelocity(vec2.mul(vec2.norm(dist), self.targetSpeed), self.controlForce)
      return
    end
  end
end

function update()
  
end
