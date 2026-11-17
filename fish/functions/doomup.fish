function doomup --description 'Update Doom core + packages (doom upgrade --aot), then the Neomacs packages'
    # `doom upgrade` = git pull Doom core, then `doom sync -u` internally —
    # which rebuilds exactly the packages that changed. --aot native-compiles
    # the updated packages ahead-of-time so the next Emacs start isn't stuck
    # JIT-compiling them. Extra args pass through: `doomup -p` (packages only),
    # `doomup --force`, `doomup -j 8`.
    #
    # The old version (`doom sync && doom upgrade && doom sync --rebuild --aot`)
    # wasted ~4-5 min/run: the leading sync is subsumed by upgrade's internal
    # `sync -u`, and `--rebuild` unconditionally rebuilt all ~180 packages.
    ~/.config/emacs/bin/doom upgrade --aot $argv; or return

    # Neomacs has no native compilation, and `doomup -p` is not a sync flag.
    env EMACS=neomacs DOOMLOCALDIR=$neomacs_doomlocaldir ~/.config/emacs/bin/doom sync -u
end
