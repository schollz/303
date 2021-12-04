-- 303 v0.0.0
--
--
-- llllllll.co/t/303
--
--
--
--    ▼ instructions below ▼

grid__=include("303/lib/grid_")
MusicUtil=require "musicutil"
lattice=require("lattice")

engine.name="ThreeOhThree"

function init()
  grid_=grid__:new()

  -- start lattice
  local sequencer=lattice:new{
    ppqn=96
  }
  local step=16
  sequencer:new_pattern({
    action=function(t)
      step=step+1
      if step>16 then
        step==1
      end
      grid_:set_col(step)
    end,
    division=1/16,
  })
  sequencer:hard_restart()

end

function enc(k,d)
  if k==1 then
    grid_:delta_bank(d)
  end
end

function key(k,z)

end

function redraw()
  screen.clear()
  screen.move(32,64)
  screen.text("303")

  screen.update()
end

function rerun()
  norns.script.load(norns.state.script)
end

function cleanup()

end
