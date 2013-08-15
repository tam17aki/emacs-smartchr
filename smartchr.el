;;; smartchr.el --  emacs version of smartchr.vim

;; Copyright (c) 2009 IMAKADO.
;; Copyright (c) 2013 Akira Tamamori

;; Author: IMAKADO <ken.imakado@gmail.com>
;; blog: http://d.hatena.ne.jp/IMAKADO (japanese)
;; Prefix: smartchr

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; (global-set-key (kbd "=") (smartchr '(" = " " == " " === ")))

;; substitute `!!' with cursor
;; (global-set-key (kbd "{")
;;              (smartchr '("{ `!!' }" "{ \"`!!'\" }" "{")))

(eval-when-compile (require 'cl))

(defgroup smartchr nil
  "smartchr group"
  :group 'smartchr)

(defcustom smartchr-template-cursor-re (rx "`!!'")
  "cursor"
  :group 'smartchr)

(defstruct (smartchr-struct
            (:constructor smartchr-make-struct
                          (&key cleanup-fn insert-fn)))
  cleanup-fn insert-fn)

(defun smartchr (&rest list-of-string)
  (let ((list-of-string (if (consp (car-safe list-of-string))
                            (car-safe list-of-string)
                          list-of-string)))
    (lexical-let ((smartchr-structs (mapcar 'smartchr-parse list-of-string))
                  (last-struct nil)
                  (count 0))
      (lambda ()
        (interactive)
        (if (eq this-command real-last-command)
            (incf count)
          (setq count 0))
        (when (>= count (length smartchr-structs))
          (setq count 0))
        ;; cleanup -> insert
        (let ((struct (nth count smartchr-structs)))
          (assert (smartchr-struct-p struct))
          (when (eq this-command real-last-command)
            (assert (smartchr-struct-p last-struct))
            (funcall (smartchr-struct-cleanup-fn last-struct)))
          (setq last-struct struct)
          (funcall (smartchr-struct-insert-fn struct)))))))

(defun smartchr-parse (template)
  (cond
   ((smartchr-struct-p template)
    template)
   ((functionp template)
    (lexical-let ((str-or-struct (funcall template)))
      (cond
       ((smartchr-struct-p str-or-struct)
        str-or-struct)
       ((stringp str-or-struct)
        (smartchr-parse str-or-struct))
       (t
        (smartchr-make-struct
         :cleanup-fn (lambda ())
         :insert-fn (lambda ()))))))
   ((string-match smartchr-template-cursor-re template)
    (destructuring-bind (pre post)
        (split-string template smartchr-template-cursor-re)
      (lexical-let ((pre pre) (post post))
        (smartchr-make-struct
         :cleanup-fn (lambda ()
                       (delete-char (- (length pre)))
                       (delete-char (length post)))
         :insert-fn (lambda ()
                      (insert pre)
                      (save-excursion (insert post)))))))
   (t
    (lexical-let ((template template))
    (smartchr-make-struct
     :cleanup-fn (lambda ()
                   (delete-char (- (length template))))
     :insert-fn (lambda () (insert template)))))))

(provide 'smartchr)

;; smartchr.el ends here
