;;; parser-test.el --- Tests for parser -*- lexical-binding: t -*-


;;; Commentary:


;;; Code:

(require 'parser)
(require 'ert)

(defun parser-test--distinct ()
  "Test `parser--distinct'."
  (message "Starting tests for (parser--distinct)")

  (should
   (equal
    '(a b c)
    (parser--distinct '(a a b c))))

  (should
   (equal
    '("aa" "b" "cc" "c" "a")
    (parser--distinct '("aa" "b" "cc" "c" "b" "a" "aa"))))
  (message "Passed tests for (parser--distinct)"))

(defun parser-test--first ()
  "Test `parser--first'."
  (message "Starting tests for (parser--first)")

  (should
   (equal
    '(a)
    (parser--first
     1
     'S
     '((S a)))))
  (message "Passed first 1 with rudimentary grammar")

  (should
   (equal
    '("a" "b")
    (parser--first
     2
     'S
     '(
       (S "a" "b" "c")))))
  (message "Passed first 2 with rudimentary grammar")

  (should
   (equal
    '("a" b "c")
    (parser--first
     3
     'S
     '((S "a" b "c")))))
  (message "Passed first 3 with rudimentary grammar")

  (should
   (equal
    '(b)
    (parser--first
     1
     'S
     '((S A)
       (A b)))))
  (message "Passed first 1 with intermediate grammar")

  (should
   (equal
    '("b" "a")
    (parser--first
     2
     'S
     '((S A)
       (A ("b" "a"))))))
  (message "Passed first 2 with intermediate grammar")

  (should
   (equal
    '("b" "a" "c")
    (parser--first
     3
     'S
     '((S A)
       (A ("b" "a" "c" e))))))
  (message "Passed first 3 with intermediate grammar")

  (should
   (equal
    '(c d)
    (parser--first
     1
     'S
     '((S A)
       (A B)
       (B (c d))))))
  (message "Passed first 1 with semi-complex grammar")

  (should
   (equal
    '((c f) (da))
    (parser--first
     2
     'S
     '((S (A a))
       (A B)
       (B (c f) d)))))
  (message "Passed first 2 with semi-complex grammar")

  (should
   (equal
    '(("c" "a" "m") ("d" "a" "m"))
    (parser--first
     3
     'S
     '((S A)
       (A (B "a" "m"))
       (B "c" "d")))))
  (message "Passed first 3 with semi-complex grammar")

  (should
   (equal
    '((a) (b) (c) (e))
    (parser--first
     1
     'S
     '((S (A B))
       (A (B a) e)
       (B (C b) C)
       (C c e)))))
  (message "Passed first 1 with complex grammar")

  ;; Example 5.28 p 402
  (should
   (equal
    '(("a") ("a" "b") ("a" "c") ("b") ("b" "a") ("c") ("c" "a") ("c" "b") (e))
    (parser--first
     2
     'S
     '((S (AB))
       (A (B "a") e)
       (B (C "b") C)
       (C "c" e)))))
  (message "Passed first 2 with complex grammar")

  (should
   (equal
    '(("a") ("a" "b") ("a" "c") ("a" "c" "b") "b" ("b" "a") ("b" "a" "b") ("b" "a" "c") "c" ("c" "a") ("c" "a" "b") ("c" "a" "c") ("c" "b") ("c" "b" "a") e)
    (parser--first
     3
     'S
     '((S (A B))
       (A (B "a") e)
       (B (C "b") C)
       (C "c" e)))))
  (message "Passed first 3 with complex grammar")

  (message "Passed tests for (parser--first)"))

;; Example 5.28 page 402
(defun parser-test--e-free-first ()
  "Test `parser--e-free-first'."
  (message "Starting tests for (parser--e-free-first)")

  ;; Example 5.28 p 402
  (should
   (equal
    '(("c" "a") ("c" "b"))
    (parser--e-free-first
     2
     'S
     '((S (A B))
       (A (B "a") e)
       (B (C "b") C)
       (C "c" e)))))
  (message "Passed empty-free-first 2 with complex grammar")

  (message "Passed tests for (parser--empty-free-first)"))

;; (defun parser-test--v-set ()
;;   "Test `parser--v-set'."
;;   (message "Starting tests for (parser-test--v-set)")

;;   ;; Example 5.29 p 407
;;   (should
;;    (equal
;;     '("ca" "cb")
;;     (parser--v-set
;;      'e
;;      '((S' S)
;;        (S SaSb)
;;        (S e))
;;      'S')))
;;   (message "Passed empty-free-first 2 with complex grammar")

;;   (message "Passed tests for (parser-test--v-set)"))

;; TODO Re-implement this function
(defun parser-test--valid-grammar-p ()
  "Test function `parser--valid-grammar-p'."
  (message "Starting tests for (parser--valid-grammar-p)")

  (should (equal
    t
    (parser--valid-grammar-p '((A B C) ("a" "b" "c") ((A "a")) A))))

  (should (equal
    nil
    (parser--valid-grammar-p '((A B C) ("a" "b" "c") ((A "a")) (A)))))

  (should (equal
    nil
    (parser--valid-grammar-p '((A B C) (("a" "b") "c") ((A "a")) A))))

  (should (equal
    nil
    (parser--valid-grammar-p '(((A B) C) ("a" "b" "c") ((A "a")) A))))

  (should (equal
    nil
    (parser--valid-grammar-p '(((A B) C) ("a" "b" "c") ((A)) A))))

  (should (equal
    nil
    (parser--valid-grammar-p "A")))

  (should (equal
    nil
    (parser--valid-grammar-p '(A B C))))

  (should (equal
    nil
    (parser--valid-grammar-p '((A B)))))

  (should (equal
    nil
    (parser--valid-grammar-p '((A B C) (a (b c) "c") (A ("a" "b") (a b)) (B b) (C "c")))))

  (message "Passed tests for (parser--valid-grammar-p)"))

(defun parser-test--valid-look-ahead-number-p ()
  "Test function `parser--valid-look-ahead-number-p'."
  (message "Starting tests for (parser--valid-look-ahead-number-p)")

  (should (equal
           nil
           (parser--valid-look-ahead-number-p 'A)))

  (should (equal
           nil
           (parser--valid-look-ahead-number-p "A")))

  (should (equal
           nil
           (parser--valid-look-ahead-number-p -2)))

  (should (equal
           nil
           (parser--valid-look-ahead-number-p 3.3)))

  (should (equal
           t
           (parser--valid-look-ahead-number-p 2)))

  (should (equal
           t
           (parser--valid-look-ahead-number-p 1)))

  (message "Passed tests for (parser--valid-look-ahead-number-p)"))

(defun parser-test--valid-sentential-form-p ()
  "Test `parser--valid-sentential-form-p'."
  (message "Starting tests  for (parser--valid-sentential-form-p)")

  (message "Passed tests for (parser--valid-sentential-form-p)"))

(defun parser-test--valid-production-p ()
  "Test `parser--valid-production-p'."
  (message "Starting tests  for (parser--valid-production-p)")

  (should (equal
           t
           (parser--valid-production-p '(A a))))

  (should (equal
           nil
           (parser--valid-production-p "A")))

  (should (equal
           nil
           (parser--valid-production-p '((A a)))))

  (message "Passed tests  for (parser--valid-production-p)"))

(defun parser-test ()
  "Run test."
  (parser-test--valid-look-ahead-number-p)
  (parser-test--valid-production-p)
  (parser-test--valid-grammar-p)
  (parser-test--distinct)
  (parser-test--valid-sentential-form-p)
  (parser-test--first)
  (parser-test--e-free-first)
  ;; (parser-test--v-set)
  )

(provide 'parser-test)

;;; parser-test.el ends here