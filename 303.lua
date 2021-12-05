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

local ROMAN_CHORDS={"I","ii","iii","IV","V","vi","vii","I"}
pss={}
pss["chord"]={name="chord",mapfn=util.linlin,mapping={0,8},default={1,6,3,5},sn=16}
pss["prob"]={name="prob",mapfn=util.linlin,mapping={0,1},default={1}}
pss["dec"]={name="dec",mapfn=util.linexp,mapping={0.1,4},default={3}}
pss["sus"]={name="sus",mapfn=util.linlin,mapping={0.0,1},default={3}}
pss["res"]={name="res",mapfn=util.linexp,mapping={0.02,0.4},default={3}}
pss["env"]={name="env",mapfn=util.linlin,mapping={250,2000},default={3}}
pss["ctf"]={name="ctf",mapfn=util.linexp,mapping={25,400},default={3}}
pss["wave"]={name="wave",mapfn=util.linlin,mapping={0,1},default={1}}
pss["pitch"]={name="pitch",mapfn=util.linlin,mapping={0,8},default={8},sn=4}

local ordering_lattice={"chord","prob","dec","sus","res","env","ctf","wave","pitch"}
local ordering_select={"chord","pitch","prob","dec","sus","res","env","ctf","wave"}
ordering_select_current=1
local shift=false

-- TODO: table of parameters
function init()
  for bank,k in ipairs(ordering_lattice) do
    local ps=pss[k]
    pss[k].bank=bank
    pss[k].step=16
    pss[k].step_max=4
    pss[k].sn=ps.sn or 1
  end

  grid_=grid__:new({mems=#ordering_select})
  for _,k in ipairs(ordering_lattice) do
    local ps=pss[k]
    for col,row in ipairs(ps.default) do
      grid_:toggle_single(row,col,ps.bank)
      if ps.name~="chord" then
        grid_:toggle_single(row,col+1,ps.bank)
      end
    end
  end
  grid_:set_bank(1)
  ordering_select_current=1

  -- start lattice
  song={root=36,scale="Major"}
  sequencer=lattice:new{
    ppqn=96
  }
  local step_global=0
  local last_step={}
  local current_notes={}
  sequencer:new_pattern({
    action=function(t)
      step_global=step_global+1
      for _,k in ipairs(ordering_lattice) do
        local ps=pss[k]
        local step_max=grid_:last_col(ps.bank)
        local step=math.ceil(((step_global-1)%(step_max*ps.sn)+1)/ps.sn)
        if ps.bank==pss[ordering_select[ordering_select_current]].bank then 
          grid_:set_col(ps.bank,step)
        end
        if (last_step~=nil and last_step[k]~=step) or step_max==1 then
          -- new step!
          -- set the new value
          local grid_val=grid_:get_col(step,ps.bank)
          pss[k].val=ps.mapfn(0,8,ps.mapping[1],ps.mapping[2],grid_val)
          if k=="chord" then
            -- change the chord
            local chord_index=math.floor(pss[k].val)
            if chord_index>0 then 
              print(chord_index,ROMAN_CHORDS[chord_index])
              current_notes=generate_note(song.root,song.scale,ROMAN_CHORDS[chord_index])
            end
          elseif k=="pitch" then
            print(k,step,last_step[k])
            -- emit the ntoe
            note_index=math.floor(pss[k].val)
            if note_index > 0 then 
              local note=current_notes[note_index]
              local d={}
              d.note=note 
              for k_,ps_ in pairs(pss) do 
                d[k_]=ps_.val
              end
              play_note(d)
            end
          end
        end
        last_step[k]=step
      end
      redraw()
    end,
    division=1/16
  })
  sequencer:hard_restart()

end

function play_note(d)
  if d==nil then
    d={}
  end
  if d.prob~=nil and math.random()>d.prob then 
    do return end
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
  elseif k==2 then
  elseif k==3 then
    pss[ordering_select[ordering_select_current]].sn=util.clamp(pss[ordering_select[ordering_select_current]].sn+d,1,16)
  end
end

function key(k,z)
  if k==1 then
    shift=z==1
  end
  if shift and k==3 then
    sequencer:hard_restart()
  elseif not shift and k>1 and z==1 then
    ordering_select_current=util.clamp(ordering_select_current+(k*2-5),1,#ordering_select)
    print("setting bank to ",pss[ordering_select[ordering_select_current]].bank,ordering_select_current)
    grid_:set_bank(pss[ordering_select[ordering_select_current]].bank)
  end
end

function redraw()
  screen.clear()
  screen.move(10,10)
  screen.text("303 "..ordering_select[ordering_select_current])
  screen.move(10,40)
  local ps=pss[ordering_select[ordering_select_current]]
  screen.text(ps.sn)
  screen.update()
end

function rerun()
  norns.script.load(norns.state.script)
end

function cleanup()

end


