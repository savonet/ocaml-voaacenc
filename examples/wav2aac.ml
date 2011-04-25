(*
 * Copyright 2003 Savonet team
 *
 * This file is part of OCaml-Vorbis.
 *
 * OCaml-Vorbis is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * OCaml-Vorbis is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with OCaml-Vorbis; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *)

(**
  * An wav to ogg converter using OCaml-Vorbis.
  *
  * @author Samuel Mimram, and many others...
  *)

(* $Id$ *)

open Unix

let src = ref ""
let dst = ref ""

let buflen = ref 1024

let input_string chan len =
  let ans = String.create len in
    (* TODO: check length *)
    ignore (input chan ans 0 len) ;
    ans

let input_int chan =
  let buf = input_string chan 4 in
    (int_of_char buf.[0])
    + (int_of_char buf.[1]) lsl 8
    + (int_of_char buf.[2]) lsl 16
    + (int_of_char buf.[3]) lsl 24

let input_short chan =
  let buf = input_string chan 2 in
    (int_of_char buf.[0]) + (int_of_char buf.[1]) lsl 8

let bitrate = ref 64000
let usage = "usage: wav2aac [options] source destination"

let _ =
  Arg.parse
    [
      "--bitrate", Arg.Int (fun b -> bitrate := b * 1000),
      "Bitrate, in kilobits per second, defaults to 64kbps"
    ]
    (
      let pnum = ref (-1) in
        (fun s -> incr pnum; match !pnum with
           | 0 -> src := s
           | 1 -> dst := s
           | _ -> Printf.eprintf "Error: too many arguments\n"; exit 1
        )
    ) usage;
  if !src = "" || !dst = "" then
    (
      Printf.printf "%s\n" usage;
      exit 1
    );
  let ic = open_in_bin !src in
  let oc = open_out_bin !dst in
    (* TODO: improve! *)
    if input_string ic 4 <> "RIFF" then invalid_arg "No RIFF tag";
    ignore (input_string ic 4);
    if input_string ic 4 <> "WAVE" then invalid_arg "No WAVE tag";
    if input_string ic 4 <> "fmt " then invalid_arg "No fmt tag";
    let _ = input_int ic in
    let _ = input_short ic in (* TODO: should be 1 *)
    let channels = input_short ic in
    let infreq = input_int ic in
    let _ = input_int ic in (* bytes / s *)
    let _ = input_short ic in (* block align *)
    let bits = input_short ic in
    let enc = 
      Voaacenc.create  
       { Voaacenc.
          samplerate = infreq;
          channels = channels;
          bitrate = !bitrate;
          adts = true }
    in
    let buflen = Voaacenc.recommended_minimum_input enc in
    let data = Buffer.create buflen in
    let start = Unix.time () in
      Printf.printf
        "Input detected: PCM WAVE %d channels, %d Hz, %d bits\n%!"
        channels infreq bits;
      Printf.printf
        "Encoding to: AAC %d channels, %d Hz, %d kbps\nPlease wait...\n%!"
        channels infreq (!bitrate/1000);
      if input_string ic 4 <> "data" then invalid_arg "No data tag";
        begin try while true do
          let buf = String.create buflen in
          really_input ic buf 0 buflen;
          Buffer.add_string data buf;
          let ret = Voaacenc.encode_buffer enc data in
          output_string oc ret;
        done;
        with End_of_file -> () end;
        close_in ic;
        close_out oc;
        Printf.printf "Finished in %.0f seconds.\n" ((Unix.time ())-.start);
        Gc.full_major ()
