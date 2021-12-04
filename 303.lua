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

local ROMAN_CHORDS={"I","ii","iii","VI","V","vi","vii","II"}
local pss={}
pss["chord"]={name="chord",mapfn=util.linlin,mapping={1,8},default={1,6,3,5},sn=16}
pss["prob"]={name="prob",mapfn=util.linlin,mapping={0,1},default={1}},
pss["decay"]={name="decay",mapfn=util.linexp,mapping={0.1,4},default={2}},
pss["sus"]={name="sus",mapfn=util.linlin,mapping={0.0,1},default={0.5}},
pss["res"]={name="res",mapfn=util.linexp,mapping={0.02,0.4},default={0.2}},
pss["env"]={name="env",mapfn=util.lilnlin,mapping={250,2000},default={1000}},
pss["ctf"]={name="ctf",mapfn=util.linexp,mapping={25,400},default={100}},
pss["wave"]={name="wave",mapfn=util.linlin,mapping={0,1},default={0}},
pss["pitch"]={name="pitch",mapfn=util.linlin,mapping={1,8},default={1}},

local ordering_lattice={"chord","prob","decay","sus","res","env","ctf","wave","pitch"}

-- TODO: table of parameters
function init()
  local bank=0
  for k,ps in pairs(pss) do
    bank=bank+1
    pss[k].bank=bank
    pss[k].step=16
    pss[k].step_max=4
    pss[k].sn=ps.sn or 1
    pss[k].val=ps.default[1]
  end

  grid_=grid__:new({mems=#pss})
  for _,ps in pairs(pss) do
    for col,val in ipairs(ps.default) do
      grid_:toggle_single(math.floor(ps.mapfn(ps.mapping[1],ps.mapping[2],8,1,val)),col)
    end
  end

  -- start lattice
  song={root=36,scale="Major"}
  local sequencer=lattice:new{
    ppqn=96
  }
  local step_global=0
  local last_step={}
  sequencer:new_pattern({
    action=function(t)
      step_global=step_global+1
      for _,k in ipairs(ordering_lattice) do
        local ps=pss[k]
        local step_max=grid_:last_col(ps.bank)
        local step=math.ceil(((step_global-1)%(step_max*ps.sn)+1)/ps.sn)
        print(k,step)
        if last_step~=nil and last_step[k]~=step then
          -- new step!
          -- set the new value
          local grid_val=grid_:get_col(step,ps.id)
          pss[k].val=ps.mapfn(0,8,ps.mapping[1],ps.mapping[2],grid_val)
          if k=="chord" then
            -- change the chord
          elseif k=="pitch" then
            -- emit the ntoe

          end
        end
        last_step[k]=step
      end,
      division=1/16
    })
    for _,k in ipairs(ordering_lattice) do
      local current_division=ps.division
      patterns[k]=sequencer:new_pattern({
        action=function(t)
          -- update the division
          if current_division~=ps.division then
            patterns[k]:set_division=ps.division
          end
          if k=="chord" then

          elseif k=="pitch" then

          end
        end,
        division=ps.division
      })
    end

    sequencer:new_pattern({
      action=function(t)
        step_global=step_global+1
        for i,ps in ipairs(pss) do
          local step=(step_global-1)%ps.step_max+1
          grid_:set_col(i,step)
          if ps.name=="chord" then
            -- special
            song.notes=generate_note(song.root,song.scale,)
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

 