local GGrid={}

function GGrid:new(args)
  local m=setmetatable({},{__index=GGrid})
  local args=args==nil and {} or args

  m.apm=args.apm or {}
  m.grid_on=args.grid_on==nil and true or args.grid_on

  -- initiate the grid
  local midigrid=util.file_exists(_path.code.."midigrid")
  local grid=midigrid and include "midigrid/lib/mg_128" or grid
  m.g=grid.connect()
  m.g.key=function(x,y,z)
    if m.grid_on then
      m:grid_key(x,y,z)
    end
  end
  print("grid columns: "..m.g.cols)

  -- setup visual
  m.visual={}
  m.grid_width=16
  for i=1,8 do
    m.visual[i]={}
    for j=1,16 do
      m.visual[i][j]=0
    end
  end

  -- keep track of pressed buttons
  m.pressed_buttons={}

  -- grid refreshing
  m.grid_refresh=metro.init()
  m.grid_refresh.time=midigrid and 0.12 or 0.07
  m.grid_refresh.event=function()
    if m.grid_on then
      m:grid_redraw()
    end
  end
  m.grid_refresh:start()

  m.light_setting={}
  m.patterns={}
  for i=3,16 do
    table.insert(m.patterns,patterner:new())
  end

  m:init()
  return m
end

function GGrid:init()
  self.blink=0
  self.blink2=0
  self.fader={0,0.04,3}
  self.page=3
  self.pressed_ids={}
  self.key_press_fn={}
  -- page 1 recording
  table.insert(self.key_press_fn,function(row,col,on,id,hold_time)
    params:set("record_beats",id/4)
  end)
  -- page 2 sample start/end
  table.insert(self.key_press_fn,function(row,col,on,id,hold_time,datti)
    if not on then
      do return end
    end
    local from_pattern=datti~=nil
    if datti==nil then
      datti=dat.ti
    end
    -- check to see if two notes are held down and set the start/end based on them
    if row<5 then
      -- set sample start position
      params:set(datti.."sampleStart",util.round(util.linlin(1,64,0,1,id),1/64))
      params:set(datti.."sampleEnd",params:get(datti.."sampleStart")+params:get(datti.."sampleDuration"))
    elseif row>5 then
      -- set sample duration
      params:set(datti.."sampleDuration",util.linlin(1,32,1/64,1.0,id-80))
      params:set(datti.."sampleEnd",params:get(datti.."sampleStart")+params:get(datti.."sampleDuration"))
    end
    if not from_pattern then
      local ti=dat.ti
      dat.tt[dat.ti].sample_pattern:add(function() g_.key_press_fn[2](row,col,on,id,hold_time,ti) end)
    end
  end)
  -- page 3 and beyond: playing
  for i=3,16 do
    table.insert(self.key_press_fn,function(row,col,on,id,hold_time,from_pattern)
      if on and from_pattern==nil then
        switch_view(id)
      end
      if params:get(id.."oneshot")==2 then
        params:set(id.."play",on and 1 or 0)
      elseif hold_time>0.25 then
        if params:get(id.."play")==1 then
          params:set(id.."release",hold_time)
        else
          params:set(id.."attack",hold_time)
        end
        params:delta(id.."play",1)
      end
      if from_pattern==nil then
        self.patterns[i-2]:add(function() g_.key_press_fn[i](row,col,on,id,hold_time,true) end)
      end
    end)
  end
end

function GGrid:grid_key(x,y,z)
  self:key_press(y,x,z==1)
  self:grid_redraw()
end

function GGrid:key_press(row,col,on)
  local ct=clock.get_beats()*clock.get_beat_sec()
  local hold_time=0
  local id=(row-1)*16+col
  if on then
    self.pressed_buttons[row..","..col]=ct
    self.pressed_ids[id]=true
  else
    hold_time=ct-self.pressed_buttons[row..","..col]
    self.pressed_buttons[row..","..col]=nil
    self.pressed_ids[id]=nil
  end
  if row==8 then
    if on then
      local old_page=self.page
      self.page=(col<=#self.key_press_fn) and col or self.page
      self.page_switched=old_page~=self.page
    elseif col>1 then -- pattern start/stop
      if self.page_switched then
        do return end
      end
      if hold_time>0.5 then
        -- record a pattern
        if col>2 then
          print("ggrid: recording key pattern on",col-2)
          self.patterns[col-2]:record()
        else
          print("ggrid: recording edge pattern on",dat.ti)
          dat.tt[dat.ti].sample_pattern:record()
        end
      else
        -- toggle a pattern
        if col>2 then
          print("ggrid: toggling key pattern on",col-2)
          self.patterns[col-2]:toggle()
        else
          print("ggrid: toggling edge pattern on",dat.ti)
          dat.tt[dat.ti].sample_pattern:toggle()
        end
      end
    end
  else
    self.key_press_fn[self.page](row,col,on,id,hold_time)
  end
end

function GGrid:light_up(id,val)
  self.light_setting[id]=val
end

function GGrid:get_visual()
  if dat==nil or dat.ti==nil then
    do return end
  end
  -- clear visual
  local id=0
  local sampleSD={}
  if self.page==2 then
    sampleSD[1]=util.round(util.linlin(0,1,1,64,params:get(dat.ti.."sampleStart")))
    sampleSD[2]=util.round(util.linlin(1/64,1,1,32,params:get(dat.ti.."sampleDuration")))
    sampleSD[3]=util.round(util.linlin(0,1,1,64,params:get(dat.ti.."sampleEnd")))
  end

  for row=1,7 do
    for col=1,self.grid_width do
      id=id+1
      if self.page==2 then
        if id==sampleSD[1] then
          self.visual[row][col]=5
        elseif id>0 and id<=64 and id<=sampleSD[3] and id>sampleSD[1] then
          self.visual[row][col]=3
        elseif id>80 and id-80<=sampleSD[2] then
          self.visual[row][col]=5
        elseif id>0 and id<=64 then
          self.visual[row][col]=2
        elseif id>80 and id<=112 then
          self.visual[row][col]=2
        else
          self.visual[row][col]=0
        end
      elseif self.page==1 then
        -- recording
        if id<=params:get("record_beats")*4 then
          self.visual[row][col]=dat.tt[dat.ti].recording and 10 or 3
        else
          self.visual[row][col]=0
        end
      else
        self.visual[row][col]=self.light_setting[id] or 0
        if self.light_setting[id]~=nil and self.light_setting[id]>0 then
          self.light_setting[id]=self.light_setting[id]-1
        end
        if dat.tt~=nil and dat.tt[id]~=nil and dat.tt[id].ready and self.visual[row][col]==0 then
          self.visual[row][col]=2
        end
      end
      -- always blink
      if id==dat.ti then
        self.blink=self.blink-1
        if self.blink<-1 then
          self.blink=6
        end
        if self.blink>0 then
          self.visual[row][col]=5-self.visual[row][col]
          self.visual[row][col]=(self.visual[row][col]<0 and 0 or self.visual[row][col])
        end
      end
    end
  end

  -- highlight available pages / current page
  for i,_ in ipairs(self.key_press_fn) do
    self.visual[8][i]=self.page==i and 4 or 1
  end
  for i,v in ipairs(self.patterns) do
    self.fader[1]=self.fader[1]+self.fader[2]
    if self.fader[1]>self.fader[3] or self.fader[1]<-1 then
      self.fader[2]=-1*self.fader[2]
    end
    self.visual[8][i+2]=self.visual[8][i+2]+(v.playing and util.round(self.fader[1]) or 0)
    if v.recording or v.primed then
      self.blink2=self.blink2-1
      if self.blink2<-1 then
        self.blink2=1
      end
      self.visual[8][i+2]=self.blink2>0 and self.visual[8][i+2] or 0
    end
  end

  return self.visual
end

function GGrid:grid_redraw()
  self.g:all(0)
  local gd=self:get_visual()
  local s=1
  local e=self.grid_width
  local adj=0
  for row=1,8 do
    for col=s,e do
      if gd~=nil and gd[row]~=nil and gd[row][col]~=0 then
        self.g:led(col+adj,row,gd[row][col])
      end
    end
  end
  self.g:refresh()
end

function GGrid:redraw()

end

return GGrid