function emacs-refresh --description 'Re-copy the emacs-plus apps to /Applications, then rebuild Doom'
    # /opt/homebrew/bin/emacs is a wrapper that prefers /Applications/Emacs.app over
    # the Cellar copy. Both /Applications bundles are plain copies with the versioned
    # Cellar path baked in: Emacs.app in its binary, Emacs Client.app in its
    # AppleScript. A brew upgrade of emacs-plus deletes that Cellar directory, so
    # Emacs aborts with "charsets: No such file or directory" and Emacs Client.app
    # fails without a message. The formula recommends a copy over a symlink, for
    # Spotlight, so run this after every emacs-plus upgrade or macOS update.
    set -l prefix (brew --prefix emacs-plus@31); or return 1

    # A GUI Emacs or a daemon runs from the bundle, so a replacement breaks the live
    # process. Ignore a --batch Emacs, because that is only a doom command.
    set -l live (pgrep -fl '/Applications/Emacs\.app/Contents/MacOS/Emacs' | grep -v -- --batch)
    if test -n "$live"
        echo "emacs-refresh: quit Emacs first, it runs from the bundle:" >&2
        printf '  %s\n' $live >&2
        return 1
    end

    for app in Emacs.app "Emacs Client.app"
        if not test -d "$prefix/$app"
            echo "emacs-refresh: $prefix/$app is missing" >&2
            return 1
        end
        # ditto merges into an existing bundle, so delete the old one first.
        rm -rf "/Applications/$app"
        ditto "$prefix/$app" "/Applications/$app"; or return 1
        echo "emacs-refresh: copied $app"
    end

    emacs --batch --eval '(princ (concat emacs-version "\n"))'; or return 1

    # A new Emacs version invalidates every straight build and every eln cache.
    # --rebuild is what the version change needs anyway, and it stops `doom sync`
    # from asking "Installed packages must be rebuilt. Do so now?".
    ~/.config/emacs/bin/doom sync --rebuild --aot $argv; or return 1

    # Emacs loads these libraries before Doom moves the eln cache into .local, so
    # it looks for them in ~/.config/emacs/eln-cache. Compile them there.
    emacs --batch -Q --eval '(dolist (lib (list "subr-x" "gv" "cl-macs" "cl-lib" "cl-seq" "pcase" "easy-mmode" "inline"))
        (native-elisp-load (native-compile (locate-library (concat lib ".el") t))))'; or return 1

    # ESET's real-time scanner authorizes each mach-O map, so `dlopen' of an .eln
    # the scanner has not seen costs 270-400 ms. The cost is per file identity,
    # and a rebuild gives every .eln a new identity. Without this step the first
    # sessions after an upgrade pay it during `find-file', which can stall for
    # minutes. Load every .eln once here, so the cost lands in this command.
    echo "emacs-refresh: warming the eln cache..."
    emacs --batch --eval '(let ((dir "~/.config/emacs/.local/cache/eln") (n 0))
        (dolist (sub (directory-files dir t "^[^.]"))
          (when (file-directory-p sub)
            (dolist (f (directory-files sub t "[.]eln$"))
              (when (ignore-errors (native-elisp-load f) t) (setq n (1+ n))))))
        (princ (format "emacs-refresh: warmed %d eln files\n" n)))'
end
