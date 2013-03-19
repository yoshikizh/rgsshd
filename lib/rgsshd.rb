require "rgsshd/version"

#==============================================================================
# ■ RGSSHD_Package
#------------------------------------------------------------------------------
# 　数据包生成的模块。
#==============================================================================
module Set_File
  OFFSET = 0x0c
  def self.load
    $rgss = File.open("Game.rgsshide","rb")
    tp = $rgss.read(16)
    if tp[0,8] != "RGSSHIDE"
      raise "不是RGSSHIDE文件!"
    end  
    if tp[8,8] != "20080808"
      raise "不支持的版本!"
    end  
    @head = []
    @audioH = []
    @graphicsH = []
    @dataH = []
    6.times{@head.push $rgss.read(4).unpack("L")[0]}
    $rgss.pos = @head[0]
    3.times{@audioH.push $rgss.read(4).unpack("L")[0]}
    $rgss.pos = @head[2]
    3.times{@graphicsH.push $rgss.read(4).unpack("L")[0]}
    $rgss.pos = @head[4]
    3.times{@dataH.push $rgss.read(4).unpack("L")[0]}
    
    $rgss.pos = @head[0] + OFFSET
    @audioInf = eval(Zlib::Inflate.inflate($rgss.read(@head[1]- OFFSET)))
    $rgss.pos = @head[2] + OFFSET
    @graphicsInf = eval(Zlib::Inflate.inflate($rgss.read(@head[3]- OFFSET)))
    $rgss.pos = @head[4] + OFFSET
    @dataInf = eval(Zlib::Inflate.inflate($rgss.read(@head[5]- OFFSET)))
  end
  
 #--------------------------------------------------------------------------
 # ● 解码代码
 #--------------------------------------------------------------------------
 def self.inflate(filename,kind)
   # Set_File.load if $rgss.closed?
   case kind
   when 0
     inf = @audioInf[filename]
     offset = @audioH[0]
   when 1
     inf = @graphicsInf[filename]
     offset = @graphicsH[0]
   when 2
     inf = @dataInf[filename]
     offset = @dataH[0]
   end
   $rgss.pos = inf[0] + offset
   code = $rgss.read(inf[1])
   if kind != 2
     code = Zlib::Inflate.inflate(code)
   end
   return code
 end

end  


module RGSSHD_Package
  
  Audios      = ["wav","mp3","ogg","wma","mid"]  
  Graphicses  = ["bmp","jpg","png"]
  Databases   = ["rxdata"]

  # 文件头地址
  LpAudioHead        = 0x10    #||
  LpAudioLength      = 0x14    #||
  LpGraphicsHead     = 0x18    #||TOTAL(16byte)
  LpGraphicsLength   = 0x1C    #||
  LpDataHead         = 0x20    #||
  LpDataLength       = 0x24    #||
  
  module_function
 #--------------------------------------------------------------------------
 # ● 开始制作数据包
 #--------------------------------------------------------------------------
 def start
   @count = 0
   @block = 0
   @sprite = Sprite.new
   @sprite_base = Sprite.new
   @sprite_base2 = Sprite.new
   @bitmap = Bitmap.new(14,16)
   @bitmap.fill_rect(Rect.new(0,0,16,16),color = Color.new(0,255,0,255))
   bitmap2 = Bitmap.new(322,18)
   bitmap2.fill_rect(Rect.new(0,0,322,18),color = Color.new(128,128,128,255))
   bitmap3 = Bitmap.new(324,20)
   bitmap3.fill_rect(Rect.new(0,0,324,20),color = Color.new(255,0,0,255))

   auth = Sprite.new
   auth.bitmap = Bitmap.new(150,16)
   auth.bitmap.font.size = 14
   auth.bitmap.draw_text(0,0,150,16,"RGSSHD"+"  "+"作者：秀秀")
   auth.x,auth.y,auth.z = 250,300,103
   
   @sprite_base.bitmap = bitmap2
   @sprite_base.x = (640-322)/2
   @sprite_base.y = 300
   @sprite_base.z = 102
   
   @sprite_base2.bitmap = bitmap3
   @sprite_base2.x = (640-322)/2 - 1
   @sprite_base2.y = 300 - 1
   @sprite_base2.z = 101
   
   @old_dir = Dir.pwd
   @audio_files = []
   @graphics_files = []
   @database_files = []
   @path = ""
   self.next_file(@path,0)
   self.next_file(@path,1)
   self.next_file(@path,2)
   if  (@audio_files + @graphics_files + @database_files).size == 0
     "没有搜索到资源"
     return
   end  
   
   @all_files = (@audio_files + @graphics_files + @database_files).size
   @rate = (@all_files / 20).to_f
   
   
   Dir.chdir(@old_dir)
   self.create_file
   self.write_file_header
   self.write_audio_header
   self.write_audio_block
   self.write_graphics_header
   self.write_graphics_block
   self.write_database_header
   self.write_database_block
   self.write_file_end
    p "Game.RGSSHD 制作成功"
   exit
 end

 def create_file
   @file = File.open("Game.rgsshide","wb")
 end   
 
 def write_file_header 
   @file.write "RGSSHIDE"
   @file.write "20080808"
 end
 
 def write_audio_header
   @file.pos = 0x28
   if @audio_files.size == 0
     @@audio_head_adress = 0x28
     @@audio_head_length = 12
     @audio_files_block_adress = 0
     @audio_files_block_length = 0
     @audio_files_amount = 0
     return
   end  
   Dir.chdir(@old_dir)
   posop = 0
   fsize = 0
   @tempa = ""
   audio_list = "resource_list = {\n"
   begin
     for name in @audio_files
       begin
         fr = File.open(name,"rb") # 打开目标Audio文件
         code = Zlib::Deflate.deflate(fr.read,9)
         fsize = code.size
         @tempa += code
         audio_list += sprintf("%s=>[%d,%d],\n","\"#{name.split(/\./)[0]}\"",
                               posop,fsize)
         posop += fsize  # 记录位置
       rescue
         print "\"#{name}\" can't open"
       ensure
         fr.close
         @count += 1
         if @count >= @rate
           @sprite_base.bitmap.blt(@block*16,0,@bitmap,Rect.new(0,0,14,16))
           @block += 1  
           @count = 0
         end
         Graphics.update
       end
     end
   ensure
     audio_list.slice!(audio_list.size-2,1)
     audio_list += "}\n"
     audio_list = Zlib::Deflate.deflate(audio_list,9)
     
     @audio_head_adress = 0x28
     @audio_head_length = audio_list.size + 12
     @audio_files_block_adress = 0x28 + @audio_head_length
     @audio_files_block_length = @tempa.length
     @audio_files_amount = @audio_files.length
     
     @file.pos = LpAudioHead
     @file.write [@audio_head_adress].pack("L")
     @file.pos = LpAudioLength
     @file.write [@audio_head_length].pack("L")
     
     @file.pos = 0x28
     @file.write [@audio_files_block_adress].pack("L")
     @file.pos = 0x28+4
     @file.write [@audio_files_block_length].pack("L")
     @file.pos = 0x28+8
     @file.write [@audio_files_amount].pack("L")
     @file.pos = 0x28+12
     @file.write audio_list
while false
     p @audio_head_adress
     p @audio_head_length
     p "文件块地址" + @audio_files_block_adress.to_s
     p "文件块长度" + @audio_files_block_length.to_s
     p "文件数量" + @audio_files_amount.to_s
end     
   end
   

 end

 def write_audio_block
   @file.write @tempa
 end  
   
 def write_graphics_header
   @gr_start_adr = @audio_files_block_adress+@audio_files_block_length
   @file.pos = @gr_start_adr

   if @graphics_files.size == 0
     @graphics_head_adress = @gr_start_adr
     @graphics_head_length = 12 # 不包含hash信息块
     @graphics_files_block_adress = 0
     @graphics_files_block_length = 0
     @graphics_files_amount = 0
     return
   end  
   
   Dir.chdir(@old_dir)
   posop = 0
   fsize = 0
   @tempg = ""
   graphics_list = "resource_list = {\n"
   begin
     for name in @graphics_files
       begin
         fr = File.open(name,"rb") # 打开目标Audio文件
         code = Zlib::Deflate.deflate(fr.read,9)
         fsize = code.size
         #压缩后写入到指定位置
         @tempg += code
         graphics_list += sprintf("%s=>[%d,%d],\n","\"#{name.split(/\./)[0]}\"",
                               posop,fsize)
         posop += fsize    # 记录现在位置
       rescue
         print "\"#{name}\" can't open"
       ensure
         fr.close
         @count += 1
         if @count >= @rate
           @sprite_base.bitmap.blt(@block*16,0,@bitmap,Rect.new(0,0,14,16))
           @block += 1  
           @count = 0
         end
         Graphics.update
       end
     end
   ensure
     graphics_list.slice!(graphics_list.size-2,1)
     graphics_list += "}\n"
     graphics_list = Zlib::Deflate.deflate(graphics_list,9)
     
     @graphics_head_adress = @gr_start_adr
     @graphics_head_length = graphics_list.size + 12
     @graphics_files_block_adress =  @graphics_head_adress + @graphics_head_length
     @graphics_files_block_length = @tempg.length
     @graphics_files_amount = @graphics_files.length
     
     @file.pos = LpGraphicsHead
     @file.write [@graphics_head_adress].pack("L")
     @file.pos = LpGraphicsLength
     @file.write [@graphics_head_length].pack("L")
     
     @file.pos = @graphics_head_adress
     @file.write [@graphics_files_block_adress].pack("L")
     @file.pos = @graphics_head_adress+4
     @file.write [@graphics_files_block_length].pack("L")
     @file.pos = @graphics_head_adress+8
     @file.write [@graphics_files_amount].pack("L")
     @file.pos = @graphics_head_adress+12
     @file.write graphics_list
   end
 end
 
 def write_graphics_block
    @file.write @tempg
 end
 
 def write_database_header
   @da_start_adr = @graphics_files_block_adress + @graphics_files_block_length
   @file.pos = @da_start_adr

   if @database_files.size == 0
     @data_head_adress = @gr_start_adr
     @data_head_length = 12 # 不包含hash信息块
     @data_files_block_adress = 0
     @data_files_block_length = 0
     @data_files_amount = 0
     return
   end  
   p @database_files
   Dir.chdir(@old_dir)
   posop = 0
   fsize = 0
   @tempd = ""
   data_list = "resource_list = {\n"
   begin
     for name in @database_files
       begin
         fr = File.open(name,"rb") # 打开目标Audio文件
         code = fr.read     # 导出内容
         fsize = code.size
         #压缩后写入到指定位置
         @tempd += code
         data_list += sprintf("%s=>[%d,%d],\n","\"#{name.split(/\./)[0]}\"",
                               posop,fsize)
         posop += fsize            # 记录现在位置
       rescue
         print "\"#{name}\" can't open"
       ensure
         fr.close
         @count += 1
         if @count >= @rate
           @sprite_base.bitmap.blt(@block*16,0,@bitmap,Rect.new(0,0,14,16))
           @block += 1  
           @count = 0
         end
         Graphics.update
       end
     end
   ensure
     data_list.slice!(data_list.size-2,1)
     data_list += "}\n"
     data_list = Zlib::Deflate.deflate(data_list,9)
     
     @data_head_adress = @da_start_adr
     @data_head_length = data_list.size + 12
     @data_files_block_adress =  @data_head_adress + @data_head_length
     @data_files_block_length = @tempd.length
     @data_files_amount = @database_files.length
     
     @file.pos = LpDataHead
     @file.write [@data_head_adress].pack("L")
     @file.pos = LpDataLength
     @file.write [@data_head_length].pack("L")
     
     @file.pos = @data_head_adress
     @file.write [@data_files_block_adress].pack("L")
     @file.pos = @data_head_adress+4
     @file.write [@data_files_block_length].pack("L")
     @file.pos = @data_head_adress+8
     @file.write [@data_files_amount].pack("L")
     @file.pos = @data_head_adress+12
     @file.write data_list
   end
   
 end
 
 def write_database_block
   @file.write @tempd
 end
 
 def write_file_end
  @file.write "RGSSHIDE-END"
  @file.close
 end
 
 #--------------------------------------------------------------------------
 # ● 搜索全部资源文件
 #--------------------------------------------------------------------------
 def next_file(path,kind)
   Dir.chdir(@old_dir)
   Dir.chdir(path) if path != ""
   case kind
   when 0
     for f in Dir["*"]
       if FileTest.directory?(f)
         @path = @path + f + "/"
         self.next_file(@path,0)
       else
         if Audios.include? f.split(/\./)[1]
           @audio_files.push @path + f
         end
       end
     end
   when 1
     for f in Dir["*"]
       if FileTest.directory?(f)
         @path = @path + f + "/"
         self.next_file(@path,1)
       else
         if Graphicses.include? f.split(/\./)[1]
           @graphics_files.push @path + f
         end
       end
     end
   when 2
     for f in Dir["*"]
       if FileTest.directory?(f)
         @path = @path + f + "/"
         self.next_file(@path,2)
       else
         if Databases.include? f.split(/\./)[1]
           @database_files.push @path + f
         end
       end
     end
   end  

   path_a = path.split(/\//)
   @path = ""
   for i in 0...path_a.size - 1
     @path += path_a[i] + "/"
   end
   Dir.chdir(@old_dir)
   Dir.chdir(@path) if @path != ""
   
 end
end
