def humanize secs
  secs, n = secs.divmod(3600)
  [[24, :heures], [1000, :jours]].map{ |count, name|
    if secs > 0
      secs, n = secs.divmod(count)
      "#{n.to_i} #{name}"
    end
  }.compact.reverse.join(' ')
end