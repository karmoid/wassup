def state_to_color(state)
  case state
    when "Open" then ""
    when "Closed Successful" then "lightgreen"
    when "Closed Backed Out" then "red"
    when "Closed Rejected" then "red"
    when "Closed Cancelled" then "red"
    when "Implementation" then "pink"
    when "Classification" then "pink"
    when "Assessment & Planning" then "pink"
    when "SM Review" then "white"
    when "Technical Review" then "white"
    else "gray"
  end
end
