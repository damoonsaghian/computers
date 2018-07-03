(tool-bar-mode -1)
(menu-bar-mode -1)
(global-eldoc-mode -1)
(add-to-list 'default-frame-alist '(left-fringe . 4))
(add-to-list 'default-frame-alist '(right-fringe . 0))
(setq visible-bell t)
(setq inhibit-startup-screen t)
(setq insert-default-directory nil)
(setq make-backup-files nil)
; (setq-default mode-line-format nil)
(global-set-key (kbd "C-x k") #'kill-this-buffer)

(setq scroll-conservatively 200) ; never recenter point
(setq-default indent-tabs-mode nil)
(add-to-list 'default-frame-alist '(foreground-color . "#222222"))
(set-face-attribute 'region nil :background "sky blue")
(set-face-attribute 'default nil :height 105)
(set-face-attribute 'fixed-pitch-serif nil :font "Monospace")
(add-hook 'prog-mode-hook 'goto-address-mode)
(add-hook 'text-mode-hook 'goto-address-mode)

(setq-default cursor-type 'bar)
(setq blink-cursor-blinks 0)
(set-face-attribute 'cursor nil :background "red")
(global-hl-line-mode 1)
(set-face-attribute 'highlight nil :background "lemon chiffon")
(show-paren-mode 1)

(setq scroll-bar-adjust-thumb-portion nil)
(add-to-list 'default-frame-alist '(scroll-bar-width . 13))
; https://stackoverflow.com/questions/21175099/how-to-automatically-add-remove-scroll-bars-as-needed-by-text-height

; paragraphs
(setq paragraph-start "\n" paragraph-separate "\n")
(defun next-paragraph ()
  (interactive)
  (unless (bobp) (left-char))
  (forward-paragraph)
  (unless (eobp) (progn (forward-paragraph)
                        (redisplay t)
                        (backward-paragraph)
                        (right-char))))
(global-set-key (kbd "C-<down>") 'next-paragraph)
(defun previous-paragraph ()
  (interactive)
  (left-char)
  (backward-paragraph)
  (unless (bobp) (progn (forward-paragraph)
                        (redisplay t)
                        (backward-paragraph)
                        (right-char))))
(global-set-key (kbd "C-<up>") 'previous-paragraph)

; adaptive wrap
; this is taken from adaptive-wrap package;
(defun adaptive-wrap-fill-context-prefix (beg en)
  "like `fill-context-prefix', but with length 2;"
  ; note: fill-context-prefix may return nil; see: http://article.gmane.org/gmane.emacs.devel/156285
  (let* ((fcp (or (fill-context-prefix beg en) ""))
         (fcp-len (string-width fcp))
         (fill-char (if (< 0 fcp-len)
                        (string-to-char (substring fcp -1))
                      ?\ )))
    (concat fcp
            (make-string 2 fill-char))))

(defun adaptive-wrap-prefix-function (beg end)
  "indent the region between BEG and END with adaptive filling;"
  ; any change at the beginning of a line might change its wrap prefix, which affects the whole line;
  ; so we need to "round-up" `end' to the nearest end of line;
  ; we do the same with `beg' although it's probably not needed;
  (goto-char end)
  (unless (bolp) (forward-line 1))
  (setq end (point))
  (goto-char beg)
  (forward-line 0)
  (setq beg (point))
  (while (< (point) end)
    (let ((lbp (point)))
      (put-text-property (point)
                         (progn (search-forward "\n" end 'move) (point))
                         'wrap-prefix
                         (let ((pfx (adaptive-wrap-fill-context-prefix
                                     lbp (point))))
                           ; remove any `wrap-prefix' property that might have been added earlier;
                           ; otherwise, we end up with a string containing a `wrap-prefix' string, containing a `wrap-prefix' string ...
                           (remove-text-properties 0 (length pfx) '(wrap-prefix) pfx)
                           pfx))))
  `(jit-lock-bounds ,beg . ,end))

(define-minor-mode adaptive-wrap-prefix-mode
  "wrap the buffer text with adaptive filling;"
  :lighter ""
  :group 'visual-line
  (if adaptive-wrap-prefix-mode
      (progn
        ; HACK ATTACK! we want to run after font-lock (so our wrap-prefix includes the faces applied by font-lock),
        ; but  jit-lock-register doesn't accept an `append' argument,
        ; so we add ourselves beforehand, to make sure we're at the end of the hook (bug#15155);
        (add-hook 'jit-lock-functions
                  #'adaptive-wrap-prefix-function 'append t)
        (jit-lock-register #'adaptive-wrap-prefix-function))
    (jit-lock-unregister #'adaptive-wrap-prefix-function)
    (with-silent-modifications
      (save-restriction
        (widen)
        (remove-text-properties (point-min) (point-max) '(wrap-prefix nil))))))
(add-hook 'visual-line-mode-hook #'adaptive-wrap-prefix-mode)
(global-visual-line-mode +1)

(setq-default proced-auto-update-flag t)
(setq-default proced-auto-update-interval 2)

; dired
(add-hook 'dired-mode-hook 'dired-hide-details-mode)
(add-hook 'dired-mode-hook 'hl-line-mode)
(setq dired-listing-switches "-l -I \"target\" -I \"*.lock\" -I \"#*#\"")
(setq dired-recursive-deletes 'always)
(setq dired-recursive-copies 'always)

(defun dired-open-file ()
  "open the thing under point; that can be either file or any other line of dired listing;"
  (interactive)
  (let ((file-name (dired-get-filename nil t)))
    (cond
     ((and (file-directory-p file-name) (string-match-p "/home/*/projects/*" file-name))
      ; first move all windows in the main workspace into the hidden workspace, and rename the main workspace to "project_name"; then if there is an Emacs frame named "project_name", move it to the main workspace; otherwise load the saved Emacs desktop in the hidden workspace, then move the Emacs frame named "project_name" to the main workspace;
      )
     ((and (file-directory-p file-name) (string-match-p "\\.m$" file-name))
      ; open image-dired/movie in in the right window
      )
     ((file-directory-p file-name)
      ; expand subtree
      )
     (t
      ; find file in the right window
      ))
    ))
; (eval-after-load "dired"
;   '(define-key dired-mode-map [remap dired-find-file] 'dired-open-file))

(defun go-to-link-at-point ()
  "open the file path under cursor; if the path starts with “http://”, open the URL in browser; input path can be relative, full path, URL;"
  (interactive)
  (let (($path (ffap-file-at-point)))
    (if (string-match-p "\\`https?://" $path)
        (progn
          (
           ; if the web_browser with the profile corresponding to this project is not open, open it; then if there is a web_browser window named "project-name, $path", raise it; otherwise create it;
           ))
      (if (file-exists-p $path)
          (progn
            (
             ; if there is an emacs frame named "project-name, $path", raise it; otherwise create it;
             ))
        (message "file doesn't exist: '%s';" $path)))))

(require 'package)
(defun require-package (package)
  (unless (require package nil 'noerror)
    (progn
      (unless (assoc package package-archive-contents)
	(package-refresh-contents))
      (package-install package)
      (require package))))
(defun install-package (package)
  (unless (package-installed-p package nil 'noerror)
    (progn
      (unless (assoc package package-archive-contents)
	(package-refresh-contents))
      (package-install package))))
(add-to-list 'package-archives
	     '("melpa" . "https://melpa.org/packages/") t)
;(package-initialize)
;(require-package 'package-name)
