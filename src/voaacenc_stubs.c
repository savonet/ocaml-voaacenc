/*
 * OCaml bindings for libvo-aacenc
 *
 * Copyright 2005-2010 Savonet team
 *
 * This file is part of ocaml-vo-aacenc.
 *
 * ocaml-vo-aacenc is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * ocaml-vo-aacenc is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with ocaml-vo-aacenc; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

 /* OCaml bindings for the libvo-aacenc library. */

#include <caml/custom.h>
#include <caml/signals.h>
#include <caml/misc.h>
#include <caml/memory.h>
#include <caml/fail.h>
#include <caml/callback.h>
#include <caml/alloc.h>

#include <vo-aacenc/voAAC.h>
#include <vo-aacenc/cmnMemory.h>

#include <stdint.h>
#include <string.h>

/* Not all errors seem to be used
 * so we only check the one that 
 * appear relevant.. */
static void check_for_err(int ret)
{
  switch(-ret)
  {
    case VO_ERR_NONE:
      return;

    case VO_ERR_FAILED:
      caml_raise_constant(*caml_named_value("voaacenc_exn_failed"));
      break;

    case VO_ERR_OUTOF_MEMORY:
      caml_raise_out_of_memory();
      break;

    case VO_ERR_NOT_IMPLEMENT:
      caml_raise_constant(*caml_named_value("voaacenc_exn_not_implemented"));
      break;

    case VO_ERR_INVALID_ARG:
      caml_raise_constant(*caml_named_value("voaacenc_exn_invalid_arg"));
      break;

    case VO_ERR_INPUT_BUFFER_SMALL:
      caml_raise_constant(*caml_named_value("voaacenc_exn_input_buffer_small"));
      break;

    case VO_ERR_OUTPUT_BUFFER_SMALL:
      caml_raise_constant(*caml_named_value("voaacenc_exn_output_buffer_small"));
      break;

    default:
      caml_raise_with_arg(*caml_named_value("voaacenc_exn_unknown_error"), Val_int(ret));
      break;
  }
}

typedef struct encoder_t
{
  VO_AUDIO_CODECAPI codec_api;
  AACENC_PARAM params;
  VO_HANDLE handle;
  VO_MEM_OPERATOR mem_operator;
  VO_CODEC_INIT_USERDATA user_data;
} encoder_t;

#define Encoder_val(v) (*((encoder_t**)Data_custom_val(v)))

static void finalize_encoder(value e)
{
  encoder_t *enc = Encoder_val(e);
  enc->codec_api.Uninit(enc->handle);
  free(enc);
}

static struct custom_operations encoder_ops =
{
  "ocaml_voaac_encoder",
  finalize_encoder,
  custom_compare_default,
  custom_hash_default,
  custom_serialize_default,
  custom_deserialize_default
};

CAMLprim value ocaml_voaacenc_channels_of_encoder(value _enc)
{
  CAMLparam1(_enc);
  encoder_t *enc = Encoder_val(_enc);
  CAMLreturn(Val_int(enc->params.nChannels));
}

CAMLprim value ocaml_voaacenc_init_enc(value chans, value samplerate, value bitrate, value adts)
{
  CAMLparam0();
  CAMLlocal1(ans);

  encoder_t *enc = malloc(sizeof(encoder_t));
  if (enc == NULL) 
    caml_raise_out_of_memory();

  enc->params.sampleRate = Int_val(samplerate);
  enc->params.bitRate = Int_val(bitrate);
  enc->params.nChannels = Int_val(chans);
  enc->params.adtsUsed = Int_val(adts);

  enc->mem_operator.Alloc = cmnMemAlloc;
  enc->mem_operator.Copy = cmnMemCopy;
  enc->mem_operator.Free = cmnMemFree;
  enc->mem_operator.Set = cmnMemSet;
  enc->mem_operator.Check = cmnMemCheck;
  enc->user_data.memflag = VO_IMF_USERMEMOPERATOR;
  enc->user_data.memData = &(enc->mem_operator);

  voGetAACEncAPI(&(enc->codec_api));
  enc->codec_api.Init(&(enc->handle), VO_AUDIO_CodingAAC, &(enc->user_data));

  int ret = enc->codec_api.SetParam(enc->handle, VO_PID_AAC_ENCPARAM, &(enc->params)) ;
  if (ret != VO_ERR_NONE) {
    free(enc);
    check_for_err(ret);
  }

  ans = caml_alloc_custom(&encoder_ops, sizeof(encoder_t *), 1, 0);
  Encoder_val(ans) = enc;   

  CAMLreturn(ans);
}

CAMLprim value ocaml_voaacenc_encode(value e, value data, value ofs, value len)
{
  CAMLparam2(e,data);
  CAMLlocal2(ret,ans);

  encoder_t *enc = Encoder_val(e);

  VO_CODECBUFFER input, output;
  VO_AUDIO_OUTPUTINFO output_info;

  input.Buffer = malloc(Int_val(len));
  if (input.Buffer == NULL)
    caml_raise_out_of_memory();
  memcpy(input.Buffer,String_val(data)+Int_val(ofs),Int_val(len));
  input.Length = Int_val(len);

  caml_enter_blocking_section();
  enc->codec_api.SetInputData(enc->handle, &input);
  caml_leave_blocking_section();

  uint8_t outbuf[20480];
  output.Buffer = outbuf;
  output.Length = sizeof(outbuf);
  
  caml_enter_blocking_section();
  int err = enc->codec_api.GetOutputData(enc->handle, &output, &output_info);
  caml_leave_blocking_section();

  free(input.Buffer);

  if (err != VO_ERR_NONE)
    check_for_err(err);

  ans = caml_alloc_string(output.Length);
  memcpy(String_val(ans), output.Buffer, output.Length);

  ret = caml_alloc_tuple(2);
  Store_field(ret,0,ans);
  Store_field(ret,1,Val_int(output_info.InputUsed));

  CAMLreturn(ret);
}
