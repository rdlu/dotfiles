function fish_user_key_bindings
  # ...
  bind \e\e 'fuck'  # Bind EscEsc to thefuck
  # or
  bind \cf 'fuck'  # Bind Ctrl+F to thefuck
  # ...
end

if type -q thefuck
  thefuck --alias | source
end