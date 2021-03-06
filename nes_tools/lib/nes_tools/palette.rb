module NesTools
  
  class Palette
    
    DEFAULT_PALLET_COLOR = [[98, 98, 98], [0, 24, 144], [31, 0, 155], [61, 0, 139], [99, 0, 105], [115, 0, 23], [104, 12, 0], [77, 42, 0], [53, 75, 1], [0, 98, 0], [0, 102, 0], [1, 89, 58], [0, 73, 124], [0, 0, 0], [0, 0, 0], [0, 0, 0], [187, 187, 187], [32, 86, 229], [84, 52, 253], [129, 34, 234], [170, 35, 195], [179, 38, 94], [169, 67, 0], [140, 95, 0], [108, 124, 0], [33, 145, 0], [0, 151, 0], [0, 141, 85], [0, 127, 168], [5, 5, 5], [0, 0, 0], [0, 0, 0], [255, 255, 255], [108, 166, 255], [151, 136, 255], [188, 119, 255], [228, 116, 255], [244, 107, 178], [239, 134, 84], [216, 161, 32], [181, 186, 6], [117, 205, 9], [79, 212, 63], [64, 205, 135], [74, 196, 214], [83, 83, 83], [0, 0, 0], [0, 0, 0], [255, 255, 255], [178, 213, 255], [186, 184, 255], [209, 186, 255], [236, 188, 255], [255, 191, 229], [255, 202, 184], [240, 213, 163], [230, 228, 149], [203, 243, 133], [171, 243, 155], [158, 232, 189], [158, 230, 220], [168, 171, 169], [0, 0, 0], [0, 0, 0]]
    
    class << self
      def nespal(img)
        pal = []
        img.palette.each do |c|
          pal[c.index] = c if c.index
        end

        base_pal = DEFAULT_PALLET_COLOR
        pal.map do |p|
          next 13 unless p
          min_idx = -1
          min = 999
          base_pal.each.with_index do |bp,i|
            d = (p.r - bp[0]).abs + (p.g - bp[1]).abs + (p.b - bp[2]).abs
            if d < min
              min = d
              min_idx = i
              break if d == 0
            end
          end
          min_idx
        end
      end
    end
  end
    
end
