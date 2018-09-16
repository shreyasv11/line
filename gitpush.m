function gitpush(msg)
system(['git add *; git commit -am "',msg,'"; git push;'])
end