/**
 * @process local/jcode-turn-gate
 * @description Implement an opt-in turn-end gate hook in jcode so external orchestrators (a5c-ai/babysitter) can drive continuation.
 * @inputs { featureDescription?: string, implementationDetails?: string, component?: string, filesToChange?: array, additionalContext?: string }
 * @outputs { success: boolean, summary: string, runDir: string }
 */

import { defineTask } from '@a5c-ai/babysitter-sdk';

export async function process(inputs, ctx) {
  const {
    featureDescription = '',
    implementationDetails = '',
    component = '',
    filesToChange = [],
    additionalContext = ''
  } = inputs;

  ctx.log('info', 'Phase 1: Analyze jcode hook architecture');

  const analysis = await ctx.task(analyzeHookArchitectureTask, {
    featureDescription,
    component,
    filesToChange,
    additionalContext
  });

  ctx.log('info', 'Phase 2: Implement turn-end gate hook');

  const implementation = await ctx.task(implementTurnEndGateTask, {
    featureDescription,
    implementationDetails,
    filesToChange: analysis.filesToChange,
    additionalContext
  });

  ctx.log('info', 'Phase 3: Add tests for turn-end gate');

  const tests = await ctx.task(addGateTestsTask, {
    filesToChange: implementation.filesToChange,
    implementationDetails
  });

  ctx.log('info', 'Phase 4: Build and verify');

  const verification = await ctx.task(buildAndVerifyTask, {
    filesToChange: tests.filesToChange,
    implementationDetails
  });

  ctx.log('info', 'Phase 5: Completion proof');

  await ctx.task(completionProofTask, {
    filesToChange: verification.filesToChange,
    implementationDetails: verification.implementationDetails,
    testResults: verification.testResults
  });

  return {
    success: true,
    summary: 'Turn-end gate hook implemented, tested, and building',
    runDir: '.'
  };
}

const analyzeHookArchitectureTask = defineTask('analyze-hook-architecture', (args, taskCtx) => ({
  kind: 'agent',
  title: 'Analyze jcode hook architecture',
  description:
    'Read crates/jcode-base/src/hooks.rs, crates/jcode-app-core/src/agent/turn_execution.rs, ' +
    'crates/jcode-config-types/src/lib.rs, and crates/jcode-app-core/src/hooks.rs to map how ' +
    'turn_start/turn_end/pre_tool hooks are dispatched, how pre_tool gate blocks, and where ' +
    'followup injection would live. Report concrete file:line anchors.',
  agent: {
    name: 'general-purpose',
    prompt: {
      role: 'jcode hook architecture analyst',
      task:
        'Map the jcode hook system in the local repo at /home/prem-modha/.jcode/source/jcode. ' +
        'Report the dispatch paths for turn_start/turn_end/pre_tool, the pre_tool gate contract ' +
        '(exit codes, stderr feedback), where a followup_message from a turn_end hook could be ' +
        'injected into the next turn, and which config fields exist. Return file:line anchors.',
      context: {
        featureDescription: args.featureDescription,
        component: args.component,
        filesToChange: args.filesToChange,
        additionalContext: args.additionalContext
      }
    }
  }
}));

const implementTurnEndGateTask = defineTask('implement-turn-end-gate', (args, taskCtx) => ({
  kind: 'agent',
  title: 'Implement opt-in turn-end gate hook',
  description:
    'Add an opt-in turn-end gate to jcode: when configured, jcode waits for the turn_end hook, ' +
    'parses its stdout as JSON; if it is {"decision":"block","followup_message":"<text>"}, inject ' +
    'followup_message as the next turn instruction. Exit 0, no valid JSON, or exit 2 = no injection, ' +
    'observer behavior preserved. Plumb a config field + timeout mirroring pre_tool_timeout_ms. ' +
    'Keep existing herdr-agent-state.sh wiring working.',
  agent: {
    name: 'general-purpose',
    prompt: {
      role: 'jcode core contributor',
      task:
        'Implement the turn-end gate hook in /home/prem-modha/.jcode/source/jcode following the ' +
        'analysis anchors. Use run_pre_tool_gate in crates/jcode-base/src/hooks.rs as the reference ' +
        'implementation. Add the config field with a timeout, mirroring pre_tool_timeout_ms. ' +
        'Do not change observer behavior for hooks that emit no gate JSON. Keep the diff additive.',
      context: {
        featureDescription: args.featureDescription,
        implementationDetails: args.implementationDetails,
        filesToChange: args.filesToChange,
        additionalContext: args.additionalContext
      }
    }
  }
}));

const addGateTestsTask = defineTask('add-gate-tests', (args, taskCtx) => ({
  kind: 'agent',
  title: 'Add unit tests for turn-end gate',
  description:
    'Mirror existing hooks.rs tests and add a turn_execution-level test proving an injected ' +
    'followup becomes the next instruction.',
  agent: {
    name: 'general-purpose',
    prompt: {
      role: 'jcode test contributor',
      task:
        'Add unit tests in /home/prem-modha/.jcode/source/jcode mirroring the existing hooks.rs tests ' +
        '(around lines 332, 496, 515) plus a turn_execution-level test that an injected followup ' +
        'message becomes the next instruction. Cover: valid block JSON, exit 0 no JSON, malformed JSON.',
      context: {
        filesToChange: args.filesToChange,
        implementationDetails: args.implementationDetails
      }
    }
  }
}));

const buildAndVerifyTask = defineTask('build-and-verify', (args, taskCtx) => ({
  kind: 'agent',
  title: 'Build and verify',
  description:
    'Run cargo build and cargo test for the affected crates. Fix failures. Report test results.',
  agent: {
    name: 'general-purpose',
    prompt: {
      role: 'jcode build verifier',
      task:
        'In /home/prem-modha/.jcode/source/jcode, run cargo build and cargo test for the affected ' +
        'crates. Fix any failures caused by the change. Report the test results and any remaining issues.',
      context: {
        filesToChange: args.filesToChange,
        implementationDetails: args.implementationDetails
      }
    }
  }
}));

const completionProofTask = defineTask('completion-proof', (args, taskCtx) => ({
  kind: 'agent',
  title: 'Completion proof',
  description:
    'Verify the final state satisfies the contract: turn_end gate emits followup, existing observers ' +
    'unaffected, build+tests pass. Emit <promise>COMPLETION_PROOF</promise>.',
  agent: {
    name: 'general-purpose',
    prompt: {
      role: 'completion proof verifier',
      task:
        'Verify the implemented turn-end gate in /home/prem-modha/.jcode/source/jcode: (1) gate emits ' +
        'followup_message when JSON decision=block, (2) exit 0 / no JSON leaves observers unchanged, ' +
        '(3) build and tests pass. Summarize evidence and emit <promise>COMPLETION_PROOF</promise>.',
      context: {
        filesToChange: args.filesToChange,
        implementationDetails: args.implementationDetails,
        testResults: args.testResults
      }
    }
  }
}));
