;;; flycheck-coala.el --- Integrate coala with flycheck

;; Copyright (c) 2015 Alex Murray
;;
;; Author: Alex Murray <murray.alex@gmail.com>
;; Maintainer: Alex Murray <murray.alex@gmail.com>
;; URL: https://github.com/alexmurray/flycheck-coala
;; Version: 0.1
;; Package-Requires: ((flycheck "0.24") (emacs "24.4"))

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Integrate coala with flycheck


;;; Code:
(require 'flycheck)
(require 'json)

(defun flycheck-coala-severity-to-level (severity)
  "Convert the SEVERITY from coala to a flycheck level type."
  (pcase severity
    (1 'info) ; INFO in coala
    (2 'warning) ; NORMAL in coala
    (3 'error)  ; MAJOR in coala
    (_ 'info)))

(defun flycheck-coala-parse-json (output checker buffer)
  "Parse coala-json errors from OUTPUT via CHECKER for BUFFER."
  (let ((errors)
        (results (cdr (assoc 'results
                             (let ((json-array-type 'list))
                               (json-read-from-string output))))))
    ;; iterate through members of results since each is from a separate section
    ;; of the configuration
    (dolist (section results)
      (dolist (err (cdr section))
        (push (flycheck-error-new
               :buffer buffer
               :checker checker
               :filename (cdr (assoc 'file err))
               :line (cdr (assoc 'line_nr err))
               :message (format "[%s]: %s" (car section) (cdr (assoc 'message err)))
               :level (flycheck-coala-severity-to-level
                       (cdr (assoc 'severity err)))) errors)))
    errors))

(flycheck-define-checker coala
  "A checker using coala.

See URL `https://coala.io'."
  :command ("coala" "--json" "--find-config" "--limit-files" source)
  :error-parser flycheck-coala-parse-json)

(provide 'flycheck-coala)

;;; flycheck-coala.el ends here
