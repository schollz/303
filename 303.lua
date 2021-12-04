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
s=require("sequins")
engine.name="ThreeOhThree"

function init()
  grid_=grid__:new()
  grid_:toggle_row(1,1,1,16,2)
  grid_:toggle_row(1,1,1,16,3)

  song={progression=s{"vi","iii","I","V"},root=36-12,scale='Major',notes={}}
  -- start lattice
  local sequencer=lattice:new{
    ppqn=96
  }
  local step=16
  sequencer:new_pattern({
    action=function(t)
      step=step+1
      if step>16 then
        step=1
        local prog=song.progression()
        print(prog)
        song.notes=generate_note(song.root,song.scale,prog)
        -- tab.print(song.notes)
      end
      grid_:set_col(step)
      local PITCH=1
      local PROB=2
      local DECAY=3
      local prob=util.linlin(0,8,0,1,grid_:get_col(step,PROB))
      local decay=util.linexp(0,8,0.1,4,grid_:get_col(step,DECAY))
      if math.random()<prob then
        local note_index=grid_:get_col(step,PITCH)+1
        local note=song.notes[note_index]
        play_note({note=note,dec=decay})
      end
      redraw()
    end,
    division=1/16,
  })
  sequencer:hard_restart()

end

function play_note(d)
  if d==nil then
    d={}
  end
  d.gate=d.gate or 1
  d.amp=d.amp or 0.5
  d.note=d.note or 40
  d.wave=d.wave or 0
  d.ctf=d.ctf or 100
  d.res=d.res or 0.2
  d.sus=d.sus or 0.5
  d.dec=d.dec or 0.5
  d.env=d.env or 1000
  d.port=d.port or 0
  engine.tot_play(
    d.gate,
    d.amp,
    d.note,
    d.wave,
    d.ctf,
    d.res,
    d.sus,
    d.dec,
    d.env,
  d.port)
end

function generate_note(root,scale,roman_num)
  local notes=MusicUtil.generate_chord_roman(root,scale,roman_num)
  table.sort(notes)
  local scale=MusicUtil.generate_scale(root+12,scale,4)
  table.sort(scale)
  local note_list={}
  local note_have={}
  for _,note in ipairs(notes) do
    note_have[note]=true
    table.insert(note_list,note)
  end
  for _,note in ipairs(scale) do
    if note_have[note]==nil and #note_list<9 then
      table.insert(note_list,note)
    end
  end
  return note_list
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
  screen.text("303 "..grid_.bank)

  screen.update()
end

function rerun()
  norns.script.load(norns.state.script)
end

function cleanup()

end
