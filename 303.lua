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

local PITCH=1
local PROB=2
local DECAY=3
local SUS=4
local RES=5
local ENV=6

local ROMAN_CHORDS={"I","ii","iii","VI","V","vi","vii"}
local pss={
  {name="chord",mapfn=util.linlin,mapping={1,8},default={1,6,3,5}},
  {name="prob",mapfn=util.linlin,mapping={0,1},default={1}},
  {name="decay",mapfn=util.linexp,mapping={0.1,4},default={2}},
  {name="sus",mapfn=util.linlin,mapping={0.0,1},default={0.5}},
  {name="res",mapfn=util.linexp,mapping={0.02,0.4},default={0.2}},
  {name="env",mapfn=util.lilnlin,mapping={250,2000},default={1000}},
  {name="ctf",mapfn=util.linexp,mapping={25,400},default={100}},
{name="wave",mapfn=util.linlin,mapping={0,1},default={0]}},
}
for i,ps in ipairs(pss) do
  pss[i].step=16
  pss[i].step_max=4
  pss[i].sn=1
end

-- TODO: table of parameters
function init()
  grid_=grid__:new({mems=#pss})
  for _,ps in ipairs(pss) do
    for col,val in ipairs(ps.default) do
      grid_:toggle_single(math.floor(ps.mapfn(ps.mapping[1],ps.mapping[2],8,1,val)),col)
    end
  end

  -- start lattice
  local sequencer=lattice:new{
    ppqn=96
  }
  sequencer:new_pattern({
    action=function(t)
      local steps_max={16}
      for bank=1,8 do
        table.insert(steps_max,grid_:last_col(bank))
      end
      for i,_ in ipairs(steps_max) do
        steps[i]=steps[i]+1
        if steps[i]>steps_max[i] then
          steps[i]=1
        end
      end
      -- chords
      if steps[1]==1 then
        local prog=song.progression()
        print(prog)
        song.notes=generate_note(song.root,song.scale,prog)
        -- tab.print(song.notes)
        for i=1,3 do
          engine.tot_pad(0.0,song.notes[i]+24,clock.get_beat_sec()*4)
        end
      end
      grid_:set_col(steps[grid_.bank+1])
      local prob=util.linlin(0,8,0,1,grid_:get_col(steps[PROB+1],PROB))
      local decay=util.linexp(0,8,0.1,4,grid_:get_col(steps[DECAY+1],DECAY))
      local sus=util.linlin(0,8,0,1,grid_:get_col(steps[SUS+1],SUS))
      local res=util.linexp(0,8,0.05,0.5,grid_:get_col(steps[RES+1],RES))
      local env=util.linexp(0,8,100,2000,grid_:get_col(steps[ENV+1],ENV))
      if math.random()<prob then
        local note_index=grid_:get_col(steps[PITCH+1],PITCH)
        if note_index>0 then
          local note=song.notes[note_index]
          play_note({note=note,dec=decay,sus=sus,res=res,env=env})
        end
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
  engine.tot_bass(
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
  -- TODO:
  -- allow encoder to modulate the division

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
