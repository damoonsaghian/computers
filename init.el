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
(package-initialize)
;; https://github.com/rranelli/auto-package-update.el/blob/master/auto-package-update.el

(tool-bar-mode -1)
(menu-bar-mode -1)
(setq inhibit-startup-screen t)
(setq visible-bell t)
(setq make-backup-files nil)
;; (setq-default mode-line-format nil)
(setq insert-default-directory nil)
(global-eldoc-mode -1)
(global-set-key (kbd "C-x k") #'kill-this-buffer)

(setq window-divider-default-places t
      window-divider-default-right-width 2
      window-divider-default-bottom-width 1)
(window-divider-mode 1)
(setq scroll-bar-adjust-thumb-portion nil)
(add-to-list 'default-frame-alist '(scroll-bar-width . 13))
(add-to-list 'default-frame-alist '(left-fringe . 2))
(add-to-list 'default-frame-alist '(right-fringe . 0))

(setq scroll-conservatively 200) ;; never recenter point
;; move point to top/bottom of buffer before signaling a scrolling error;
(setq scroll-error-top-bottom t)

(setq blink-cursor-blinks 0)
(setq-default cursor-in-non-selected-windows nil)

(add-to-list 'default-frame-alist '(foreground-color . "#222222"))
(set-face-attribute 'highlight nil :background "lemon chiffon")
(set-face-attribute 'region nil :background "LightSkyBlue1")
(set-face-attribute 'default nil :height 105)
(set-face-attribute 'fixed-pitch-serif nil :font "Monospace")
(add-hook 'prog-mode-hook 'goto-address-mode)
(add-hook 'text-mode-hook 'goto-address-mode)
(setq-default indent-tabs-mode nil)

(require-package 'adaptive-wrap)
(setq-default adaptive-wrap-extra-indent 2)
(add-hook 'visual-line-mode-hook #'adaptive-wrap-prefix-mode)
(global-visual-line-mode +1)

;; paragraphs
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

(require 'dired)
(setq dired-recursive-deletes 'always)
(setq dired-recursive-copies 'always)
;; https://www.emacswiki.org/emacs/DiredView

;; when Emacs is called with -projects argument, show the list of projects:
(add-to-list
 'command-switch-alist
 (cons
  "projects"
  #'(lambda (projects-path)
      (set-frame-name "projects")
      (setq dired-listing-switches "-l -I \".*\" -I \"#*#\" -I \"*.lock\" -I \"target\"")
      (add-hook 'dired-mode-hook 'dired-hide-details-mode)
      (dired projects-path)
      ;; todo: automatically mount storage devices when available, and show their "projects" directories in seperate panes (Emacs windows);
      ;; the name of projects in other panes will be prefixed with a number indicating the pane number, like this: "[1] project_name";
      ;; after unmounting pane 1 for example, we must force close all windows in workspace named "[1]*";

      (defun dired-find-project ()
        (interactive)
        (let ((file-name (dired-get-filename nil t)))
          (when (file-directory-p file-name)
            ;; if workspace "1:project_name" is not empty, go to that workspace, and rename it to "1:project_name" (this apparently mundane command is for moving workspace button to the first position in i3-bar); but if it's empty:
            ;; , go to "/hidden/" workspace;
            ;; , execute: emacs -project file-name;
            )))
      (define-key dired-mode-map [remap dired-find-file] 'dired-find-project)

      ;; packages which need to be installed, but are not needed to be "required" in projects view instance:
      (install-package 'sr-speedbar))))

;; when Emacs is called with -project argument:
(add-to-list
 'command-switch-alist
 (cons
  "project"
  #'(lambda (project-path)
      (desktop-save-mode 1)
      (desktop-change-dir project-path)

      ;; go to workspace "1:project_name", and rename it to "1:project_name";
      ;; move the window named "project_name" from the "/hidden/" workspace to "1:project_name" workspace;
      
      ;; https://www.emacswiki.org/emacs/sr-speedbar.el
      ;; sr-speedbar-open, sr-speedbar-select-window
      ;; sr-speedbar-auto-refresh
      ;; copy, rename, delete, speedbar-creat-directory works just like in dired;
      ;; speedbar-line-{file,directory,path}
      ;; speedbar-{edit,expand,contract}-line
      ;; button-face, file-face, directory-face, selected-face
      ;; speedbar-path-line
      ;; speedbar-ignored-directory-expressions, speedbar-ignored-path-expressions
      ;; next file:
      ;; , go to tree view
      ;; , next file
      ;; , open (in the window at right, go to the first line)
      ;; https://www.gnu.org/software/emacs/draft/manual/html_node/elisp/Side-Windows.html
      ;; http://mads-hartmann.com/2016/05/12/emacs-tree-view.html

      (require-package 'sr-speedbar)
      (setq sr-speedbar-right-side nil)
      (setq sr-speedbar-skip-other-window-p t)
      (setq speedbar-directory-unshown-regexp "^\\(\\.*\\)\\'\\|^target\\'")
      (setq speedbar-file-unshown-regexp "^\\(\\.*\\)\\'\\|\\.lock\\'\\|^\\(\\#*\\)\\#\\'")
      (setq speedbar-show-unknown-files t)
      (setq speedbar-use-images nil)
      ;; (setq speedbar-indentation-width 2)
      (defun sr-speedbar-open-file ()
        (interactive)
        (let ((file-name (speedbar-line-file nil t)))
          (if (and (file-directory-p file-name) (string-match-p "\\.m\\'" file-name))
              (find-file file-name)
              ;; open image-dired/movie in the right window
              ;; http://ergoemacs.org/emacs/emacs_view_image_thumbnails.html
              ;; https://www.gnu.org/software/emacs/manual/html_node/emacs/Image_002dDired.html
              ;; https://www.emacswiki.org/emacs/ThumbsMode
              ;; https://lars.ingebrigtsen.no/2011/04/12/emacs-movie-browser/
              ;; https://github.com/larsmagne/movie.el
              ;; http://www.mplayerhq.hu/DOCS/tech/slave.txt
              ;; https://www.gnu.org/software/emms/screenshots.html
              ;; http://wikemacs.org/wiki/Media_player
              ;; https://github.com/dbrock/bongo
            (speedbar-find-file))))
      (define-key speedbar-mode-map [remap speedbar-find-file] speedbar-open-file))))

;; https://www.gnu.org/software/emacs/manual/html_node/emacs/FFAP.html
(defun go-to-link-at-point ()
  "open the file path under cursor; if the path starts with “http://”, open the URL in browser; input path can be relative, full path, URL;"
  (interactive)
  (let (($path (ffap-file-at-point)))
    (if (string-match-p "\\`https?://" $path)
        (progn
          (
           ;; if the web_browser with the profile corresponding to this project is not open, open it; then if there is a web_browser window named "project-name, $path", raise it; otherwise create it;
           ))
      (if (file-exists-p $path)
          (progn
            (
             ;; if there is an emacs frame named "project-name, $path", raise it; otherwise create it;
             ))
        (message "file doesn't exist: '%s';" $path)))))

;; https://www.emacswiki.org/emacs/BrowseUrl
;; https://www.chromium.org/user-experience/multi-profiles

;; view-mode
;; https://github.com/emacs-evil/evil
;; https://github.com/emacs-evil/evil-collection
;; https://www.gnu.org/software/emacs/manual/html_mono/viper.html
;; https://github.com/mrkkrp/modalka
;; https://github.com/jyp/boon
;; http://retroj.net/modal-mode
;; https://github.com/abo-abo/hydra
;; https://github.com/chrisdone/god-mode
;; https://github.com/xahlee/xah-fly-keys
;; https://github.com/ergoemacs/ergoemacs-mode
;; https://github.com/justbur/emacs-which-key
;; https://www.gnu.org/software/emacs/manual/html_node/emacs/Abbrevs.html



;; https://www.gnu.org/software/emacs/manual/html_node/elisp/Minibuffers-and-Frames.html
;; https://stackoverflow.com/questions/5079466/hide-emacs-echo-area-during-inactivity
;; https://emacs.stackexchange.com/questions/1074/how-to-display-the-content-of-minibuffer-in-the-middle-of-the-emacs-frame
;; https://www.emacswiki.org/emacs/Dedicated_Minibuffer_Frame

;; https://orgmode.org/manual/Tables.html
;; https://www.gnu.org/software/emacs/manual/html_node/emacs/Text-Based-Tables.html
;; http://shallowsky.com/blog/linux/editors/graphics-in-emacs.html
;; https://www.gnu.org/software/auctex
;; https://github.com/aaptel/preview-latex
;; https://github.com/josteink/wsd-mode
;; https://jblevins.org/projects/markdown-mode/

;; https://github.com/dengste/minimap

;; lsp-rust, lsp-flycheck
;; https://christian.kellner.me/2017/05/31/language-server-protocol-lsp-rust-and-emacs/
;; https://github.com/rust-lang/rust-mode
;; https://github.com/kwrooijen/cargo.el
;; https://github.com/racer-rust/emacs-racer
;; https://github.com/flycheck/flycheck-rust
;; http://julienblanchard.com/2016/fancy-rust-development-with-emacs/

;; https://github.com/hlissner/doom-emacs/wiki/FAQ#how-is-dooms-startup-so-fast
;; https://www.emacswiki.org/emacs/DiredSync
;; http://ergoemacs.org/emacs/emacs_magit-mode_tutorial.html
;;   https://magit.vc/
;;   https://github.com/vermiculus/magithub
;; https://github.com/DarthFennec/highlight-indent-guides
;;   https://github.com/zk-phi/indent-guide
;; https://www.gnu.org/software/emacs/manual/html_node/gnus/index.html
;;   https://www.gnu.org/software/emacs/manual/html_node/message/index.html
;;   https://www.gnu.org/software/emacs/manual/html_node/emacs/Gnus.html
;;   https://www.gnu.org/software/emacs/manual/html_node/emacs/Sending-Mail.html
;;   https://www.gnu.org/software/emacs/manual/html_node/emacs/Rmail.html
;;   https://www.gnu.org/software/emacs/manual/html_node/mh-e/index.html
;; https://www.gnu.org/software/emacs/manual/html_node/emacs/Calendar_002fDiary.html
;; http://www.gnu.org/software/emacs/manual/html_node/elisp/Timers.html
;; https://www.gnu.org/software/emacs/manual/html_node/emacs/Spelling.html
;; https://www.emacswiki.org/emacs/DictMode
;;   https://www.emacswiki.org/emacs/DictEm
;;   https://www.emacswiki.org/emacs/wordnik.el
;;   https://github.com/gromnitsky/wordnut
;;   https://www.emacswiki.org/emacs/ThesauriAndSynonyms
;;   https://github.com/atykhonov/google-translate
;; https://www.gnu.org/software/emacs/manual/html_node/calc/index.html
;; https://github.com/domtronn/all-the-icons.el
