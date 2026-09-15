// RUN: bishengir-opt -pass-pipeline="builtin.module(func.func(hivm-cross-core-gss))" -split-input-file -verify-diagnostics %s

module {
  func.func @missing_wait(%arg0: i64 {hacc.arg_type = #hacc.arg_type<ffts_base_address>}) attributes {hacc.entry, hacc.function_kind = #hacc.function_kind<DEVICE>, hivm.func_core_type = #hivm.func_core_type<MIX>} {
    %mutex = hivm.hir.create_sync_block_mutex : !hivm.sync_block_mutex
    hivm.hir.sync_block_set %mutex [<CUBE>, <PIPE_FIX>, <PIPE_S>] flag = -1 // expected-error {{missing matching sync_block_wait for user sync group 0}}
    return
  }
}

// -----

module {
  func.func @wait_without_set(%arg0: i64 {hacc.arg_type = #hacc.arg_type<ffts_base_address>}) attributes {hacc.entry, hacc.function_kind = #hacc.function_kind<DEVICE>, hivm.func_core_type = #hivm.func_core_type<MIX>} {
    %mutex = hivm.hir.create_sync_block_mutex : !hivm.sync_block_mutex
    hivm.hir.sync_block_wait %mutex [<VECTOR>, <PIPE_FIX>, <PIPE_S>] flag = -1 // expected-error {{sync_block_wait appears before matching sync_block_set for user sync group 0}}
    return
  }
}

// -----

module {
  func.func @duplicate_set(%arg0: i64 {hacc.arg_type = #hacc.arg_type<ffts_base_address>}) attributes {hacc.entry, hacc.function_kind = #hacc.function_kind<DEVICE>, hivm.func_core_type = #hivm.func_core_type<MIX>} {
    %mutex = hivm.hir.create_sync_block_mutex : !hivm.sync_block_mutex
    hivm.hir.sync_block_set %mutex [<CUBE>, <PIPE_FIX>, <PIPE_S>] flag = -1
    hivm.hir.sync_block_set %mutex [<CUBE>, <PIPE_FIX>, <PIPE_S>] flag = -1 // expected-error {{duplicate sync_block_set for user sync group 0}}
    hivm.hir.sync_block_wait %mutex [<VECTOR>, <PIPE_FIX>, <PIPE_S>] flag = -1
    return
  }
}

// -----

module {
  func.func @duplicate_wait(%arg0: i64 {hacc.arg_type = #hacc.arg_type<ffts_base_address>}) attributes {hacc.entry, hacc.function_kind = #hacc.function_kind<DEVICE>, hivm.func_core_type = #hivm.func_core_type<MIX>} {
    %mutex = hivm.hir.create_sync_block_mutex : !hivm.sync_block_mutex
    hivm.hir.sync_block_set %mutex [<CUBE>, <PIPE_FIX>, <PIPE_S>] flag = -1
    hivm.hir.sync_block_wait %mutex [<VECTOR>, <PIPE_FIX>, <PIPE_S>] flag = -1
    hivm.hir.sync_block_wait %mutex [<VECTOR>, <PIPE_FIX>, <PIPE_S>] flag = -1 // expected-error {{duplicate sync_block_wait for user sync group 0}}
    return
  }
}

// -----

module {
  func.func @pipe_mismatch(%arg0: i64 {hacc.arg_type = #hacc.arg_type<ffts_base_address>}) attributes {hacc.entry, hacc.function_kind = #hacc.function_kind<DEVICE>, hivm.func_core_type = #hivm.func_core_type<MIX>} {
    %mutex = hivm.hir.create_sync_block_mutex : !hivm.sync_block_mutex
    hivm.hir.sync_block_set %mutex [<CUBE>, <PIPE_FIX>, <PIPE_S>] flag = -1
    hivm.hir.sync_block_wait %mutex [<VECTOR>, <PIPE_MTE2>, <PIPE_S>] flag = -1 // expected-error {{user sync_block_set/wait source pipe mismatch for group 0}}
    return
  }
}

// -----

module {
  func.func @same_core_type(%arg0: i64 {hacc.arg_type = #hacc.arg_type<ffts_base_address>}) attributes {hacc.entry, hacc.function_kind = #hacc.function_kind<DEVICE>, hivm.func_core_type = #hivm.func_core_type<MIX>} {
    %mutex = hivm.hir.create_sync_block_mutex : !hivm.sync_block_mutex
    hivm.hir.sync_block_set %mutex [<CUBE>, <PIPE_FIX>, <PIPE_S>] flag = -1
    hivm.hir.sync_block_wait %mutex [<CUBE>, <PIPE_FIX>, <PIPE_S>] flag = -1 // expected-error {{user sync_block_set/wait core types must be different for group 0}}
    return
  }
}

// -----

module {
  func.func @too_many_live_user_syncs(%arg0: i64 {hacc.arg_type = #hacc.arg_type<ffts_base_address>}) attributes {hacc.entry, hacc.function_kind = #hacc.function_kind<DEVICE>, hivm.func_core_type = #hivm.func_core_type<MIX>} { // expected-error {{unable to assign a flag ID to user sync group}}
    %mutex0 = hivm.hir.create_sync_block_mutex : !hivm.sync_block_mutex
    %mutex1 = hivm.hir.create_sync_block_mutex : !hivm.sync_block_mutex
    %mutex2 = hivm.hir.create_sync_block_mutex : !hivm.sync_block_mutex
    %mutex3 = hivm.hir.create_sync_block_mutex : !hivm.sync_block_mutex
    %mutex4 = hivm.hir.create_sync_block_mutex : !hivm.sync_block_mutex
    %mutex5 = hivm.hir.create_sync_block_mutex : !hivm.sync_block_mutex
    %mutex6 = hivm.hir.create_sync_block_mutex : !hivm.sync_block_mutex
    %mutex7 = hivm.hir.create_sync_block_mutex : !hivm.sync_block_mutex
    %mutex8 = hivm.hir.create_sync_block_mutex : !hivm.sync_block_mutex
    %mutex9 = hivm.hir.create_sync_block_mutex : !hivm.sync_block_mutex
    %mutex10 = hivm.hir.create_sync_block_mutex : !hivm.sync_block_mutex
    %mutex11 = hivm.hir.create_sync_block_mutex : !hivm.sync_block_mutex
    %mutex12 = hivm.hir.create_sync_block_mutex : !hivm.sync_block_mutex
    %mutex13 = hivm.hir.create_sync_block_mutex : !hivm.sync_block_mutex
    %mutex14 = hivm.hir.create_sync_block_mutex : !hivm.sync_block_mutex
    hivm.hir.sync_block_set %mutex0 [<CUBE>, <PIPE_FIX>, <PIPE_S>] flag = -1
    hivm.hir.sync_block_set %mutex1 [<CUBE>, <PIPE_FIX>, <PIPE_S>] flag = -1
    hivm.hir.sync_block_set %mutex2 [<CUBE>, <PIPE_FIX>, <PIPE_S>] flag = -1
    hivm.hir.sync_block_set %mutex3 [<CUBE>, <PIPE_FIX>, <PIPE_S>] flag = -1
    hivm.hir.sync_block_set %mutex4 [<CUBE>, <PIPE_FIX>, <PIPE_S>] flag = -1
    hivm.hir.sync_block_set %mutex5 [<CUBE>, <PIPE_FIX>, <PIPE_S>] flag = -1
    hivm.hir.sync_block_set %mutex6 [<CUBE>, <PIPE_FIX>, <PIPE_S>] flag = -1
    hivm.hir.sync_block_set %mutex7 [<CUBE>, <PIPE_FIX>, <PIPE_S>] flag = -1
    hivm.hir.sync_block_set %mutex8 [<CUBE>, <PIPE_FIX>, <PIPE_S>] flag = -1
    hivm.hir.sync_block_set %mutex9 [<CUBE>, <PIPE_FIX>, <PIPE_S>] flag = -1
    hivm.hir.sync_block_set %mutex10 [<CUBE>, <PIPE_FIX>, <PIPE_S>] flag = -1
    hivm.hir.sync_block_set %mutex11 [<CUBE>, <PIPE_FIX>, <PIPE_S>] flag = -1
    hivm.hir.sync_block_set %mutex12 [<CUBE>, <PIPE_FIX>, <PIPE_S>] flag = -1
    hivm.hir.sync_block_set %mutex13 [<CUBE>, <PIPE_FIX>, <PIPE_S>] flag = -1
    hivm.hir.sync_block_set %mutex14 [<CUBE>, <PIPE_FIX>, <PIPE_S>] flag = -1
    hivm.hir.sync_block_wait %mutex0 [<VECTOR>, <PIPE_FIX>, <PIPE_S>] flag = -1
    hivm.hir.sync_block_wait %mutex1 [<VECTOR>, <PIPE_FIX>, <PIPE_S>] flag = -1
    hivm.hir.sync_block_wait %mutex2 [<VECTOR>, <PIPE_FIX>, <PIPE_S>] flag = -1
    hivm.hir.sync_block_wait %mutex3 [<VECTOR>, <PIPE_FIX>, <PIPE_S>] flag = -1
    hivm.hir.sync_block_wait %mutex4 [<VECTOR>, <PIPE_FIX>, <PIPE_S>] flag = -1
    hivm.hir.sync_block_wait %mutex5 [<VECTOR>, <PIPE_FIX>, <PIPE_S>] flag = -1
    hivm.hir.sync_block_wait %mutex6 [<VECTOR>, <PIPE_FIX>, <PIPE_S>] flag = -1
    hivm.hir.sync_block_wait %mutex7 [<VECTOR>, <PIPE_FIX>, <PIPE_S>] flag = -1
    hivm.hir.sync_block_wait %mutex8 [<VECTOR>, <PIPE_FIX>, <PIPE_S>] flag = -1
    hivm.hir.sync_block_wait %mutex9 [<VECTOR>, <PIPE_FIX>, <PIPE_S>] flag = -1
    hivm.hir.sync_block_wait %mutex10 [<VECTOR>, <PIPE_FIX>, <PIPE_S>] flag = -1
    hivm.hir.sync_block_wait %mutex11 [<VECTOR>, <PIPE_FIX>, <PIPE_S>] flag = -1
    hivm.hir.sync_block_wait %mutex12 [<VECTOR>, <PIPE_FIX>, <PIPE_S>] flag = -1
    hivm.hir.sync_block_wait %mutex13 [<VECTOR>, <PIPE_FIX>, <PIPE_S>] flag = -1
    hivm.hir.sync_block_wait %mutex14 [<VECTOR>, <PIPE_FIX>, <PIPE_S>] flag = -1
    return
  }
}
