# ticker_items = [
#   "Ici nous pouvons faire apparaître des messages importants pour les équipes",
# 	"Par exemple le nombre d'incident VIP, le nombre de SEV 1, ou la date du prochain pôt"
# ]
# ticker_items = []
# shown = false
# SCHEDULER.every 17, :first_in => 0 do
#   if shown
# 	  send_event( 'ticker', { :items => [] } )
#   else
#     send_event( 'ticker', { :items => ticker_items } )
#   end
#   shown = !shown
#   puts "iteration : shown = #{shown.inspect}"
# end
