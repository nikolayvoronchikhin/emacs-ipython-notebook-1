(eval-when-compile (require 'cl))
(require 'f)
(require 'espuds)
(require 'ert)

(let* ((support-path (f-dirname load-file-name))
       (root-path (f-parent (f-parent support-path))))
  (add-to-list 'load-path (concat root-path "/lisp"))
  (add-to-list 'load-path (concat root-path "/test")))

(require 'ein-notebooklist)
(require 'ein-jupyter)
(require 'ein-dev)
(require 'ein-testing)

(defvar ein:testing-jupyter-server-root (f-parent (f-dirname load-file-name)))
(ein:deflocal ein:%testing-port% nil)

(defun ein:testing-after-scenario ()
  (ein:testing-flush-queries)
  (with-current-buffer (ein:notebooklist-get-buffer ein:%testing-url%)
    (let ((urlport (ein:$notebooklist-url-or-port ein:%notebooklist%)))
      (loop for notebook in (ein:notebook-opened-notebooks)
            for path = (ein:$notebook-notebook-path notebook)
            do (ein:notebook-kill-kernel-then-close-command notebook t)
               (if (search "Untitled" path )
                   (ein:notebooklist-delete-notebook path)))))
  (ein:testing-flush-queries))

(Setup
 (ein:dev-start-debug)
 (setq ein:notebook-autosave-frequency 0)
 (setq ein:populate-hierarchy-on-notebooklist-open t)
 (setq ein:testing-dump-file-log (concat default-directory "log/ecukes.log"))
 (setq ein:testing-dump-file-messages (concat default-directory "log/ecukes.messages"))
 (setq ein:testing-dump-file-server  (concat default-directory  "log/ecukes.server"))
 (setq ein:testing-dump-file-request  (concat default-directory "log/ecukes.request"))
 (setq ein:jupyter-server-args '("--no-browser" "--debug"))
 (setq ein:%testing-url% nil)
 (deferred:sync! (ein:jupyter-server-start (executable-find "jupyter") ein:testing-jupyter-server-root))
 (ein:testing-wait-until (lambda () (ein:notebooklist-list)) nil 20000 1000)
 (assert (processp %ein:jupyter-server-session%) t "notebook server defunct")
 (setq ein:%testing-url% (car (ein:jupyter-server-conn-info))))

(After
 (ein:testing-after-scenario))

(Teardown
 (cl-letf (((symbol-function 'y-or-n-p) #'ignore))
   (ein:jupyter-server-stop t))
 (assert (not (processp %ein:jupyter-server-session%)) t "notebook server orphaned"))

(Fail
 (if noninteractive
     (ein:testing-after-scenario)
   (keyboard-quit))) ;; useful to prevent emacs from quitting
