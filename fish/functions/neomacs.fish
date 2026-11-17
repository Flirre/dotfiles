function neomacs --description 'Run Neomacs with its own Doom local dir and server name'
    # GNU Emacs and Neomacs use the same default server socket.
    DOOMLOCALDIR=$neomacs_doomlocaldir EMACS_SERVER_NAME=neomacs command neomacs $argv
end
