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

(** {1 AAC encoding module for OCaml} *)

(** {2 Exceptions} *)

exception Failed
exception Not_implemented
exception Invalid_voaacenc_argument
exception Input_buffer_too_small
exception Output_buffer_too_small
exception Unknown of int

val string_of_exception : exn -> string option

(** {2 Types} *)

type parameters =
  { 
    samplerate : int;
    channels   : int;
    bitrate    : int;
    adts       : bool
  }

type t

(** {2 Functions} *)

(** Create a new encoder. *)
val create : parameters -> t

(** Recommended minimun input to
  * feed to the decoder. *)
val recommended_minimum_input : t -> int

(** [encode_string enc data] encodes the
  * given S16LE pcm buffer and returns
  * AAC data and the number of input bytes 
  * consumed by the decoder. *)
val encode_string : t -> string -> string*int

(** [encode_substring enc data offset len] encodes
  * the sub-string of [data] starting at
  * position [offset] and of length [len].
  * Raises [Invalid_argument] if such sub-string
  * does not exist. *)
val encode_substring : t -> string -> int -> int -> string*int

(** [encode_buffer enc buffer] encodes S16LE
  * data from the string buffer [buffer] and 
  * drops consumed data from [buffer]. This
  * does nothing if [Buffer.length buffer < recommended_minumun_input enc] *)
val encode_buffer : t -> Buffer.t -> string

