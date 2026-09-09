// RUN: bishengir-opt -pass-pipeline="builtin.module(func.func(hivm-cross-core-gss))" -split-input-file -verify-diagnostics %s

module {
  func.func @missing_wait(%arg0: i64 {hacc.arg_type = #hacc.arg_type<ffts_base_address>}) attributes {hacc.entry, hacc.function_kind = #hacc.function_kind<DEVICE>, hivm.func_core_type = #hivm.func_core_type<MIX>} {
    hivm.hir.sync_block_set {hivm.gss_deduce_flag_id = 0 : i64} [<CUBE>, <PIPE_FIX>, <PIPE_S>] flag = -1 // expected-error {{missing matching sync_block_wait for user sync group 0}}
    return
  }
}

// -----

module {
  func.func @wait_before_set(%arg0: i64 {hacc.arg_type = #hacc.arg_type<ffts_base_address>}) attributes {hacc.entry, hacc.function_kind = #hacc.function_kind<DEVICE>, hivm.func_core_type = #hivm.func_core_type<MIX>} {
    hivm.hir.sync_block_wait {hivm.gss_deduce_flag_id = 0 : i64} [<VECTOR>, <PIPE_FIX>, <PIPE_S>] flag = -1 // expected-error {{sync_block_wait appears before matching sync_block_set for user sync group 0}}
    return
  }
}

// -----

module {
  func.func @duplicate_set(%arg0: i64 {hacc.arg_type = #hacc.arg_type<ffts_base_address>}) attributes {hacc.entry, hacc.function_kind = #hacc.function_kind<DEVICE>, hivm.func_core_type = #hivm.func_core_type<MIX>} {
    hivm.hir.sync_block_set {hivm.gss_deduce_flag_id = 0 : i64} [<CUBE>, <PIPE_FIX>, <PIPE_S>] flag = -1
    hivm.hir.sync_block_set {hivm.gss_deduce_flag_id = 0 : i64} [<CUBE>, <PIPE_FIX>, <PIPE_S>] flag = -1 // expected-error {{duplicate sync_block_set for user sync group 0}}
    hivm.hir.sync_block_wait {hivm.gss_deduce_flag_id = 0 : i64} [<VECTOR>, <PIPE_FIX>, <PIPE_S>] flag = -1
    return
  }
}

// -----

module {
  func.func @duplicate_wait(%arg0: i64 {hacc.arg_type = #hacc.arg_type<ffts_base_address>}) attributes {hacc.entry, hacc.function_kind = #hacc.function_kind<DEVICE>, hivm.func_core_type = #hivm.func_core_type<MIX>} {
    hivm.hir.sync_block_set {hivm.gss_deduce_flag_id = 0 : i64} [<CUBE>, <PIPE_FIX>, <PIPE_S>] flag = -1
    hivm.hir.sync_block_wait {hivm.gss_deduce_flag_id = 0 : i64} [<VECTOR>, <PIPE_FIX>, <PIPE_S>] flag = -1
    hivm.hir.sync_block_wait {hivm.gss_deduce_flag_id = 0 : i64} [<VECTOR>, <PIPE_FIX>, <PIPE_S>] flag = -1 // expected-error {{duplicate sync_block_wait for user sync group 0}}
    return
  }
}

// -----

module {
  func.func @pipe_mismatch(%arg0: i64 {hacc.arg_type = #hacc.arg_type<ffts_base_address>}) attributes {hacc.entry, hacc.function_kind = #hacc.function_kind<DEVICE>, hivm.func_core_type = #hivm.func_core_type<MIX>} {
    hivm.hir.sync_block_set {hivm.gss_deduce_flag_id = 0 : i64} [<CUBE>, <PIPE_FIX>, <PIPE_S>] flag = -1
    hivm.hir.sync_block_wait {hivm.gss_deduce_flag_id = 0 : i64} [<VECTOR>, <PIPE_MTE2>, <PIPE_S>] flag = -1 // expected-error {{user sync_block_set/wait source pipe mismatch for group 0}}
    return
  }
}

// -----

module {
  func.func @too_many_live_user_syncs(%arg0: i64 {hacc.arg_type = #hacc.arg_type<ffts_base_address>}) attributes {hacc.entry, hacc.function_kind = #hacc.function_kind<DEVICE>, hivm.func_core_type = #hivm.func_core_type<MIX>} { // expected-error {{unable to assign a flag ID to user sync group}}
    hivm.hir.sync_block_set {hivm.gss_deduce_flag_id = 0 : i64} [<CUBE>, <PIPE_FIX>, <PIPE_S>] flag = -1
    hivm.hir.sync_block_set {hivm.gss_deduce_flag_id = 1 : i64} [<CUBE>, <PIPE_FIX>, <PIPE_S>] flag = -1
    hivm.hir.sync_block_set {hivm.gss_deduce_flag_id = 2 : i64} [<CUBE>, <PIPE_FIX>, <PIPE_S>] flag = -1
    hivm.hir.sync_block_set {hivm.gss_deduce_flag_id = 3 : i64} [<CUBE>, <PIPE_FIX>, <PIPE_S>] flag = -1
    hivm.hir.sync_block_set {hivm.gss_deduce_flag_id = 4 : i64} [<CUBE>, <PIPE_FIX>, <PIPE_S>] flag = -1
    hivm.hir.sync_block_set {hivm.gss_deduce_flag_id = 5 : i64} [<CUBE>, <PIPE_FIX>, <PIPE_S>] flag = -1
    hivm.hir.sync_block_set {hivm.gss_deduce_flag_id = 6 : i64} [<CUBE>, <PIPE_FIX>, <PIPE_S>] flag = -1
    hivm.hir.sync_block_set {hivm.gss_deduce_flag_id = 7 : i64} [<CUBE>, <PIPE_FIX>, <PIPE_S>] flag = -1
    hivm.hir.sync_block_set {hivm.gss_deduce_flag_id = 8 : i64} [<CUBE>, <PIPE_FIX>, <PIPE_S>] flag = -1
    hivm.hir.sync_block_set {hivm.gss_deduce_flag_id = 9 : i64} [<CUBE>, <PIPE_FIX>, <PIPE_S>] flag = -1
    hivm.hir.sync_block_set {hivm.gss_deduce_flag_id = 10 : i64} [<CUBE>, <PIPE_FIX>, <PIPE_S>] flag = -1
    hivm.hir.sync_block_set {hivm.gss_deduce_flag_id = 11 : i64} [<CUBE>, <PIPE_FIX>, <PIPE_S>] flag = -1
    hivm.hir.sync_block_set {hivm.gss_deduce_flag_id = 12 : i64} [<CUBE>, <PIPE_FIX>, <PIPE_S>] flag = -1
    hivm.hir.sync_block_set {hivm.gss_deduce_flag_id = 13 : i64} [<CUBE>, <PIPE_FIX>, <PIPE_S>] flag = -1
    hivm.hir.sync_block_set {hivm.gss_deduce_flag_id = 14 : i64} [<CUBE>, <PIPE_FIX>, <PIPE_S>] flag = -1
    hivm.hir.sync_block_wait {hivm.gss_deduce_flag_id = 0 : i64} [<VECTOR>, <PIPE_FIX>, <PIPE_S>] flag = -1
    hivm.hir.sync_block_wait {hivm.gss_deduce_flag_id = 1 : i64} [<VECTOR>, <PIPE_FIX>, <PIPE_S>] flag = -1
    hivm.hir.sync_block_wait {hivm.gss_deduce_flag_id = 2 : i64} [<VECTOR>, <PIPE_FIX>, <PIPE_S>] flag = -1
    hivm.hir.sync_block_wait {hivm.gss_deduce_flag_id = 3 : i64} [<VECTOR>, <PIPE_FIX>, <PIPE_S>] flag = -1
    hivm.hir.sync_block_wait {hivm.gss_deduce_flag_id = 4 : i64} [<VECTOR>, <PIPE_FIX>, <PIPE_S>] flag = -1
    hivm.hir.sync_block_wait {hivm.gss_deduce_flag_id = 5 : i64} [<VECTOR>, <PIPE_FIX>, <PIPE_S>] flag = -1
    hivm.hir.sync_block_wait {hivm.gss_deduce_flag_id = 6 : i64} [<VECTOR>, <PIPE_FIX>, <PIPE_S>] flag = -1
    hivm.hir.sync_block_wait {hivm.gss_deduce_flag_id = 7 : i64} [<VECTOR>, <PIPE_FIX>, <PIPE_S>] flag = -1
    hivm.hir.sync_block_wait {hivm.gss_deduce_flag_id = 8 : i64} [<VECTOR>, <PIPE_FIX>, <PIPE_S>] flag = -1
    hivm.hir.sync_block_wait {hivm.gss_deduce_flag_id = 9 : i64} [<VECTOR>, <PIPE_FIX>, <PIPE_S>] flag = -1
    hivm.hir.sync_block_wait {hivm.gss_deduce_flag_id = 10 : i64} [<VECTOR>, <PIPE_FIX>, <PIPE_S>] flag = -1
    hivm.hir.sync_block_wait {hivm.gss_deduce_flag_id = 11 : i64} [<VECTOR>, <PIPE_FIX>, <PIPE_S>] flag = -1
    hivm.hir.sync_block_wait {hivm.gss_deduce_flag_id = 12 : i64} [<VECTOR>, <PIPE_FIX>, <PIPE_S>] flag = -1
    hivm.hir.sync_block_wait {hivm.gss_deduce_flag_id = 13 : i64} [<VECTOR>, <PIPE_FIX>, <PIPE_S>] flag = -1
    hivm.hir.sync_block_wait {hivm.gss_deduce_flag_id = 14 : i64} [<VECTOR>, <PIPE_FIX>, <PIPE_S>] flag = -1
    return
  }
}
