#lang racket
(require xml)

;;processing insruction
(define proc-inst (p-i 'racket
                       'racket
                       'xml
                       "version='1.0' standalone='no'"))

;prolog with SVG doc type declaration.
(define svg-prolog (prolog (list proc-inst)
                     (document-type
                      'svg
                      (external-dtd/public
                       "-//W3C//DTD SVG 1.1//EN"
                       "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd")
                      #f)
                     '()))
;
;;xexpr defs of xml elements 
;(define text-tag
;  '(text ((x "50") ;attributes
;          (y "120")
;          (font-size "80")
;          (font-family "Verdana")
;          (fill "aliceblue"))
;         "Racket")) ;content
;
;;<rect x="0" y="0" width="1500" height="1000" 
;;        fill="yellow" stroke="blue" stroke-width="12"  />
;
;(define rect1-tag
;  '(rect ((x "0")
;          (y "0")
;          (width "400")
;          (height "200")
;          (fill "navy"))))
;
;(define rect2-tag
;  '(rect ((x "25")
;          (y "30")
;          (width "340")
;          (height "140")
;          (fill "red"))))
;
;(define svg-body
;  (list 'svg
;         '((xmlns "http://www.w3.org/2000/svg")
;           (version "1.1")
;           (width "400px")
;           (height "200px")
;           (viewbox "0 0 400 200"))
;         rect1-tag
;         rect2-tag
;         text-tag))
;
;;complete xml document
;(define svg-doc (document
;                 svg-prolog ;doc prolog
;                 (xexpr->xml svg-body) ;doc body. xexpr to xml.
;                 '())) ;list of misc items
;
;(define out (open-output-file ".\\test.svg" #:exists 'replace))
;(write-xml svg-doc out)
;(close-output-port out)
;
;(define get-elements (xml->xexpr (document-element svg-doc)))
; ---------------------------------------------------------------

;;(define tst2 (match svg-doc
;;  [(struct document (prolog element misc)) element]
;;  [_ "test"]))
;;
;;(define tst3 (match tst2
;;  [(struct element (start stop name attributes content))
;;   (cons name attributes)]
;;  [_ "test"]))

(provide svg)
(define (svg)
  (let ((elements-list '())
        (svg-width 0)
        (svg-height 0))

    ;; Set svg width/height
    (define (set-wh width height)
      (set! svg-width width)
      (set! svg-height height))
    
    ;; Add shape to the elements-list
    (define (add-shape type param)
      (set! elements-list
            (append elements-list
                    (list (make-element type param)))))

    ;; Element object constructor
    ;; Takes "type" and "coords" of element
    (define (make-element type param)
      (let ((t type)
            (p param))
        (define (dispatch msg)
          (cond ((eq? msg 'get-param) p)
                ((eq? msg 'get-type) t)))
        dispatch))

    ;; ----------------------------------------------------------
    ;; svg-xml shape types
    (define num->str number->string)

    ; cx="50" cy="50" r="40"
    (define (mk-ellipse element)
      (let ((coords (element 'get-param)))
        (let ((cx (car coords))
              (cy (cadr coords))
              (rx (/ (- (caddr coords) (car coords)) 2.0))
              (ry (/ (- (cadddr coords) (cadr coords)) 2.0)))
      (list 'ellipse (list (list 'cx (num->str (+ cx rx)))
                           (list 'cy (num->str (+ cy ry)))
                           (list 'rx (num->str rx))
                           (list 'ry (num->str ry))
                           (list 'stroke "black")
                           (list 'stroke-width "2")
                           (list 'fill-opacity "0.0"))))))

    ; x1="0" y1="0" x2="200" y2="200"
    (define (mk-line element)
      (let ((coords (element 'get-param)))
        (let ((x1 (car coords))
              (y1 (cadr coords))
              (x2 (caddr coords))
              (y2 (cadddr coords)))
          (list 'line (list (list 'x1 (num->str x1))
                            (list 'y1 (num->str y1))
                            (list 'x2 (num->str x2))
                            (list 'y2 (num->str y2))
                            (list 'stroke "black")
                            (list 'stroke-width "2"))))))
    ;; ----------------------------------------------------------
    
    ; svg-body
    (define (mk-svg-body body-elements)
      (append (list 'svg
                    (list (list 'xmlns "http://www.w3.org/2000/svg")
                          (list 'version "1.1")
                          (list 'width (string-append (num->str svg-width) "px"))
                          (list 'height (string-append (num->str svg-height) "px"))))
;                          (list 'viewbox (string-append "0 0 "
;                                                        (num->str svg-width)
;                                                        " "
;                                                        (num->str svg-height)))))
              body-elements))
    
    ; generate xml body elements list
    (define (mk-body-elements)
      (map (λ(element) (cond ((eq? (element 'get-type) 'line)
                              (mk-line element))
                             ((eq? (element 'get-type) 'ellipse)
                              (mk-ellipse element)))) elements-list))
              
       ; xml-document
    (define (mk-svg-doc) (document
                          svg-prolog ;doc prolog
                          (xexpr->xml (mk-svg-body (mk-body-elements))) ;doc body. xexpr to xml.
                          '())) ;list of misc items
    
    ; Save svg
    (define (save-svg path)
      (define out (open-output-file path #:exists 'replace))
      (write-xml (mk-svg-doc) out)
      (close-output-port out))
       
       
    ;; Dispatch
    (define (dispatch msg)
      (cond ((eq? msg 'add-shape) add-shape)

            ((eq? msg 'get-e-list) elements-list)

            ((eq? msg 'set-wh) set-wh)
            
            ((eq? msg 'save) save-svg)))
    dispatch))