function fish_user_key_bindings
  # ...
  bind \e\e 'thefuck'  # Bind EscEsc to thefuck
  # or
  bind \cf 'thefuck'  # Bind Ctrl+F to thefuck
  # ...
end

if type -q thefuck
  thefuck --alias | source
end