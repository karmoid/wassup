def state_to_color(state,close_success)
  puts "#{state} & #{close_success.inspect}"
  case state
    when "Open" then ""
    when "Closed Successful" then "lightgreen"
    when "Closed Backed Out" then "red"
    when "Closed Rejected" then "red"
    when "Closed Cancelled" then "red"
    when "Implementation" then
      if close_success==""
        "pink"
      else
        close_success.downcase=="yes" ? "lightgreen" : "red"
      end
    when "Classification" then "pink"
    when "Assessment & Planning" then "pink"
    when "SM Review" then "white"
    when "Technical Review" then "white"
    else "gray"
  end
end
