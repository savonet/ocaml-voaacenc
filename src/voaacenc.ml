(*
 * Copyright 2003-2010 Savonet team
 *
 * This file is part of Ocaml-vo-aacenc.
 *
 * Ocaml-vo-aacenc is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * Ocaml-vo-aacenc is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Ocaml-vo-aacenc; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *)

 (** OCaml bindings for the libvo-aacenc. *)

exception Failed
exception Not_implemented
exception Invalid_voaacenc_argument
exception Input_buffer_too_small
exception Output_buffer_too_small
exception Unknown of int

let () =
  Callback.register_exception "aacplus_exn_failed" Failed;
  Callback.register_exception "aacplus_exn_not_implemented" Not_implemented;
  Callback.register_exception "aacplus_exn_invalid_arg" Invalid_voaacenc_argument;
  Callback.register_exception "aacplus_exn_input_buffer_small" Input_buffer_too_small;
  Callback.register_exception "aacplus_exn_output_buffer_small" Output_buffer_too_small;
  Callback.register_exception "aacplus_exn_unknown_error" (Unknown 0)

let string_of_exception = 
  function 
     | Failed -> Some "Generic failure"
     | Not_implemented -> Some "Operation not implemented"
     | Invalid_voaacenc_argument -> Some "Invalid argument"
     | Input_buffer_too_small -> Some "Input buffer too small"
     | Output_buffer_too_small -> Some "Output buffer too small. \
                                   This error should not happen, \
                                   please report it"
     | Unknown x -> Some (Printf.sprintf "Unknown error %i. \
                                    Please repport it." x)
     | _ -> None

(* Dummy registration function for
 * user compiling with ocaml < 3.11.2 *)
let register_printer _ = ()

(* Now open Printexc,
 * overriding register_printer
 * if present *)
open Printexc

let () = register_printer string_of_exception

type t

type parameters = 
  { 
    samplerate : int;
    channels   : int;
    bitrate    : int;
    adts       : bool
  }


external create : int -> int -> int -> int -> t = "ocaml_voaacenc_init_enc"

let create params = 
  create params.channels params.samplerate 
       params.bitrate (Obj.magic params.adts)

external channels_of_encoder : t -> int = "ocaml_voaacenc_channels_of_encoder"

let recommended_minimum_input enc = (channels_of_encoder enc)*2*1024

external encode_substring : t -> string -> int -> int -> string*int = "ocaml_voaacenc_encode"

let encode_substring enc data start len = 
  if String.length data < start+len then
    raise (Invalid_argument "Voaacenc.encode_substring");
  if len > 0 then
    encode_substring enc data start len
  else
    "",0

let encode_string enc data = encode_substring enc data 0 (String.length data)

let encode_buffer enc buffer = 
  let minlen = recommended_minimum_input enc in
  let len = Buffer.length buffer in
  if len < minlen then
    ""
  else
   begin
    let encoded = Buffer.create 1024 in
    let s = Buffer.contents buffer in
    let rec f pos = 
      if len < pos+minlen then
       begin
        Buffer.reset buffer;
        Buffer.add_substring buffer s pos (len-pos) ;
        Buffer.contents encoded
       end
      else
       begin
        let ret,used = encode_substring enc s pos minlen in
        Buffer.add_string encoded ret ;
        f (pos+used)
       end
    in
    f 0
   end
