let test_hello () =
  Alcotest.(check string) "hello" "Hello world!" Proj_lib.Proj.hello

let tests : unit Alcotest.test_case list = [ ("hello", `Quick, test_hello) ]
