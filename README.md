# Rgsshd

TODO: Write a gem description

## Installation

Add this line to your application's Gemfile:

    gem 'rgsshd'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rgsshd

## Usage

RGSSHD加密包

制作思路: 
1.音乐文件，图片文件 ZLIB 加密 数据库文件 直接打入加密包 

2.数据结构: 
          
          总文件头：开始地址:0x00
                    00-07(8byte)  描述数据包名称
                    08-0F(8byte)  描述版本号
                    10-13(4byte)  Audio文件头地址           
                    14-17(4byte)  Audio文件头长度
                    18-1B(4byte)  Graphics文件头地址
                    1C-1F(4byte)  Graphics文件头长度
                    20-23(4byte)  Date文件头地址
                    24-27(4byte)  Date文件头长度
                    
                   
          Audio文件头:
                      AUDIO文件块地址 (4byte) --|
                      AUDIO文件块长度 (4byte) --|--Total(12byte)
                      AUDIO文件数量   (4byte) --|
                      
                      "hash = { 路径\文件名1=>[文件1地址,文件1长度],
                                路径\文件名2=>[文件2地址,文件2长度], 
                                ..............
                                ...........
                                路径\文件名x=>[文件x地址,文件x长度], 
                      }"
                      
                     
          Audio文件块:文件1内容+文件2内容+文件3内容......

                      
                      
                      
          Graphics文件头:
                      Graphics文件块地址 (4byte) --|
                      Graphics文件块长度 (4byte) --|--Total(12byte)
                      Graphics文件数量   (4byte) --|
                      
                      "hash = { 路径\文件名1=>[文件1地址,文件1长度],
                                路径\文件名2=>[文件2地址,文件2长度], 
                                ..............
                                ...........
                                路径\文件名x=>[文件x地址,文件x长度], 
                      }"
                      

          Graphics文件块:文件1内容+文件2内容+文件3内容......
                      
          
          
          Data文件头:
                      Data文件块地址 (4byte) --|
                      Data文件块长度 (4byte) --|--Total(12byte)
                      Data文件数量   (4byte) --|
                      
                      "hash = { 路径\文件名1=>[文件1地址,文件1长度],
                                路径\文件名2=>[文件2地址,文件2长度], 
                                ..............
                                ...........
                                路径\文件名x=>[文件x地址,文件x长度], 
                      }"
                      

          Data文件块:文件1内容+文件2内容+文件3内容......        

          数据包结尾块信息:预留16个字节

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
