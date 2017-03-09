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
