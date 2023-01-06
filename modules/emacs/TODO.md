# Installation of Emacs on Windows 11 with WSL2
# source: https://emacsredux.com/blog/2021/12/19/using-emacs-on-windows-11-with-wsl2/

```bash
$ git clone git://git.sv.gnu.org/emacs.git
$ sudo apt install build-essential libgtk-3-dev libgnutls28-dev libtiff5-dev libgif-dev libjpeg-dev libpng-dev libxpm-dev libncurses-dev texinfo  libglib2.0-dev -y
$ cd emacs
$ ./autogen.sh
$ ./configure --with-pgtk --with-mailutils
$ make -j8
$ sudo make install
```

```elisp
(defun copy-selected-text (start end)
  (interactive "r")
    (if (use-region-p)
        (let ((text (buffer-substring-no-properties start end)))
            (shell-command (concat "echo '" text "' | clip.exe")))))
```

