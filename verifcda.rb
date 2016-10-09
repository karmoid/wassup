# ruby verifcda.rb "(\[[\]]|.*\])(?:\[.*\])?\s?(.*)$"

[
"[CDA FR110-11648 / UMANIS] Commande 1x JABRA SPORT PULSEWIRELESS",
"[CDA FRxxx-xxxxx / ECONOCOM] 1x iPad Air2",
"[CDA FR110-11637 / UMANIS] Commande 5 barrettes m\u00E9moire 8Go pour HP ELITEDESK 705 mini",
"[CDA FR110-11634 / UMANIS] Commande 1 Clavier AZERTY pour Elitebook 745",
"[CDA FR110-11616 / UMANIS] Commande 1 KVM HDMI",
"[CDA FR020-35782 / UMANIS] Commande 10 cartes graphiques double \u00E9cran pour desktop",
"[CDA FR110-11600 / RECYCLEA][ATT retour DESTRUCTION / MAJ GDP] Enl\u00E8vement et destruction des mat\u00E9riels du stock obsol\u00E8te",
"[CDA FR110-11591 / UMANIS] Onduleur HS (batteries \u00E0 remplacer)"
].each do |commande|
  # cmdfields = /\[CDA\s(FR\d*-\d*)\s?\/\s?(.*)\](?:\[|\s)(.*)$/.match(commande)
    cmdfields = /#{ARGV[0]}/.match(commande)
    if cmdfields.nil?
      puts ">>>>>> " + commande.inspect
    else
      puts cmdfields.to_a.join("\n")+"\n--------\n\n"
    end
end
puts "with #{ARGV[0]}"
