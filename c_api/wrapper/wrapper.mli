open! Base

module Format : sig
  type t =
    | Null
    | Boolean
    | Int8
    | Uint8
    | Int16
    | Uint16
    | Int32
    | Uint32
    | Int64
    | Uint64
    | Float16
    | Float32
    | Float64
    | Binary
    | Large_binary
    | Utf8_string
    | Large_utf8_string
    | Decimal128 of
        { precision : int
        ; scale : int
        }
    | Fixed_width_binary of { bytes : int }
    | Date32 of [ `days ]
    | Date64 of [ `milliseconds ]
    | Time32 of [ `seconds | `milliseconds ]
    | Time64 of [ `microseconds | `nanoseconds ]
    | Timestamp of
        { precision : [ `seconds | `milliseconds | `microseconds | `nanoseconds ]
        ; timezone : string
        }
    | Duration of [ `seconds | `milliseconds | `microseconds | `nanoseconds ]
    | Interval of [ `months | `days_time ]
    | Struct
    | Map
    | Unknown of string
  [@@deriving sexp]
end

module Reader : sig
  type t

  val read : string -> t
  val close : t -> unit
  val num_rows : t -> int
  val with_file : string -> f:(t -> 'a) -> 'a
end

module Schema : sig
  module Flags : sig
    type t [@@deriving sexp_of]

    val none : t
    val dictionary_ordered : t -> bool
    val nullable : t -> bool
    val map_keys_sorted : t -> bool
  end

  type t =
    { format : Format.t
    ; name : string
    ; metadata : (string * string) list
    ; flags : Flags.t
    ; children : t list
    }
  [@@deriving sexp_of]

  val get : Reader.t -> t
end

module Column : sig
  val read_i64_ba
    :  Reader.t
    -> column_idx:int
    -> (int64, Bigarray.int64_elt, Bigarray.c_layout) Bigarray.Array1.t

  val read_f64_ba
    :  Reader.t
    -> column_idx:int
    -> (float, Bigarray.float64_elt, Bigarray.c_layout) Bigarray.Array1.t

  val read_utf8 : Reader.t -> column_idx:int -> string array
  val read_date : Reader.t -> column_idx:int -> Core_kernel.Date.t array
  val read_time_ns : Reader.t -> column_idx:int -> Core_kernel.Time_ns.t array

  val read_i64_ba_opt
    :  Reader.t
    -> column_idx:int
    -> (int64, Bigarray.int64_elt, Bigarray.c_layout) Bigarray.Array1.t * Valid.t

  val read_f64_ba_opt
    :  Reader.t
    -> column_idx:int
    -> (float, Bigarray.float64_elt, Bigarray.c_layout) Bigarray.Array1.t * Valid.t

  val read_utf8_opt : Reader.t -> column_idx:int -> string option array
  val read_date_opt : Reader.t -> column_idx:int -> Core_kernel.Date.t option array
  val read_time_ns_opt : Reader.t -> column_idx:int -> Core_kernel.Time_ns.t option array
end

module Writer : sig
  type col

  val int64_ba
    :  (int64, Bigarray.int64_elt, Bigarray.c_layout) Bigarray.Array1.t
    -> name:string
    -> col

  val float64_ba
    :  (float, Bigarray.float64_elt, Bigarray.c_layout) Bigarray.Array1.t
    -> name:string
    -> col

  val utf8 : string array -> name:string -> col
  val date : Core_kernel.Date.t array -> name:string -> col
  val time_ns : Core_kernel.Time_ns.t array -> name:string -> col
  val write : ?chunk_size:int -> string -> cols:col list -> unit
end
