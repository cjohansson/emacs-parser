;;; parser-generator-lr-test.el --- Tests for LR(k) Parser Generator -*- lexical-binding: t -*-


;;; Commentary:


;;; Code:


(require 'parser-generator-lr)
(require 'ert)

(defun parser-generator-lr-test--parse-incremental-vs-regular ()
  "Verify that regular and incremental parse results in same data."
  (let ((regular-parse (parser-generator-lr--parse)))
    ;; (message "regular-parse: %s" regular-parse)
    (let ((regular-parse-history (nth 3 regular-parse)))
      ;; (message "regular-parse-history: %s" regular-parse-history)
      (let ((history-length (length regular-parse-history))
            (history-index 0)
            (history)
            (iterated-history))
        (while (< history-index history-length)
          (setq history (nth history-index regular-parse-history))
          (let ((input-tape-index (nth 0 history))
                (pushdown-list (nth 1 history))
                (output (nth 2 history))
                (translation (nth 3 history))
                (translation-symbol-table (nth 4 history))
                (history-list iterated-history))

            ;; (message "input-tape-index: %s" input-tape-index)
            ;; (message "pushdown-list: %s" pushdown-list)
            ;; (message "output: %s" output)
            ;; (message "translation: %s" translation)
            ;; (message "history-list: %s" history-list)

            (let ((incremental-parse
                   (parser-generator-lr--parse
                    input-tape-index
                    pushdown-list
                    output
                    translation
                    translation-symbol-table
                    history-list)))
              ;; (message "incremental-parse: %s" incremental-parse)
              (should
               (equal
                regular-parse
                incremental-parse))
              (message "Passed incremental parse test %s" (1+ history-index)))

            (push history iterated-history)
            (setq history-index (1+ history-index))))))))

(defun parser-generator-lr-test--generate-action-tables ()
  "Test `parser-generator-lr--generate-action-tables'."
  (message "Starting tests for (parser-generator-lr--generate-action-tables)")

  ;; Example 5.32 p. 393
  (parser-generator-set-grammar '((Sp S) (a b) ((Sp S) (S (S a S b)) (S e)) Sp))
  (parser-generator-set-look-ahead-number 1)
  (parser-generator-process-grammar)
  (parser-generator-lr-generate-parser-tables)

  ;; Fig. 5.9 p. 374, replaced e with $
  (should
   (equal
    '((0 ((($) reduce 2) ((a) reduce 2)))
      (1 ((($) accept) ((a) shift)))
      (2 (((a) reduce 2) ((b) reduce 2)))
      (3 (((a) shift) ((b) shift)))
      (4 (((a) reduce 2) ((b) reduce 2)))
      (5 ((($) reduce 1) ((a) reduce 1)))
      (6 (((a) shift) ((b) shift)))
      (7 (((a) reduce 1) ((b) reduce 1))))
    (parser-generator--hash-to-list
     parser-generator-lr--action-tables)))

  ;; TODO Test with look-ahead number > 1 here

  (message "Ended tests for (parser-generator-lr--generate-action-tables)"))

(defun parser-generator-lr-test--generate-goto-tables ()
  "Test `parser-generator-lr--generate-goto-tables'."
  (message "Starting tests for (parser-generator-lr--generate-goto-tables)")

  ;; Example 5.30, p. 389
  (parser-generator-set-grammar
   '((Sp S) (a b) ((Sp S) (S (S a S b)) (S e)) Sp))
  (parser-generator-set-look-ahead-number 1)
  (parser-generator-process-grammar)
  (let ((table-lr-items
         (parser-generator-lr--generate-goto-tables)))

    (parser-generator--debug
     (message
      "GOTO-table: %s"
      (parser-generator--hash-to-list
       parser-generator-lr--goto-tables)))
    (should
     (equal
      '((0 ((S 1)))
        (1 ((a 2)))
        (2 ((S 3)))
        (3 ((a 4) (b 5)))
        (4 ((S 6)))
        (5 nil)
        (6 ((a 4) (b 7)))
        (7 nil))
      (parser-generator--hash-to-list
       parser-generator-lr--goto-tables)))
    (message "Passed GOTO-tables")

    (parser-generator--debug
     (message
      "LR-items: %s"
      (parser-generator--hash-to-list
       table-lr-items)))
    (should
     (equal
      '((0 (((S) nil (S a S b) ($)) ((S) nil (S a S b) (a)) ((S) nil nil ($)) ((S) nil nil (a)) ((Sp) nil (S) ($))))
        (1 (((S) (S) (a S b) ($)) ((S) (S) (a S b) (a)) ((Sp) (S) nil ($))))
        (2 (((S) (S a) (S b) ($)) ((S) (S a) (S b) (a)) ((S) nil (S a S b) (a)) ((S) nil (S a S b) (b)) ((S) nil nil (a)) ((S) nil nil (b))))
        (3 (((S) (S) (a S b) (a)) ((S) (S) (a S b) (b)) ((S) (S a S) (b) ($)) ((S) (S a S) (b) (a))))
        (4 (((S) (S a) (S b) (a)) ((S) (S a) (S b) (b)) ((S) nil (S a S b) (a)) ((S) nil (S a S b) (b)) ((S) nil nil (a)) ((S) nil nil (b))))
        (5 (((S) (S a S b) nil ($)) ((S) (S a S b) nil (a))))
        (6 (((S) (S) (a S b) (a)) ((S) (S) (a S b) (b)) ((S) (S a S) (b) (a)) ((S) (S a S) (b) (b))))
        (7 (((S) (S a S b) nil (a)) ((S) (S a S b) nil (b)))))
      (parser-generator--hash-to-list
       table-lr-items)))
    (message "Passed LR-items"))

  (message "Passed LR-items for example 5.30")

  ;; Example 5.30, p. 389 but with terminals as strings
  (parser-generator-set-grammar
   '((Sp S) ("a" "b") ((Sp S) (S (S "a" S "b")) (S e)) Sp))
  (parser-generator-set-look-ahead-number 1)
  (parser-generator-process-grammar)

  (let ((table-lr-items
         (parser-generator-lr--generate-goto-tables)))

    ;; (message "GOTO-table: %s" (parser-generator--hash-to-list parser-generator-lr--goto-tables))
    ;; (message "LR-items: %s" (parser-generator--hash-to-list parser-generator-lr--items))

    (should
     (equal
      '((0 ((S 1)))
        (1 (("a" 2)))
        (2 ((S 3)))
        (3 (("a" 4) ("b" 5)))
        (4 ((S 6)))
        (5 nil)
        (6 (("a" 4) ("b" 7)))
        (7 nil))
      (parser-generator--hash-to-list
       parser-generator-lr--goto-tables)))
    (message "Passed GOTO-tables with tokens as strings")

    (should
     (equal
      '((0 (((S) nil (S "a" S "b") ($)) ((S) nil (S "a" S "b") ("a")) ((S) nil nil ($)) ((S) nil nil ("a")) ((Sp) nil (S) ($))))
        (1 (((S) (S) ("a" S "b") ($)) ((S) (S) ("a" S "b") ("a")) ((Sp) (S) nil ($))))
        (2 (((S) (S "a") (S "b") ($)) ((S) (S "a") (S "b") ("a")) ((S) nil (S "a" S "b") ("a")) ((S) nil (S "a" S "b") ("b")) ((S) nil nil ("a")) ((S) nil nil ("b"))))
        (3 (((S) (S) ("a" S "b") ("a")) ((S) (S) ("a" S "b") ("b")) ((S) (S "a" S) ("b") ($)) ((S) (S "a" S) ("b") ("a"))))
        (4 (((S) (S "a") (S "b") ("a")) ((S) (S "a") (S "b") ("b")) ((S) nil (S "a" S "b") ("a")) ((S) nil (S "a" S "b") ("b")) ((S) nil nil ("a")) ((S) nil nil ("b"))))
        (5 (((S) (S "a" S "b") nil ($)) ((S) (S "a" S "b") nil ("a"))))
        (6 (((S) (S) ("a" S "b") ("a")) ((S) (S) ("a" S "b") ("b")) ((S) (S "a" S) ("b") ("a")) ((S) (S "a" S) ("b") ("b"))))
        (7 (((S) (S "a" S "b") nil ("a")) ((S) (S "a" S "b") nil ("b")))))
      (parser-generator--hash-to-list table-lr-items)))
    (message "Passed LR-items with tokens as strings"))

  (message "Passed LR-items for example 5.30 but with tokens as strings")

  ;; TODO Test with look-ahead number > 1 he

  (message "Passed tests for (parser-r--generate-goto-tables)"))

(defun parser-generator-lr-test--items-for-prefix ()
  "Test `parser-generator-lr--items-for-prefix'."
  (message "Starting tests for (parser-generator-lr--items-for-prefix)")

  ;; Example 5.29 p 387
  (parser-generator-set-grammar
   '((Sp S) (a b) ((Sp S) (S (S a S b)) (S e)) Sp))
  (parser-generator-set-look-ahead-number 1)
  (parser-generator-process-grammar)

  (should
   (equal
    '(((S) nil (S a S b) ($))
      ((S) nil (S a S b) (a))
      ((S) nil nil ($))
      ((S) nil nil (a))
      ((Sp) nil (S) ($)))
    (parser-generator-lr--items-for-prefix 'e)))
  (message "Passed V(e)")

  (should
   (equal
    '(((S) (S) (a S b) ($))
      ((S) (S) (a S b) (a))
      ((Sp) (S) nil ($)))
    (parser-generator-lr--items-for-prefix 'S)))
  (message "Passed V(S)")

  (should
   (equal
    nil
    (parser-generator-lr--items-for-prefix 'a)))
  (message "Passed V(a)")

  (should
   (equal
    nil
    (parser-generator-lr--items-for-prefix 'b)))
  (message "Passed V(b)")

  (should
   (equal
    '(((S) (S a) (S b) ($))
      ((S) (S a) (S b) (a))
      ((S) nil (S a S b) (a))
      ((S) nil (S a S b) (b))
      ((S) nil nil (a))
      ((S) nil nil (b)))
    (parser-generator-lr--items-for-prefix '(S a))))
  (message "Passed V(Sa)")

  (should
   (equal
    nil
    (parser-generator-lr--items-for-prefix '(S S))))
  (message "Passed V(SS)")

  (should
   (equal
    nil
    (parser-generator-lr--items-for-prefix '(S b))))
  (message "Passed V(Sb)")

  ;; a3 p. 390
  (should
   (equal
    '(((S) (S) (a S b) (a))
      ((S) (S) (a S b) (b))
      ((S) (S a S) (b) ($))
      ((S) (S a S) (b) (a)))
    (parser-generator-lr--items-for-prefix '(S a S))))
  (message "Passed V(SaS)")

  (should
   (equal
    nil
    (parser-generator-lr--items-for-prefix '(S a a))))
  (message "Passed V(Saa)")

  (should
   (equal
    nil
    (parser-generator-lr--items-for-prefix '(S a b))))
  (message "Passed V(Sab)")

  (message "Passed tests for (parser-generator-lr--items-for-prefix)"))

(defun parser-generator-lr-test--items-valid-p ()
  "Test `parser-generator-lr--items-valid-p'."
  (message "Started tests for (parser-generator-lr--items-valid-p)")

  (parser-generator-set-grammar '((Sp S) (a b) ((Sp S) (S (S a S b)) (S e)) Sp))
  (parser-generator-set-look-ahead-number 1)
  

  (let ((table-lr-items (parser-generator-process-grammar)))

    (should
     (equal
      t
      (parser-generator-lr--items-valid-p (parser-generator--hash-values-to-list table-lr-items t))))

    (message "Passed first"))

  (should
   (equal
    nil
    (parser-generator-lr--items-valid-p
     '(((S nil (S a S b) (a)) (S nil (S a S b) (e)) (S nil nil (a)) (S nil nil (e)) (Sp nil (S) (e))) ((S (S) (a S b) (a)) (S (S) (a S b) (e)) (Sp (S) nil (e))) ((S (S a) (S b) (a)) (S (S a) (S b) (e)) (S nil (S a S b) (a)) (S nil (S a S b) (b)) (S nil nil (a)) (S nil nil (b))) ((S (S) (a S b) (a)) (S (S) (a S b) (b)) (S (S a S) (b) (a)) (S (S a S) (b) (e))) ((S (S a S b) nil (a)) (S (S a S b) (a) (a)) (S (S a S b) nil (e))) ((S (S a) (S b) (a)) (S (S a) (S b) (b)) (S nil (S a S b) (a)) (S nil (S a S b) (b)) (S nil nil (a)) (S nil nil (b))) ((S (S) (a S b) (a)) (S (S) (a S b) (b)) (S (S a S) (b) (a)) (S (S a S) (b) (b))) ((S (S a S b) nil (a)) (S (S a S b) nil (b)))))))

  (message "Passed tests for (parser-generator-lr--items-valid-p)"))

(defun parser-generator-lr-test-parse ()
  "Test `parser-generator-lr-parse'."
  (message "Started tests for (parser-generator-lr-parse)")

  (parser-generator-set-grammar
   '((Sp S) (a b) ((Sp S) (S (S a S b)) (S e)) Sp))
  (parser-generator-set-look-ahead-number 1)
  (parser-generator-process-grammar)
  (parser-generator-lr-generate-parser-tables)
  (setq
   parser-generator-lex-analyzer--function
   (lambda (index)
     (let* ((string '((a 1 . 2) (a 2 . 3) (b 3 . 4) (b 4 . 5)))
            (string-length (length string))
            (max-index index)
            (tokens))
       (while (and
               (< (1- index) string-length)
               (< (1- index) max-index))
         (push (nth (1- index) string) tokens)
         (setq index (1+ index)))
       (nreverse tokens))))
  (should
   (equal
    '(2 2 2 1 1)
    (parser-generator-lr-parse)))
  (message "Passed test with terminals as symbols")

  (setq
   parser-generator-lex-analyzer--function
   (lambda (index)
     (let* ((string '((a 1 . 2) (a 2 . 3) (b 3 . 4) (b 4 . 5) (b 5 . 6)))
            (string-length (length string))
            (max-index index)
            (tokens))
       (while (and
               (< (1- index) string-length)
               (< (1- index) max-index))
         (push (nth (1- index) string) tokens)
         (setq index (1+ index)))
       (nreverse tokens))))
  (should-error
   (parser-generator-lr--parse))
  (message "Passed test with terminals as symbols, invalid syntax")

  (parser-generator-set-grammar '((Sp S) ("a" "b") ((Sp S) (S (S "a" S "b")) (S e)) Sp))
  (parser-generator-set-look-ahead-number 1)
  (parser-generator-process-grammar)
  (let ((lr-items (parser-generator-lr-generate-parser-tables)))
    (parser-generator--debug
     (message "lr-items: %s" (parser-generator--hash-values-to-list lr-items t)))
    )
  (parser-generator--debug
   (message "goto-tables: %s" (parser-generator--hash-values-to-list parser-generator-lr--goto-tables t))
   (message "action-tables: %s" (parser-generator--hash-values-to-list parser-generator-lr--action-tables t)))
  (setq
   parser-generator-lex-analyzer--function
   (lambda (index)
     (let* ((string '(("a" 1 . 2) ("a" 2 . 3) ("b" 3 . 4) ("b" 4 . 5)))
            (string-length (length string))
            (max-index index)
            (tokens))
       (while (and
               (< (1- index) string-length)
               (< (1- index) max-index))
         (push (nth (1- index) string) tokens)
         (setq index (1+ index)))
       (nreverse tokens))))
  (should
   (equal
    '(2 2 2 1 1)
    (parser-generator-lr-parse)))
  (message "Passed test with terminals as string")

  (setq
   parser-generator-lex-analyzer--function
   (lambda (index)
     (let* ((string '(("a" 1 . 2) ("a" 2 . 3) ("b" 3 . 4) ("b" 4 . 5) ("b" 5 . 6)))
            (string-length (length string))
            (max-index index)
            (tokens))
       (while (and
               (< (1- index) string-length)
               (< (1- index) max-index))
         (push (nth (1- index) string) tokens)
         (setq index (1+ index)))
       (nreverse tokens))))
  (should-error
   (parser-generator-lr--parse))
  (message "Passed test with terminals as string, invalid syntax")

  (setq
   parser-generator-lex-analyzer--function
   (lambda (index)
     (let* ((string '(("a" 1 . 2) ("a" 2 . 3) ("b" 3 . 4) ("b" 4 . 5)))
            (string-length (length string))
            (max-index index)
            (tokens))
       (while (and
               (< (1- index) string-length)
               (< (1- index) max-index))
         (push (nth (1- index) string) tokens)
         (setq index (1+ index)))
       (nreverse tokens))))

  (parser-generator-lr-test--parse-incremental-vs-regular)
  (message "Passed incremental-tests")

  (message "Passed tests for (parser-generator-lr--parse)"))

(defun parser-generator-lr-test-parse-k-2 ()
  "Test `parser-generator-lr-parse' with k = 2."
  (message "Started tests for (parser-generator-lr-parse) k = 2")

  ;; https://stackoverflow.com/questions/62075086/what-is-an-lr2-parser-how-does-it-differ-from-an-lr1-parser
  ;; S → RS | R
  ;; R → abT
  ;; T → aT | c | ε

  (parser-generator-set-grammar
   '((Sp S R T) (a b c) ((Sp S) (S (R S) (R)) (R (a b T)) (T (a T) (c) (e))) Sp))
  (parser-generator-set-look-ahead-number 2)
  (parser-generator-process-grammar)

  (let ((lr-items (parser-generator-lr--generate-goto-tables)))
    (parser-generator--debug
     (message
      "LR-items: %s"
      (parser-generator--hash-to-list
       lr-items)))

    ;;     (1)
    ;;     S' -> .S   [$$]  // Go to 10
    ;;     S  -> .R   [$$]  // Go to 8
    ;;     S  -> .RS  [$$]  // Go to 8
    ;;     R  -> .abT [$$]  // Shift  on ab, go to (2)
    ;;     R  -> .abT [ab]  // Shift  on ab, go to (2)

    ;; (2)
    ;;     R  -> a.bT [$$]  // Shift  on ba, bc, b$, go to (3)
    ;;     R  -> a.bT [ab]  // Shift  on ba, bc,     go to (3)

    ;; (3)
    ;;     R  -> ab.T [$$] // Go to 7
    ;;     R  -> ab.T [ab] // Go to 7
    ;;     T  -> .aT  [$$] // Shift  on aa, ac, a$, go to (4)
    ;;     T  -> .c   [$$] // Shift  on c$,         go to (5)
    ;;     T  -> .    [$$] // Reduce on $$
    ;;     T  -> .aT  [ab] // Shift  on aa, ac,     go to (4)
    ;;     T  -> .c   [ab] // Shift  on ca,         go to (5)
    ;;     T  -> .    [ab] // Reduce on ab

    ;; (4)
    ;;     T  -> a.T  [$$] // Go to 6
    ;;     T  -> a.T  [ab] // Go to 6
    ;;     T  -> .    [$$] // Reduce on $$
    ;;     T  -> .aT  [$$] // Shift  on aa, ac, a$, go to (4)
    ;;     T  -> .c   [$$] // Shift  on c$,         go to (5)
    ;;     T  -> .    [ab] // Reduce on ab
    ;;     T  -> .aT  [ab] // Shift  on aa, ac,     go to (4)
    ;;     T  -> .c   [ab] // Shift  on ca,         go to (5)

    ;; (5)
    ;;     T  -> c.   [$$] // Reduce on $$
    ;;     T  -> c.   [ab] // Reduce on ab

    ;; (6)
    ;;     T  -> aT.  [$$] // Reduce on $$ 
    ;;     T  -> aT.  [ab] // Reduce on ab

    ;; (7)
    ;;     R  -> abT. [$$] // Reduce on $$
    ;;     R  -> abT. [ab] // Reduce on ab

    ;; (8)
    ;;     S  -> R.   [$$] // Reduce on $$
    ;;     S  -> R.S  [$$] // Go to 9
    ;;     S  -> .RS  [$$] // Go to 8
    ;;     S  -> .R   [$$] // Go to 8
    ;;     R  -> .abT [$$] // Shift  on ab, go to (2)
    ;;     R  -> .abT [ab] // Shift  on ab, go to (2)

    ;; (9)
    ;;     S  -> RS.  [$$] // Reduce on $$

    ;; (10)
    ;;     S' -> S.   [$$] // Accept on $$

    (should
     (equal
      '((0 (
            ((R) nil (a b T) ($ $))
            ((R) nil (a b T) (a b))
            ((S) nil (R) ($ $))
            ((S) nil (R S) ($ $))
            ((Sp) nil (S) ($ $))
            ))
        (1 (
            ((R) nil (a b T) ($ $))
            ((R) nil (a b T) (a b))
            ((S) (R) (S) ($ $))
            ((S) (R) nil ($ $))
            ((S) nil (R) ($ $))
            ((S) nil (R S) ($ $))))
        (2 (
            ((Sp) (S) nil ($ $))))
        (3 (
            ((R) (a) (b T) ($ $))
            ((R) (a) (b T) (a b))
            ))
        (4 (
            ((R) (a b) (T) ($ $))
            ((R) (a b) (T) (a b))
            ((T) nil (a T) ($ $))
            ((T) nil (a T) (a b))
            ((T) nil (c) ($ $))
            ((T) nil (c) (a b))
            ((T) nil nil ($ $))
            ((T) nil nil (a b))
            ))
        (5 (
            ((R) (a b T) nil ($ $))
            ((R) (a b T) nil (a b))
            ))
        (6 (
            ((T) (a) (T) ($ $))
            ((T) (a) (T) (a b))
            ((T) nil (a T) ($ $))
            ((T) nil (a T) (a b))
            ((T) nil (c) ($ $))
            ((T) nil (c) (a b))
            ((T) nil nil ($ $))
            ((T) nil nil (a b))
            ))
        (7 (
            ((T) (c) nil ($ $))
            ((T) (c) nil (a b))
            ))
        (8 (
            ((T) (a T) nil ($ $))
            ((T) (a T) nil (a b))))
        (9 (
            ((S) (R S) nil ($ $)))))
      (parser-generator--hash-to-list
       lr-items)))
    (message "Passed LR-items k = 2")

    (parser-generator--debug
     (message "GOTO-tables k = 2: %s"
              (parser-generator--hash-to-list
               parser-generator-lr--goto-tables
               t)))

    ;; state |  a  |  b  |  c  |  $  |  S  |  R  |  T
    ;; -------+-----+-----+-----+-----+-----+-----+-----
    ;;    1   |  2  |     |     |     |  10 |  8  |
    ;; -------+-----+-----+-----+-----+-----+-----+-----
    ;;    2   |     |  3  |     |     |     |     |
    ;; -------+-----+-----+-----+-----+-----+-----+-----
    ;;    3   |  4  |     |  5  |     |     |     |  7
    ;; -------+-----+-----+-----+-----+-----+-----+-----
    ;;    4   |  4  |     |  5  |     |     |     |  6
    ;; -------+-----+-----+-----+-----+-----+-----+-----
    ;;    5   |     |     |     |     |     |     |
    ;; -------+-----+-----+-----+-----+-----+-----+-----
    ;;    6   |     |     |     |     |     |     |
    ;; -------+-----+-----+-----+-----+-----+-----+-----
    ;;    7   |     |     |     |     |     |     |
    ;; -------+-----+-----+-----+-----+-----+-----+-----
    ;;    8   |  2  |     |     |     |  9  |  8  |
    ;; -------+-----+-----+-----+-----+-----+-----+-----
    ;;    9   |     |     |     |     |     |     |
    ;; -------+-----+-----+-----+-----+-----+-----+-----
    ;;    10  |     |     |     |     |     |     |

    (should
     (equal
      '((0 ((R 1) (S 2) (a 3)))
        (1 ((R 1) (S 9) (a 3)))
        (2 nil)
        (3 ((b 4)))
        (4 ((T 5) (a 6) (c 7)))
        (5 nil)
        (6 ((T 8) (a 6) (c 7)))
        (7 nil)
        (8 nil)
        (9 nil))
      (parser-generator--hash-to-list
       parser-generator-lr--goto-tables)))
    (message "Passed GOTO-tables k = 2")

    (parser-generator-lr--generate-action-tables
     lr-items)
    (parser-generator--debug
     (message
      "Action-tables k = 2: %s"
      (parser-generator--hash-values-to-list parser-generator-lr--action-tables t)))

    ;; TODO Validate action-table here, should be able to reduce at look-ahead ("a" "b") as well

    ;; (should
    ;;  (equal
    ;;   '((0 ((("a" "a") reduce 2) (("a" e) reduce 2) ((e e) reduce 2)))
    ;;     (1 ((("a" "b") shift) ((e e) accept)))
    ;;     (2 ((("a" "a") reduce 2) (("a" e) reduce 2) (("b" e) reduce 2)))
    ;;     (3 ((("a" "b") shift) (("b" e) shift) (("b" "a") shift)))
    ;;     (4 ((("a" "a") reduce 2) (("a" e) reduce 2) (("b" e) reduce 2)))
    ;;     (5 ((("a" "a") reduce 1) (("a" e) reduce 1) ((e e) reduce 1)))
    ;;     (6 ((("a" "b") shift) (("b" "b") shift) (("b" "a") shift)))
    ;;     (7 ((("a" "a") reduce 1) (("a" e) reduce 1) (("b" e) reduce 1))))
    ;;   (parser-generator--hash-to-list
    ;;    parser-generator-lr--action-tables)))
    ;; (message "Passed ACTION-tables k = 2")

    )
  (setq
   parser-generator-lex-analyzer--function
   (lambda (index)
     (let* ((string '(("a" 1 . 2) ("b" 2 . 3)))
            (string-length (length string))
            (max-index index)
            (tokens))
       (while (and
               (< (1- index) string-length)
               (< (1- index) max-index))
         (push (nth (1- index) string) tokens)
         (setq index (1+ index)))
       (nreverse tokens))))
  (should
   (equal
    '(2 2 2 1 1)
    (parser-generator-lr-parse)))
  (message "Passed test with terminals as string with look-ahead-number 2")

  (message "Passed tests for (parser-generator-lr--parse-k-2)"))

(defun parser-generator-lr-test-translate ()
  "Test `parser-generator-lr-translate'."
  (message "Started tests for (parser-generator-lr-translate)")

  ;; Test translation with terminals as strings here

  (let ((buffer (generate-new-buffer "*a*")))
    (switch-to-buffer buffer)
    (insert "aabb")

    (parser-generator-set-grammar '((Sp S) ("a" "b") ((Sp S) (S (S "a" S "b" (lambda(args) (let ((list "")) (dolist (item args) (when item (setq list (format "%s%s" item list)))) list)))) (S e)) Sp))
    (parser-generator-set-look-ahead-number 1)
    (parser-generator-process-grammar)
    (parser-generator-lr-generate-parser-tables)

    (setq
     parser-generator-lex-analyzer--function
     (lambda (index)
       (with-current-buffer buffer
         (when (<= (+ index 1) (point-max))
           (let ((start index)
                 (end (+ index 1)))
             (let ((token (buffer-substring-no-properties start end)))
               `(,token ,start . ,end)))))))

    (setq
     parser-generator-lex-analyzer--get-function
     (lambda (token)
       (with-current-buffer buffer
         (let ((start (car (cdr token)))
               (end (cdr (cdr token))))
           (when (<= end (point-max))
             (buffer-substring-no-properties start end))))))

    (should
     (equal
      "bbaaba"
      (parser-generator-lr-translate)))

    (kill-buffer buffer))
  (message "Passed test with translation 1")

  (let ((buffer (generate-new-buffer "*a*")))
    (switch-to-buffer buffer)
    (insert "if (a) { b; }")

    (parser-generator-set-grammar '((Sp S) (";" OPEN_ROUND_BRACKET CLOSE_ROUND_BRACKET ECHO IF OPEN_CURLY_BRACKET CLOSE_CURLY_BRACKET VARIABLE) ((Sp S) (S (IF OPEN_ROUND_BRACKET VARIABLE CLOSE_ROUND_BRACKET OPEN_CURLY_BRACKET VARIABLE ";" CLOSE_CURLY_BRACKET (lambda(args) (format "(when %s %s)" (nth 2 args) (nth 5 args)))))) Sp))
    (parser-generator-set-look-ahead-number 1)
    (parser-generator-process-grammar)
    (parser-generator-lr-generate-parser-tables)

    (setq
     parser-generator-lex-analyzer--function
     (lambda (index)
       (with-current-buffer buffer
         (unless (>= index (point-max))
           (goto-char index)
           (unless (looking-at "[^ \n\t]")
             (search-forward-regexp "[^ \n\t]" nil t nil)
             (forward-char -1))
           (let ((token))
             (cond
              ((looking-at "if")
               (setq token `(IF ,(match-beginning 0) . ,(match-end 0))))
              ((looking-at "echo")
               (setq token `(ECHO ,(match-beginning 0) . ,(match-end 0))))
              ((looking-at "(")
               (setq token `(OPEN_ROUND_BRACKET ,(match-beginning 0) . ,(match-end 0))))
              ((looking-at ")")
               (setq token `(CLOSE_ROUND_BRACKET ,(match-beginning 0) . ,(match-end 0))))
              ((looking-at "{")
               (setq token `(OPEN_CURLY_BRACKET ,(match-beginning 0) . ,(match-end 0))))
              ((looking-at "}")
               (setq token `(CLOSE_CURLY_BRACKET ,(match-beginning 0) . ,(match-end 0))))
              ((looking-at ";")
               (setq token `(";" ,(match-beginning 0) . ,(match-end 0))))
              ((looking-at "[a-zA-Z]+")
               (setq token `(VARIABLE ,(match-beginning 0) . ,(match-end 0))))
              (t (error "Invalid syntax! Could not lex-analyze at %s!" (point))))
             token)))))

    (setq
     parser-generator-lex-analyzer--get-function
     (lambda (token)
       (with-current-buffer buffer
         (let ((start (car (cdr token)))
               (end (cdr (cdr token))))
           (when (<= end (point-max))
             (buffer-substring-no-properties start end))))))

    (should
     (equal
      "(when a b)"
      (parser-generator-lr-translate)))
    (message "Passed test with non-nested translation")

    (switch-to-buffer buffer)
    (kill-region (point-min) (point-max))

    (parser-generator-set-grammar '((Sp S T) (";" OPEN_ROUND_BRACKET CLOSE_ROUND_BRACKET ECHO IF OPEN_CURLY_BRACKET CLOSE_CURLY_BRACKET VARIABLE) ((Sp S) (S (IF OPEN_ROUND_BRACKET VARIABLE CLOSE_ROUND_BRACKET OPEN_CURLY_BRACKET T CLOSE_CURLY_BRACKET (lambda(args) (format "(when %s %s)" (nth 2 args) (nth 5 args))))) (T (ECHO VARIABLE ";" (lambda(args) (format "(message %s)" (nth 1 args)))) (VARIABLE ";" (lambda(args) (format "%s" (nth 0 args)))))) Sp))
    (parser-generator-set-look-ahead-number 1)
    (parser-generator-process-grammar)
    (parser-generator-lr-generate-parser-tables)

    (insert "if (a) { echo b; }")

    (should
     (equal
      "(when a (message b))"
      (parser-generator-lr-translate)))

    (message "Passed test with nested-translation with depth 2")

    (switch-to-buffer buffer)
    (kill-region (point-min) (point-max))
    (goto-char 1)
    (insert "if (a) { echo b }")

    (should-error
     (parser-generator-lr-parse))

    (kill-buffer buffer))
  (message "Passed test with translation 2")

  (let ((buffer (generate-new-buffer "*a*")))
    (switch-to-buffer buffer)
    (insert "if (a) { b; }")

    (parser-generator-set-grammar '((Sp S) (";" OPEN_ROUND_BRACKET CLOSE_ROUND_BRACKET IF OPEN_CURLY_BRACKET CLOSE_CURLY_BRACKET VARIABLE) ((Sp S) (S (IF OPEN_ROUND_BRACKET VARIABLE CLOSE_ROUND_BRACKET OPEN_CURLY_BRACKET VARIABLE ";" CLOSE_CURLY_BRACKET (lambda(args) (format "(when %s %s)" (nth 2 args) (nth 5 args)))))) Sp))
    (parser-generator-set-look-ahead-number 1)
    (parser-generator-process-grammar)
    (parser-generator-lr-generate-parser-tables)

    (setq
     parser-generator-lex-analyzer--function
     (lambda (index)
       (with-current-buffer "*a*"
         (unless (>= index (point-max))
           (goto-char index)
           (unless (looking-at "[^ \n\t]")
             (search-forward-regexp "[^ \n\t]" nil t nil)
             (forward-char -1))
           (let ((token))
             (cond
              ((looking-at "if")
               (setq token `(IF ,(match-beginning 0) . ,(match-end 0))))
              ((looking-at "(")
               (setq token `(OPEN_ROUND_BRACKET ,(match-beginning 0) . ,(match-end 0))))
              ((looking-at ")")
               (setq token `(CLOSE_ROUND_BRACKET ,(match-beginning 0) . ,(match-end 0))))
              ((looking-at "{")
               (setq token `(OPEN_CURLY_BRACKET ,(match-beginning 0) . ,(match-end 0))))
              ((looking-at "}")
               (setq token `(CLOSE_CURLY_BRACKET ,(match-beginning 0) . ,(match-end 0))))
              ((looking-at ";")
               (setq token `(";" ,(match-beginning 0) . ,(match-end 0))))
              ((looking-at "[a-zA-Z]+")
               (setq token `(VARIABLE ,(match-beginning 0) . ,(match-end 0))))
              (t (error "Invalid syntax! Could not lex-analyze at %s!" (point))))
             token)))))

    (setq
     parser-generator-lex-analyzer--get-function
     (lambda (token)
       (with-current-buffer "*a*"
         (let ((start (car (cdr token)))
               (end (cdr (cdr token))))
           (when (<= end (point-max))
             (buffer-substring-no-properties start end))))))

    (parser-generator-lr-test--parse-incremental-vs-regular)
    (kill-buffer buffer))

  (message "Passed incremental tests")

  (message "Passed tests for (parser-generator-lr-translate)"))

(defun parser-generator-lr-test ()
  "Run test."
  ;; (setq debug-on-error t)

  (parser-generator-lr-test--items-for-prefix)
  (parser-generator-lr-test--items-valid-p)
  (parser-generator-lr-test--generate-goto-tables)
  (parser-generator-lr-test--generate-action-tables)
  (parser-generator-lr-test-parse)
  (parser-generator-lr-test-translate)
  (parser-generator-lr-test-parse-k-2))


(provide 'parser-generator-lr-test)

;;; parser-generator-lr-test.el ends here
