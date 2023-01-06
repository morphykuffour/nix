(custom-set-faces
 '(italic ((t (:slant italic)))))

(setq hrs/default-fixed-font "JetBrainsMono Nerd Font Mono")
(setq hrs/default-fixed-font-size 100)
(setq hrs/current-fixed-font-size hrs/default-fixed-font-size)
(set-face-attribute 'default nil
                    :family hrs/default-fixed-font
                    :height hrs/current-fixed-font-size)
(set-face-attribute 'fixed-pitch nil
                    :family hrs/default-fixed-font
                    :height hrs/current-fixed-font-size)

(setq hrs/default-variable-font "JetBrainsMono Nerd Font Mono")
(setq hrs/default-variable-font-size 100)
(setq hrs/current-variable-font-size hrs/default-variable-font-size)
(set-face-attribute 'variable-pitch nil
                    :family hrs/default-variable-font
                    :height hrs/current-variable-font-size)

(setq hrs/font-change-increment 1.1)

(defun hrs/set-font-size ()
  "Change default, fixed-pitch, and variable-pitch font sizes to match respective variables."
  (set-face-attribute 'default nil
                      :height hrs/current-fixed-font-size)
  (set-face-attribute 'fixed-pitch nil
                      :height hrs/current-fixed-font-size)
  (set-face-attribute 'variable-pitch nil
                      :height hrs/current-variable-font-size))

(defun hrs/reset-font-size ()
  "Revert font sizes back to defaults."
  (interactive)
  (setq hrs/current-fixed-font-size hrs/default-fixed-font-size)
  (setq hrs/current-variable-font-size hrs/default-variable-font-size)
  (hrs/set-font-size))

(defun hrs/increase-font-size ()
  "Increase current font sizes by a factor of `hrs/font-change-increment'."
  (interactive)
  (setq hrs/current-fixed-font-size
        (ceiling (* hrs/current-fixed-font-size hrs/font-change-increment)))
  (setq hrs/current-variable-font-size
        (ceiling (* hrs/current-variable-font-size hrs/font-change-increment)))
  (hrs/set-font-size))

(defun hrs/decrease-font-size ()
  "Decrease current font sizes by a factor of `hrs/font-change-increment', down to a minimum size of 1."
  (interactive)
  (setq hrs/current-fixed-font-size
        (max 1
             (floor (/ hrs/current-fixed-font-size hrs/font-change-increment))))
  (setq hrs/current-variable-font-size
        (max 1
             (floor (/ hrs/current-variable-font-size hrs/font-change-increment))))
  (hrs/set-font-size))

(define-key global-map (kbd "C-)") 'hrs/reset-font-size)
(define-key global-map (kbd "C-+") 'hrs/increase-font-size)
(define-key global-map (kbd "C-=") 'hrs/increase-font-size)
(define-key global-map (kbd "C-_") 'hrs/decrease-font-size)
(define-key global-map (kbd "C--") 'hrs/decrease-font-size)

(hrs/reset-font-size)
