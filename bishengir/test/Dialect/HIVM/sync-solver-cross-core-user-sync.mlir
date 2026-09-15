// RUN: bishengir-opt -pass-pipeline="builtin.module(func.func(hivm-cross-core-gss))" -split-input-file %s | FileCheck %s

module {
  func.func @deduce_user_pair(%arg0: i64 {hacc.arg_type = #hacc.arg_type<ffts_base_address>}) attributes {hacc.entry, hacc.function_kind = #hacc.function_kind<DEVICE>, hivm.func_core_type = #hivm.func_core_type<MIX>} {
    // CHECK-LABEL: func.func @deduce_user_pair
    // CHECK-NOT: create_sync_block_mutex
    // CHECK: hivm.hir.sync_block_set[<CUBE>, <PIPE_FIX>, <PIPE_S>] flag = 0
    // CHECK-NOT: sync_block_mutex
    // CHECK: hivm.hir.sync_block_wait[<VECTOR>, <PIPE_FIX>, <PIPE_S>] flag = 0
    %mutex = hivm.hir.create_sync_block_mutex : !hivm.sync_block_mutex
    hivm.hir.sync_block_set %mutex [<CUBE>, <PIPE_FIX>, <PIPE_S>] flag = -1
    hivm.hir.sync_block_wait %mutex [<VECTOR>, <PIPE_FIX>, <PIPE_S>] flag = -1
    return
  }
}

// -----

module {
  func.func @deduce_two_non_overlapping_user_pairs(%arg0: i64 {hacc.arg_type = #hacc.arg_type<ffts_base_address>}) attributes {hacc.entry, hacc.function_kind = #hacc.function_kind<DEVICE>, hivm.func_core_type = #hivm.func_core_type<MIX>} {
    // CHECK-LABEL: func.func @deduce_two_non_overlapping_user_pairs
    // CHECK-NOT: create_sync_block_mutex
    // CHECK: hivm.hir.sync_block_set[<CUBE>, <PIPE_FIX>, <PIPE_S>] flag = 0
    // CHECK: hivm.hir.sync_block_wait[<VECTOR>, <PIPE_FIX>, <PIPE_S>] flag = 0
    // CHECK: hivm.hir.sync_block_set[<VECTOR>, <PIPE_MTE2>, <PIPE_S>] flag = 0
    // CHECK: hivm.hir.sync_block_wait[<CUBE>, <PIPE_MTE2>, <PIPE_S>] flag = 0
    %mutex0 = hivm.hir.create_sync_block_mutex : !hivm.sync_block_mutex
    hivm.hir.sync_block_set %mutex0 [<CUBE>, <PIPE_FIX>, <PIPE_S>] flag = -1
    hivm.hir.sync_block_wait %mutex0 [<VECTOR>, <PIPE_FIX>, <PIPE_S>] flag = -1
    %mutex1 = hivm.hir.create_sync_block_mutex : !hivm.sync_block_mutex
    hivm.hir.sync_block_set %mutex1 [<VECTOR>, <PIPE_MTE2>, <PIPE_S>] flag = -1
    hivm.hir.sync_block_wait %mutex1 [<CUBE>, <PIPE_MTE2>, <PIPE_S>] flag = -1
    return
  }
}

// -----

module {
  func.func @deduce_user_pair_inside_loop(%arg0: i64 {hacc.arg_type = #hacc.arg_type<ffts_base_address>}) attributes {hacc.entry, hacc.function_kind = #hacc.function_kind<DEVICE>, hivm.func_core_type = #hivm.func_core_type<MIX>} {
    // CHECK-LABEL: func.func @deduce_user_pair_inside_loop
    %c0 = arith.constant 0 : index
    %c4 = arith.constant 4 : index
    %c1 = arith.constant 1 : index
    scf.for %i = %c0 to %c4 step %c1 {
      // CHECK-NOT: create_sync_block_mutex
      // CHECK: hivm.hir.sync_block_set[<CUBE>, <PIPE_FIX>, <PIPE_S>] flag = 0
      // CHECK: hivm.hir.sync_block_wait[<VECTOR>, <PIPE_FIX>, <PIPE_S>] flag = 0
      %mutex = hivm.hir.create_sync_block_mutex : !hivm.sync_block_mutex
      hivm.hir.sync_block_set %mutex [<CUBE>, <PIPE_FIX>, <PIPE_S>] flag = -1
      hivm.hir.sync_block_wait %mutex [<VECTOR>, <PIPE_FIX>, <PIPE_S>] flag = -1
    }
    return
  }
}

// -----

module {
  func.func @deduce_two_overlapping_user_pairs(%arg0: i64 {hacc.arg_type = #hacc.arg_type<ffts_base_address>}) attributes {hacc.entry, hacc.function_kind = #hacc.function_kind<DEVICE>, hivm.func_core_type = #hivm.func_core_type<MIX>} {
    // CHECK-LABEL: func.func @deduce_two_overlapping_user_pairs
    // CHECK-NOT: create_sync_block_mutex
    // CHECK-DAG: hivm.hir.sync_block_set[<CUBE>, <PIPE_FIX>, <PIPE_S>] flag = 0
    // CHECK-DAG: hivm.hir.sync_block_set[<CUBE>, <PIPE_FIX>, <PIPE_S>] flag = 1
    // CHECK-DAG: hivm.hir.sync_block_wait[<VECTOR>, <PIPE_FIX>, <PIPE_S>] flag = 0
    // CHECK-DAG: hivm.hir.sync_block_wait[<VECTOR>, <PIPE_FIX>, <PIPE_S>] flag = 1
    %mutex0 = hivm.hir.create_sync_block_mutex : !hivm.sync_block_mutex
    %mutex1 = hivm.hir.create_sync_block_mutex : !hivm.sync_block_mutex
    hivm.hir.sync_block_set %mutex0 [<CUBE>, <PIPE_FIX>, <PIPE_S>] flag = -1
    hivm.hir.sync_block_set %mutex1 [<CUBE>, <PIPE_FIX>, <PIPE_S>] flag = -1
    hivm.hir.sync_block_wait %mutex0 [<VECTOR>, <PIPE_FIX>, <PIPE_S>] flag = -1
    hivm.hir.sync_block_wait %mutex1 [<VECTOR>, <PIPE_FIX>, <PIPE_S>] flag = -1
    return
  }
}

// -----

module {
  func.func @fixed_user_sync_unchanged(%arg0: i64 {hacc.arg_type = #hacc.arg_type<ffts_base_address>}) attributes {hacc.entry, hacc.function_kind = #hacc.function_kind<DEVICE>, hivm.func_core_type = #hivm.func_core_type<MIX>} {
    // CHECK-LABEL: func.func @fixed_user_sync_unchanged
    // CHECK: hivm.hir.sync_block_set[<CUBE>, <PIPE_FIX>, <PIPE_S>] flag = 7
    hivm.hir.sync_block_set[<CUBE>, <PIPE_FIX>, <PIPE_S>] flag = 7
    // CHECK: hivm.hir.sync_block_wait[<VECTOR>, <PIPE_FIX>, <PIPE_S>] flag = 7
    hivm.hir.sync_block_wait[<VECTOR>, <PIPE_FIX>, <PIPE_S>] flag = 7
    return
  }
}
