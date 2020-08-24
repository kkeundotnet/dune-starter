module F = Format

type t = {
  proj : string;
  proj_big : string;
  project_synopsis : string;
  author_name : string;
  author_email : string;
  github_id : string;
  target : string;
}

let pp
    {
      proj;
      proj_big;
      project_synopsis;
      author_name;
      author_email;
      github_id;
      target;
    } =
  F.fprintf F.std_formatter
    "Project name: %s (module %s)@\n\
     Project synopsis: %s@\n\
     Author name: %s@\n\
     Author email: %s@\n\
     GitHub ID: %s@\n\
     Target directory: %s@." proj proj_big project_synopsis author_name
    author_email github_id target

(* Replace *)

let replace from to_ line = Str.global_replace (Str.regexp_string from) to_ line

let replace_proj proj proj_big line =
  if line = "dune-project" then line
  else replace "proj" proj line |> replace "Proj" proj_big

let replace_rev
    {
      proj;
      proj_big;
      project_synopsis;
      author_name;
      author_email;
      github_id;
      target;
    } lines =
  let replace_line line =
    replace "project_name" proj line
    |> replace "project_synopsis" project_synopsis
    |> replace "author_name" author_name
    |> replace "author_email" author_email
    |> replace "github_id" github_id
    |> replace_proj proj proj_big
  in
  let rec replace_rev lines rev =
    match lines with
    | [] -> rev
    | line :: lines -> replace_rev lines (replace_line line :: rev)
  in
  replace_rev lines []

(* Ask *)

let rec ask title =
  print_string (title ^ ": ");
  flush_all ();
  let s = read_line () in
  if String.length s <= 0 then (
    print_endline (title ^ " cannot be empty.");
    ask title )
  else s

let rec ask_non_space title =
  let s = ask title in
  if String.contains s ' ' then (
    print_endline (title ^ " cannot include the space character.");
    ask_non_space title )
  else s

let rec ask_project_synopsis () =
  let s = ask "Project synopsis" in
  if
    Str.string_match (Str.regexp {|^[A-Z]|}) s 0
    && s.[String.length s - 1] != '.'
  then s
  else (
    print_endline "Synopsis should start with a capital and not end with a dot.";
    ask_project_synopsis () )

let rec ask_proj () =
  let s = ask_non_space "Project name" in
  if
    Str.string_match (Str.regexp {|^[a-z]+$|}) s 0
    || Str.string_match (Str.regexp {|^[a-z][a-z_-]+[a-z]$|}) s 0
  then s
  else (
    print_endline
      "Small alphabet letters, '-', and '_' are permited as a project name.";
    ask_proj () )

let get_big s =
  let buf = Buffer.create 20 in
  let dash = ref false in
  for i = 0 to String.length s - 1 do
    if i = 0 then Buffer.add_char buf (Char.uppercase_ascii s.[i])
    else if s.[i] = '-' then dash := true
    else if !dash then (
      dash := false;
      Buffer.add_char buf (Char.uppercase_ascii s.[i]) )
    else Buffer.add_char buf s.[i]
  done;
  Buffer.contents buf

let rec ask_directory () =
  let s = ask_non_space "Target directory" in
  if Sys.file_exists s then (
    print_endline "The target directory is already exists.";
    ask_directory () )
  else if String.contains s '~' then (
    let home = Unix.getenv "HOME" in
    assert (String.length home > 0);
    replace "~" home s )
  else s

(* Written by Jeffrey Scofield
   https://stackoverflow.com/questions/13410159/how-to-read-a-character-in-ocaml-without-a-return-key
   *)
let get1char () =
  let termio = Unix.tcgetattr Unix.stdin in
  let () =
    Unix.tcsetattr Unix.stdin Unix.TCSADRAIN
      { termio with Unix.c_icanon = false }
  in
  let res = input_char stdin in
  Unix.tcsetattr Unix.stdin Unix.TCSADRAIN termio;
  res

let rec is_this_ok () =
  print_string
    "Is the information correct? A new project will be initialized in the \
     target directory. [y/N] ";
  flush_all ();
  let c = get1char () in
  print_newline ();
  match c with
  | 'Y' | 'y' -> true
  | 'N' | 'n' | '\n' -> false
  | _ ->
      print_endline "Invalid input.";
      is_this_ok ()

let split_on_char_right c s =
  match String.rindex_opt s c with
  | None -> None
  | Some n ->
      Some (String.sub s 0 n, String.sub s (n + 1) (String.length s - (n + 1)))

(* Do init *)

let read_from_file_rev file =
  let ch = open_in file in
  let lines = ref [] in
  ( try
      while true do
        lines := input_line ch :: !lines
      done
    with End_of_file -> () );
  close_in ch;
  !lines

let write_to_file file lines =
  let ch = open_out file in
  List.iter
    (fun line ->
      output_string ch line;
      output_char ch '\n')
    lines;
  close_out ch

let cp_file v from to_ =
  print_endline ("F " ^ from ^ " -> " ^ to_);
  read_from_file_rev from |> replace_rev v |> write_to_file to_

let rec cp_dir v from to_ =
  print_endline ("D " ^ from ^ " -> " ^ to_);
  Unix.mkdir to_ 0o755;
  Sys.readdir from
  |> Array.iter (fun file ->
         let base = Filename.basename file in
         let from = Filename.concat from base in
         let to_ = Filename.concat to_ (replace_proj v.proj v.proj_big base) in
         if Sys.is_directory from then cp_dir v from to_ else cp_file v from to_)

let do_init v = cp_dir v "proj" v.target

let main () =
  let proj = ask_proj () in
  let proj_big = get_big proj in
  let project_synopsis = ask_project_synopsis () in
  let author_name = ask "Author name" in
  let author_email = ask_non_space "Author email" in
  let github_id = ask_non_space "GitHub ID" in
  let target = ask_directory () in
  let v =
    {
      proj;
      proj_big;
      project_synopsis;
      author_name;
      author_email;
      github_id;
      target;
    }
  in
  print_newline ();
  pp v;
  print_newline ();
  if is_this_ok () then do_init v else print_endline "No changes applied."

let () = main ()
