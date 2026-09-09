//===--------- IRTranslator.h ---- Graph Sync Solver ------------===//
//
// Copyright (c) Huawei Technologies Co., Ltd. 2025. All rights reserved.
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
//===----------------------------------------------------------------------===//
#ifndef BISHENG_DIALECT_HIVM_TRANSFORMS_GRAPHSYNCSOLVER_SYNCSOLVERIRTRANSLATOR_H
#define BISHENG_DIALECT_HIVM_TRANSFORMS_GRAPHSYNCSOLVER_SYNCSOLVERIRTRANSLATOR_H

#include "bishengir/Dialect/HIVM/Transforms/GraphSyncSolver/SyncSolverIR.h"
#include "bishengir/Dialect/HIVM/Transforms/GraphSyncSolver/Utility.h"

#include "bishengir/Dialect/HIVM/IR/HIVM.h"
#include "mlir/Dialect/Func/IR/FuncOps.h"
#include "mlir/Dialect/Tensor/IR/Tensor.h"
#include "mlir/IR/AsmState.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/DenseSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/Support/LogicalResult.h"
#include <map>
#include <memory>
#include <optional>
#include <utility>

namespace mlir::hivm::syncsolver {

using AnchorMap = llvm::DenseMap<int64_t, hivm::AnchorOp>;

struct CVTripletKernels {
  func::FuncOp mixFuncOp;
  func::FuncOp vectorFuncOp;
  func::FuncOp cubeFuncOp;
  CVTripletKernels(const func::FuncOp &mixFuncOp,
                   const func::FuncOp &vectorFuncOp,
                   const func::FuncOp &cubeFuncOp)
      : mixFuncOp(mixFuncOp), vectorFuncOp(vectorFuncOp),
        cubeFuncOp(cubeFuncOp) {}
};

class IRTranslator {
public:
  // Configuration options.
  const SyncSolverOptions options;

  // Original MLIR function being processed (may be null for test-only Solver).
  func::FuncOp funcOp;

  // In-memory hierarchical IR (Function -> Scopes -> Ops) used by the solver.
  std::unique_ptr<OperationBase> funcIr;

  // Linearized occurrence sequence (sync IR) built from funcIr, each Occurrence
  // represents one appearance of an operation in the sync-analysis order.
  std::vector<std::unique_ptr<Occurrence>> syncIr;

  // Set of RW operations that expose unit-flag feature and need special
  // handling.
  llvm::SetVector<RWOperation *> unitFlagFeaturedOps;

  // Map op -> list of occurrences in syncIr (quick lookup for an op's
  // occurrences).
  llvm::DenseMap<OperationBase *, std::vector<Occurrence *>> opAllOccurrences;

  // Aliases for block arguments collected from cf::CondBranchOp and
  // cf::BranchOp operations.
  llvm::DenseMap<Value, llvm::SmallVector<Value>> blockArgAliases;

  // Ordered map anchor-id -> (anchor op / anchor-attr marked op).
  std::map<int64_t, OperationBase *> anchorOpMap;

  // Failure state accumulated while translating MLIR to solver IR.
  llvm::LogicalResult translationResult{llvm::success()};

  // (user id, caller call-site location) -> sync-group key made during
  // IR translation.
  // Ops originating from the same inlined call site have same Attribute.
  llvm::DenseMap<std::pair<int64_t, Attribute>, int64_t> userSyncGroupKeys;
  int64_t nextUserSyncGroupKey{0};

  // Scoped user sync group key -> translated solver set/wait ops.
  llvm::DenseMap<int64_t, std::pair<SetFlagOp *, WaitFlagOp *>>
      userSyncGroupOps;

public:
  IRTranslator(SyncSolverOptions options) : options(options) {}

  IRTranslator(func::FuncOp func, SyncSolverOptions options)
      : options(options), funcOp(func) {
    auto funcOp = std::make_unique<syncsolver::Function>(func.getOperation());
    auto scopeOp = funcIrBuilder(func.getRegion(), funcOp.get());
    funcOp->body.push_back(std::move(scopeOp));
    funcIr = std::move(funcOp);
    if (llvm::failed(translationResult)) {
      return;
    }
    translationResult = validateUserSyncPairs();
    if (llvm::failed(translationResult)) {
      return;
    }
    if (options.buildUnrolledSyncIR) {
      syncIrBuilder(funcIr.get());
    }
  }

  IRTranslator(std::unique_ptr<OperationBase> funcIr, SyncSolverOptions options)
      : options(options), funcIr(std::move(funcIr)) {
    if (this->funcIr && this->funcIr->op)
      funcOp = dyn_cast<func::FuncOp>(this->funcIr->op);
    if (options.buildUnrolledSyncIR) {
      syncIrBuilder(this->funcIr.get());
    }
  }

  llvm::LogicalResult getResult() const { return translationResult; }

protected:
  int64_t globalIndex{0};
  int64_t globalPreOrderTraversalIndex{0};

  // Convert MLIR Region into the in-memory funcIr Scope representation.
  std::unique_ptr<Scope> funcIrBuilder(Region &region, OperationBase *parentOp,
                                       bool skipEmptyScopes = false);

  // Return the logical user-sync group id from a deduce annotation, or none
  // when the operation is not annotated for user-sync flag-id deduction.
  std::optional<int64_t> getUserSyncGroupId(Operation *op);

  // Parse op to get user ID included in metadata.
  std::optional<int64_t> getUserSyncGroupKey(Operation *op);

  // Verify that each deduced user-sync group has exactly one valid set/wait
  // pair in the supported forward-only/cross-core subset.
  llvm::LogicalResult validateUserSyncPairs();

  // Create a decomposed representation for certain MMAD L1 ops if enabled.
  std::unique_ptr<OperationBase> getDecomposedMmadl1(hivm::MmadL1Op mmadl1Op,
                                                     OperationBase *parentOp);

  std::unique_ptr<OperationBase>
  getDecomposedMmadMxL1(hivm::MmadMxL1Op mmadMxL1Op, OperationBase *parentOp);

  // Build sync IR occurrences from the operation tree.
  void syncIrBuilder(OperationBase *op, Occurrence *parentOcc = nullptr,
                     bool isUseless = false);

  // Collect pointer-like operands reachable from a Value.
  llvm::SmallVector<Value> tracebackMemVals(Value val);
  llvm::SmallVector<Value> tracebackMemValsStep(Value val);

  // Extract memory-related Values from a list of pointer values.
  llvm::SmallVector<Value> getMemoryOps(const SmallVector<Value> &vals);

  // Return read and write memory operand lists for an MLIR operation.
  std::pair<llvm::SmallVector<Value>, llvm::SmallVector<Value>>
  getReadWriteMemoryOps(Operation *op);

  // Return a wrapped Load/Store RWOperation when encountering affine/memref
  // load/store ops.
  template <typename OP>
  std::unique_ptr<OperationBase> getLoadStoreOp(OP op, OperationBase *parentOp);

  std::unique_ptr<OperationBase> getDebugOp(DebugOp debugOp,
                                            OperationBase *parentOp);

  std::unique_ptr<OperationBase>
  getDestinationStyleInterfaceOp(Operation *op, OperationBase *parentOp);

  std::unique_ptr<OperationBase> translateRWLikeOp(Operation *op,
                                                   OperationBase *parentOp);

  std::unique_ptr<OperationBase> getTensorExtractOp(tensor::ExtractOp extractOp,
                                                    OperationBase *parentOp);

  std::unique_ptr<OperationBase> getCallOp(func::CallOp callOp,
                                           OperationBase *parentOp);


  std::unique_ptr<OperationBase> buildUserSetFlagOp(hivm::SyncBlockSetOp op,
                                                    OperationBase *parentOp,
                                                    int64_t userSyncGroupId);

  std::unique_ptr<OperationBase> buildUserWaitFlagOp(hivm::SyncBlockWaitOp op,
                                                     OperationBase *parentOp,
                                                     int64_t userSyncGroupId);

  bool isVectorOpResult(Value val);

  std::optional<hivm::PIPE>
  getInferredPipe(Operation *op, TCoreType coreType,
                  const llvm::SmallVector<Value> &writeMemInfo);

  void updateBlockArgAliases(Block *block, OperandRange destOperands);

  bool isUnlikelyCondition(Condition *condOp);

  bool isParallelLoop(Loop *loopOp);

  bool isCVUnrolledLoop(Loop *loopOp);

  std::optional<int64_t> getLoopMultibufferUnrollNum(Loop *loopOp);

  std::optional<int64_t> getScopePreloadNum(Scope *scopeOp);

  std::optional<int64_t> getScopeMaxPreloadNum(Scope *scopeOp);
};

class DelayedCrossCoreIRTranslator : public IRTranslator {
public:
  CVTripletKernels tripletKernels;
  std::unique_ptr<IRTranslator> cubeIRTranslator;
  std::unique_ptr<IRTranslator> vectorIRTranslator;

public:
  DelayedCrossCoreIRTranslator(const CVTripletKernels &t,
                               SyncSolverOptions options)
      : IRTranslator(options), tripletKernels(t) {
    funcOp = tripletKernels.mixFuncOp;
    initIRTranslators();
    if (llvm::failed(translationResult)) {
      return;
    }
    funcIr = buildDelayedFuncIr();
    if (llvm::failed(translationResult)) {
      return;
    }
    if (options.buildUnrolledSyncIR) {
      syncIrBuilder(funcIr.get());
    }
  }

  void initIRTranslators();

  std::unique_ptr<OperationBase> buildDelayedFuncIr();
};

} // namespace mlir::hivm::syncsolver

#endif // BISHENG_DIALECT_HIVM_TRANSFORMS_GRAPHSYNCSOLVER_SYNCSOLVERIRTRANSLATOR_H
