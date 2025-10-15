function rm --wraps='echo "This is not the command you are looking for."; false' --description 'alias rm=echo "This is not the command you are looking for."; false'
  echo "This is not the command you are looking for."; false $argv
        
end
