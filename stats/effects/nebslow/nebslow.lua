function init()
  script.setUpdateDelta(5)
end

function update(dt)
  mcontroller.controlModifiers({
      groundMovementModifier = 0.8,
      speedModifier = 0.8
    })
end

function uninit()

end
