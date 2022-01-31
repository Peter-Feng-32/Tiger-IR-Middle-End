(lang dune 2.0)

(name tigerirmiddleend)

(license ISC)

(authors "Peter Feng, Keshav Shenoy, Srikar Vanavasam")

(maintainers "Peter Feng, Keshav Shenoy, Srikar Vanavasam")

(generate_opam_files true)

(package
 (name tigerirmiddleend)
 (synopsis
  "Middle end of a compiler that performs static analysis and code optimization of Tiger-IR.  Intended for CS 4240.")
 (description
  "Middle end of a compiler that performs static analysis and code optimization of Tiger-IR.  Intended for CS 4240.")
 (depends
  (ocaml
   (>= 4.08.0))
  dune
  (alcotest :with-test)
  (odoc :with-doc)))
(using menhir 2.0)
