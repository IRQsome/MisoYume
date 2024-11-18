
# Direct Color table
File.binwrite("DCOLOR.DAT",Array.new(256) do 
    ((_1&0xC0) << 8) + ((_1&0x38)<<18) + ((_1&0x07)<<29)
end.pack('L<*'))


# Mosaic tables
def gen_mosaic_table(size)
    tab = Array.new
    64.times do |i|
        val = 0
        4.times do |j|
            x = ((i*4+j)/size)*size
            if x < i*4
                val |= 0x8000_0000
            else
                val |= (x-i*4) << ((j^3)*2)
            end
        end
        tab << val
        #puts "mosaic%2dx %2d: %08X" % [size,i,val]
    end
    return tab
end

MOSAIC_TABLES = Array.new(16){gen_mosaic_table(_1+1).pack('L<*')}
# Mosaic table entries only need their top and bottom bytes, so they can be interleaved:
# aL xx AL aH bL AH BL bH cL BH CL
MOSAIC_INTERLEAVE = String.new
(16*64*2+2).times do |i|

    even_i = (i/4)&63
    odd_i = ((i-2)/4)&63
    even_tab = (i/256)*2
    odd_tab = ((i-2)/256)*2 + 1

    #puts "%3d %d %2d %2d %2d %2d" % [i,i&3,even_i,odd_i,even_tab,odd_tab]

    case i&3
    when 0
        #puts "%3d %d %2d low  %2d" % [i,i&3,even_i,even_tab]
        MOSAIC_INTERLEAVE << (even_tab >= 16 ? 0xC0 : MOSAIC_TABLES[even_tab][even_i*4+0])
    when 1
        #puts "%3d %d %2d high %2d" % [i,i&3,odd_i,odd_tab]
        MOSAIC_INTERLEAVE << (odd_tab < 0 ? 0xC1 : MOSAIC_TABLES[odd_tab][odd_i*4+3])
    when 2
        #puts "%3d %d %2d low  %2d" % [i,i&3,odd_i,odd_tab]
        MOSAIC_INTERLEAVE << (odd_tab < 0 ? 0xC2 : MOSAIC_TABLES[odd_tab][odd_i*4+0])
    when 3
        #puts "%3d %d %2d high %2d" % [i,i&3,even_i,even_tab]
        MOSAIC_INTERLEAVE << (even_tab >= 16 ? 0xC3 : MOSAIC_TABLES[even_tab][even_i*4+3])
    end

end

File.binwrite("MOSAIC.DAT",MOSAIC_INTERLEAVE)

def gen_winlog_table
    nibbles = Array.new
    64.times do |i|
        winlog = i&3
        inv1 = i[2] != 0
        en1 = i[3] != 0
        inv2 = i[4] != 0
        en2 = i[5] != 0
        if en1 && en2
            nib = [0b1110,0b1000,0b0110,0b1001][winlog] # OR/AND/XOR/XNOR
        elsif en1
            nib = 0b1010
        elsif en2
            nib = 0b1100
        else
            nib = 0
        end
        if inv1
            nib = ((nib&0b1010) >> 1) | ((nib&0b0101) << 1)
        end
        if inv2
            nib = ((nib&0b1100) >> 2) | ((nib&0b0011) << 2)
        end
        nib ^= 0b1111 # invert all logic such that 1=layer visible
        nibbles << nib
    end
    str = "ppc_winlog_table long ".dup
    64.times do |i|
        if (i&7) == 0
            str << ', ' unless i==0
            str << ?$
        end
        str << nibbles[i^7].to_s(16)
    end
    puts str
    return nibbles
end

gen_winlog_table()