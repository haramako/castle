#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

# NOTE: MacOS X では、GDのセットアップに失敗したので注意。また、bmpへの対応はソースのちょっと変更が必要
#
#

require 'fc/compiler'
require 'json'
require 'pathname'
require 'tempfile'
require 'fileutils'

module NesTool

  class Tile
    attr_reader :pixels
    attr_reader :palette

    def initialize( _pixels, _palette = nil )
      @palette = _palette
      @pixels = _pixels
      raise if @pixels.size != 8
      @pixels.each{|line| raise if line.size != 8 }
    end

    def bin
      r = []
      8.times do |py|
        lo = 0
        hi = 0
        8.times do |px|
          lo |= ((@pixels[py][px] >> 0)& 1) << (7-px)
          hi |= ((@pixels[py][px] >> 1)& 1) << (7-px)
        end
        r[py+0] = lo
        r[py+8] = hi
      end
      r.pack('c*')
    end

    def to_text_graphic
      @pixels.map{|x| x.join('')}.join("\n")
    end

    def self.from_img( img, x, y)
      pal_stat = Hash.new{0}
      pixels = Array.new(8){Array.new(8){0}}
      8.times do |py|
        8.times do |px|
          c = img[x+px, y+py].index
          pixels[py][px] = c % 4
          pal_stat[c/4] += 1 if c % 4 != 0
        end
      end

      # 一番使ってるパレットを取得
      if pal_stat.empty?
        pal = 0
      else
        pal = pal_stat.to_a.sort{|a,b| b[1]<=>a[1] }[0][0]
      end

      Tile.new( pixels, pal )
    end

    def self.from_img_monochrome( img, x, y )
      pixels = Array.new(8){Array.new(8){0}}
      8.times do |py|
        8.times do |px|
          c = img[x+px, y+py]
          pixels[py][px] = 3-(3.0*(c.r + c.g + c.b)/3/256).round
        end
      end
      Tile.new( pixels, 0 )
    end

  end

  class TileSet

    attr_reader :tiles

    def initialize
      @tiles = []
    end

    def size
      @tiles.size
    end

    def add_from_img( img, opt = Hash.new)
      width = opt[:width] || img.width
      height = opt[:height] || img.height
      (height/8).times do |cy|
        (width/8).times do |cx|
          case opt[:pal]
          when :monochrome
            @tiles << Tile.from_img_monochrome( img, cx*8, cy*8 )
          else
            @tiles << Tile.from_img( img, cx*8, cy*8 )
          end
        end
      end
    end

    def reflow!
      r = []
      (tiles.size/4).times do |i|
        n = (i/8)*32 + (i%8)*2
        r << @tiles[n+0]
        r << @tiles[n+16]
        r << @tiles[n+1]
        r << @tiles[n+17]
      end
      @tiles = r
      self
    end

    def bin
      @tiles.map{|t| t.bin }.join('')
    end

    def save( filename )
      IO.write(filename, self.bin)
    end

  end

  class Nsd

    NSC = 'nsc'
    CA65 = 'ca65'
    LD65 = 'ld65'

    LD65_CONFIG = <<EOT
MEMORY { ROM: start = $0000, size = $8000, file = %O; }
SEGMENTS { RODATA: load = ROM, type = ro, define = yes; }
EOT

    def initiaize
    end
    
    def sh( *args )
      require 'open3'
      command = args.map(&:to_s)
      puts command.join(" ")
      Open3.popen2e( *command ) do |i, oe, th|
        v = th.value
        if v != 0
          raise "`#{command}` returns #{v}"
          puts oe.read
        end
        oe.read
      end
    end

    def convert( filename )
      path = Pathname.new(filename)
      asm_path = path.sub_ext('.s')
      obj_path = path.sub_ext('.o')
      bin_path = path.sub_ext('.bin')

      cfg = Tempfile.new('nsc.cfg')
      cfg.write LD65_CONFIG
      cfg.close

      sh NSC, '-a', path

      sh CA65, asm_path
      asm = IO.read(asm_path)
      asm.gsub!( /.segment	"RODATA"\n/ ){ |m| m+"\t.word _nsd_BGM0\n" }
      IO.write asm_path, asm

      sh LD65, '-o', path.sub_ext('.bin'), '-C', cfg.path, obj_path

      FileUtils.rm_f [path.sub_ext('.o'), asm_path]
    end

  end
end

