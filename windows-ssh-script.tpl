add-content -path c:/Users/USER/.ssh/config -value @'

Host ${hostname}
  Hostname ${hostname}
  User ${user}
  IdentityFile ${identityfile}
'@
