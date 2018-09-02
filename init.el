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

(menu-bar-mode -1)
(tool-bar-mode -1)
(setq inhibit-startup-screen t)
(setq visible-bell t)
;; (setq-default mode-line-format nil)
(setq insert-default-directory nil) ;; or use double slash mechanism;
(global-eldoc-mode -1)
(setq make-backup-files nil)
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
(set-face-attribute 'highlight nil :background "LightSkyBlue1")
(set-face-attribute 'region nil :background "LightSkyBlue1")
(set-face-attribute 'default nil :height 105)
(set-face-attribute 'fixed-pitch-serif nil :font "Monospace")
(add-hook 'prog-mode-hook 'goto-address-mode)
(add-hook 'text-mode-hook 'goto-address-mode)
(setq-default indent-tabs-mode nil)
(setq-default truncate-lines t)

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
(setq dired-listing-switches "-l -I \".*\" -I \"#*#\" -I \"*.lock\" -I \"target\"")
;; "^\\(\\.*\\)\\'\\|^target\\'|\\.lock\\'\\|^\\(\\#*\\)\\#\\'"
;; https://www.gnu.org/software/emacs/manual/html_node/emacs/Regexps.html
(add-hook 'dired-mode-hook (lambda () (progn (dired-hide-details-mode 1)
                                             (setq cursor-type nil)
                                             (hl-line-mode 1))))
;; https://www.emacswiki.org/emacs/DiredView
;; async file operations in dired

(require-package 'dired-subtree)
(setq dired-subtree-use-backgrounds nil)

(require 'hl-line)
;; make highlighted lines in other (not selected) windows gray;
(defun hl-line-update-face (window)
  "update the `hl-line' face in WINDOW to indicate whether the window is selected;"
  (with-current-buffer (window-buffer window)
    (when (or global-hl-line-mode hl-line-mode)
      (if (eq (current-buffer) (window-buffer (selected-window)))
          (face-remap-reset-base 'hl-line)
        (face-remap-set-base 'hl-line :background "#dddddd")))))
(add-hook 'buffer-list-update-hook
          (lambda () (walk-windows #'hl-line-update-face nil t)))

(defun show-projects (projects-path)
  (dired projects-path)

  ;; to do: automatically mount storage devices when available,
  ;;   and show their "projects" directories in seperate panes (Emacs windows);
  ;; the name of projects in other panes will be named like this:
  ;;   "project_name/partition_name/";
  ;; after unmounting a pane, we must force close all windows
  ;;   in workspaces named "*/partition_name/";
  ;; https://wiki.archlinux.org/index.php/Udisks#udevadm_monitor

  (defun dired-find-project ()
    (interactive)
    (let ((project-path (dired-get-filename)))
      (if (file-directory-p project-path)
          (let* ((project-name (file-name-nondirectory project-path))
                 (workspace-name (concat "1:" project-name)))
            ;; go to the workspace named "1:project_name";
            ;; rename it to "1:project_name"; (this apparently mundane command is for
            ;;     moving workspace button to the first position in i3-bar);
            ;; then if there is no Emacs frame with title "project_name" in the workspace:
            ;; , first close all windows in current workspace,
            ;;   and all workspaces named like this: "1:project_name /*";
            ;; , then run a new instance of Emacs for this project;
            (call-process-shell-command
             (concat
              "i3-msg workspace '\"" workspace-name "\"'; "
              "i3-msg rename workspace '\"" workspace-name "\"'"
              "  to '\"" workspace-name "\"'; "
              "if [[ \"$(i3-msg [workspace=__focused__ class=Emacs tiling] focus)\""
              "  =~ \"false\" ]]; "
              "then "
              "  i3-msg [workspace=\"^" workspace-name " /\"] kill; "
              "  i3-msg [workspace=__focused__] kill; "
              "  emacs --eval '(goto-project \"" project-path "\")' & fi"))
            ))))
  (define-key dired-mode-map [remap dired-find-file] 'dired-find-project)
)

(defun goto-project (project-path)
  (require 'desktop)
  (let ((desktop-file-dir-path (expand-file-name ".cache/" project-path))
        (desktop-file-path (expand-file-name ".cache/.emacs.desktop" project-path)))
    (unless (file-exists-p desktop-file-dir-path)
      (make-directory desktop-file-dir-path t))
    (unless (file-exists-p desktop-file-path)
      (write-region "" nil desktop-file-path))
    (add-to-list 'desktop-path desktop-file-dir-path))
  (setq desktop-restore-frames nil)
  (setq desktop-load-locked-desktop t)
  (desktop-save-mode 1)

  (defun project-explorer ()
    (interactive)
    (let ((buffer (dired-noselect project-path)))
      (display-buffer-in-side-window buffer '((side . left) (window-width . 0.25)))
      (set-window-dedicated-p (get-buffer-window buffer) t)
      (select-window (get-buffer-window buffer))))
  (global-set-key (kbd "C-c p") 'project-explorer)
  (setq window-sides-vertical t)
  (project-explorer)

  (defun project-explorer-find-or-expand ()
    (interactive)
    (let ((file-name (dired-get-filename)))
      (if (file-directory-p file-name)
          (if (string-match-p "\\.m\\'" file-name)
              (progn
                ;; open image-dired/movie in the right window
                ;; http://ergoemacs.org/emacs/emacs_view_image_thumbnails.html
                ;; https://www.gnu.org/software/emacs/manual/html_node/emacs/Image_002dDired.html
                ;; https://www.emacswiki.org/emacs/ThumbsMode
                ;; https://lars.ingebrigtsen.no/2011/04/12/emacs-movie-browser/
                ;; https://github.com/larsmagne/movie.el
                ;; http://www.mplayerhq.hu/DOCS/tech/slave.txt
                ;; https://www.gnu.org/software/emms/
                ;; http://wikemacs.org/wiki/Media_player
                ;; https://github.com/dbrock/bongo
                (dired-find-file-other-window))
            (dired-subtree-insert)
            (revert-buffer))
        (dired-find-file-other-window))))
  (define-key dired-mode-map [remap dired-find-file] 'project-explorer-find-or-expand))

;; https://www.gnu.org/software/emacs/manual/html_node/emacs/FFAP.html
(defun go-to-link-at-point ()
  "open the project with the URL under cursor; 
  if the path starts with “http://”, copy it and go to Firefox workspace;"
  (interactive)
  (let (($path (ffap-file-at-point)))
    (if (string-match-p "\\`git://" $path)
        (progn
          (
           ))
      (if (string-match-p "\\`https?://" $path)
          (progn
            (
             ))
        (message "file doesn't exist: '%s';" $path)))))

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
;; https://stackoverflow.com/questions/3050011/is-it-possible-to-move-the-emacs-minibuffer-to-the-top-of-the-screen
;; https://emacs.stackexchange.com/questions/1074/how-to-display-the-content-of-minibuffer-in-the-middle-of-the-emacs-frame
;; https://www.emacswiki.org/emacs/Dedicated_Minibuffer_Frame

;; https://orgmode.org/manual/Tables.html
;; https://www.gnu.org/software/emacs/manual/html_node/emacs/Text-Based-Tables.html
;; http://shallowsky.com/blog/linux/editors/graphics-in-emacs.html
;; https://www.gnu.org/software/auctex
;; https://github.com/aaptel/preview-latex
;; https://github.com/josteink/wsd-mode
;; https://jblevins.org/projects/markdown-mode/

;; lsp-rust, lsp-flycheck
;; https://christian.kellner.me/2017/05/31/language-server-protocol-lsp-rust-and-emacs/
;; https://github.com/rust-lang/rust-mode
;; https://github.com/kwrooijen/cargo.el
;; https://github.com/racer-rust/emacs-racer
;; https://github.com/flycheck/flycheck-rust
;; http://julienblanchard.com/2016/fancy-rust-development-with-emacs/

;; https://github.com/dengste/minimap
;; https://www.gnu.org/software/emacs/draft/manual/html_node/elisp/Side-Windows.html
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
;;   https://github.com/gromnitsky/wordnut
;;   https://www.emacswiki.org/emacs/ThesauriAndSynonyms
;;   https://github.com/atykhonov/google-translate
;; https://www.gnu.org/software/emacs/manual/html_node/calc/index.html
;; https://github.com/domtronn/all-the-icons.el
;; https://www.gnu.org/software/emacs-muse/manual/html_node/Extending-Muse.html#Extending-Muse
;; https://github.com/Fuco1/smartparens
;; http://company-mode.github.io/
