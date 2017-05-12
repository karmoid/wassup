def humanize secs
  secs, n = secs.divmod(3600)
  outst = [[24, :heure], [1000, :jour]].map{ |count, name|
    if secs > 0
      secs, n = secs.divmod(count)
      n.to_i > 0 ? "#{n.to_i} #{name}#{n.to_i > 1 ? "s" : ""}" : ""
    end
  }.compact.reverse.join(' ')
  outst.empty? ? "récent" : outst
end

def humanizeJH secs
  secs, n = secs.divmod(3600)
  outst = [[24, :h], [1000, :j]].map{ |count, name|
    if secs > 0
      secs, n = secs.divmod(count)
      n.to_i > 0 ? "#{n.to_i} #{name}#{n.to_i > 1 ? "s" : ""}" : ""
    end
  }.compact.reverse.join(' ')
  outst.empty? ? "récent" : outst
end

def humanize_with_lib secs, prefix, none
  secs, n = secs.divmod(3600)
  outst = [[24, :heure], [1000, :jour]].map{ |count, name|
    if secs > 0
      secs, n = secs.divmod(count)
      n.to_i > 0 ? "#{n.to_i} #{name}#{n.to_i > 1 ? "s" : ""}" : ""
    end
  }.compact.reverse.join(' ')
  outst.empty? ? none : prefix + " " + outst
end

class Integer
   def to_humanB
     conv={
       1024=>'B',
       1024*1024=>'KB',
       1024*1024*1024=>'MB',
       1024*1024*1024*1024=>'GB',
       1024*1024*1024*1024*1024=>'TB',
       1024*1024*1024*1024*1024*1024=>'PB',
       1024*1024*1024*1024*1024*1024*1024=>'EB'
     }
     conv.keys.sort.each { |mult|
        next if self >= mult
        suffix=conv[mult]
        return "%.2f %s" % [ self.to_f / (mult / 1024), suffix ]
     }
   end
 end
