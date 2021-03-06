local Grid_={}

function Grid_:new(args)
  local m=setmetatable({},{__index=Grid_})
  local args=args==nil and {} or args

  m.grid_on=args.grid_on==nil and true or args.grid_on

  -- initiate the grid
  m.g=grid.connect()
  m.g.key=function(x,y,z)
    if m.grid_on then
      m:grid_key(x,y,z)
    end
  end
  print("grid columns: "..m.g.cols)

  -- setup visual
  m.visual={}
  m.mem={}
  m.bank=1
  m.grid_width=16
  for i=1,8 do
    m.visual[i]={}
    for j=1,m.grid_width do
      m.visual[i][j]=0
    end
  end
  m.mems=args.mems or 8
  print("loading mems of ",m.mems)
  for bank=1,m.mems do
    m.mem[bank]={}
    for i=1,8 do
      m.mem[bank][i]={}
      for j=1,m.grid_width do
        m.mem[bank][i][j]=0
      end
    end
  end
  m.bank=1

  -- keep track of pressed buttons
  m.pressed_buttons={}
  m.highlight_column={}

  -- grid refreshing
  m.grid_refresh=metro.init()
  m.grid_refresh.time=0.03
  m.grid_refresh.event=function()
    if m.grid_on then
      m:grid_redraw()
    end
  end
  m.grid_refresh:start()

  return m
end

function Grid_:set_col(bank,c)
  if c~=nil and c>0 then
    self.highlight_column[bank]=c
  else
    self.highlight_column[bank]=nil
  end
end

function Grid_:set_bank(b)
  self.bank=b
end

function Grid_:delta_bank(d)
  if self.bank<#self.mem and d>0 then
    self.bank=self.bank+1
  elseif self.bank>1 and d<0 then
    self.bank=self.bank-1
  end
end

function Grid_:grid_key(x,y,z)
  self:key_press(y,x,z==1)
  self:grid_redraw()
end

function Grid_:key_press(row,col,on)
  if on then
    self.pressed_buttons[row..","..col]=true
  else
    self.pressed_buttons[row..","..col]=nil
  end

  local buttons={}
  for k,_ in pairs(self.pressed_buttons) do
    local row,col=k:match("(%d+),(%d+)")
    buttons[#buttons+1]={tonumber(row),tonumber(col)}
  end

  if on then
    if #buttons==2 then
      self:toggle_row(buttons[1][1],buttons[2][1],buttons[1][2],buttons[2][2])
    elseif #buttons==1 then
      self:toggle_single(row,col)
    end
  end
end

function Grid_:toggle_row(row1,row2,col1,col2,bank)
  local foo=col1
  local foo2=row1
  if col1>col2 then
    col1=col2
    col2=foo
    row1=row2
    row2=foo2
  end
  local slope=(row2-row1)/(col2-col1)
  for col=col1,col2 do
    self:set(math.floor(row1-((col1-col)*slope)),col,1,bank)
  end
end

function Grid_:toggle_single(row,col,bank)
  if self:get(row,col)>0 then
    self:set(row,col,0,bank)
  else
    self:set(row,col,1,bank)
  end
end

function Grid_:last_col(bank)
  bank=bank or self.bank
  local last_col=1
  for col=2,16 do
    for row=1,8 do
      if self.mem[bank][row][col]>0 then
        last_col=col
      end
    end
  end
  return last_col
end

function Grid_:set(row,col,val,bank)
  if bank==nil then
    bank=self.bank
  end
  for i=1,8 do
    self.mem[bank][i][col]=i>=row and 1 or 0
  end

end

function Grid_:get_col(col,bank)
  -- returns 0-8
  for row=1,8 do
    local val=self:get(row,col,bank)
    if val>0 then
      do return 9-row end
    end
  end
  return 0
end

function Grid_:get(row,col,bank)
  if bank==nil then
    bank=self.bank
  end
  return self.mem[bank][row][col]
end

function Grid_:get_visual()
  -- clear visual
  for row=1,8 do
    for col=1,self.grid_width do
      self.visual[row][col]=self.visual[row][col]-1
      if self.visual[row][col]<0 then
        self.visual[row][col]=0
      end
    end
  end

  -- illuminate current bank
  for row in ipairs(self.mem[self.bank]) do
    for col in ipairs(self.mem[self.bank][row]) do
      if self.mem[self.bank][row][col]>0 then
        self.visual[row][col]=7
      end
    end
  end

  -- highlight columns
  if self.highlight_column[self.bank]~=nil then
    local col=self.highlight_column[self.bank]
    for row=1,8 do
      self.visual[row][col]=self.visual[row][col]+5
      if self.visual[row][col]>15 then
        self.visual[row][col]=15
      end
    end
  end

  -- illuminate currently pressed button
  for k,_ in pairs(self.pressed_buttons) do
    local row,col=k:match("(%d+),(%d+)")
    self.visual[tonumber(row)][tonumber(col)]=15
  end

  return self.visual
end

function Grid_:grid_redraw()
  self.g:all(0)
  local gd=self:get_visual()
  if gd==nil then 
    do return end
  end
  local s=1
  local e=self.grid_width
  local adj=0
  for row=1,8 do
    for col=s,e do
      if gd[row][col]~=0 then
        self.g:led(col+adj,row,gd[row][col])
      end
    end
  end
  self.g:refresh()
end

return Grid_
