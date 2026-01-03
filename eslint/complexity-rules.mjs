/**
 * ESLint Complexity Rules Template
 *
 * These rules help prevent technical debt accumulation by enforcing
 * code complexity limits. Use this as a reference for your projects.
 *
 * Source: Discovered from Elu-co-jp/management_tools
 *
 * Implementation Strategy:
 * - Phase 1: Set rules to "warn" to detect issues without breaking builds
 * - Phase 2: Upgrade to "error" once codebase is compliant
 */

export const complexityRules = {
  /**
   * Cyclomatic Complexity
   * Limits the complexity of functions by counting the number of linearly
   * independent paths through the code.
   *
   * Recommended: 15 (warn), stricter: 10 (error)
   */
  complexity: ['warn', { max: 15 }],

  /**
   * Function Length
   * Limits the number of lines in a function to maintain readability.
   *
   * Recommended: 100 lines (warn)
   * Blank lines and comments are not counted.
   */
  'max-lines-per-function': [
    'warn',
    {
      max: 100,
      skipBlankLines: true,
      skipComments: true,
    },
  ],

  /**
   * File Length
   * Limits the number of lines in a file to maintain focus and cohesion.
   *
   * Recommended: 500 lines (warn)
   * Blank lines and comments are not counted.
   */
  'max-lines': [
    'warn',
    {
      max: 500,
      skipBlankLines: true,
      skipComments: true,
    },
  ],

  /**
   * Nesting Depth
   * Limits the depth of nested blocks to improve readability.
   *
   * Recommended: 4 levels (warn)
   */
  'max-depth': ['warn', 4],

  /**
   * Function Parameters
   * Limits the number of parameters a function can accept.
   *
   * Recommended: 5 parameters (warn)
   * Consider using an options object for more parameters.
   */
  'max-params': ['warn', 5],
};

/**
 * Usage Example:
 *
 * import { complexityRules } from './eslint/complexity-rules.mjs';
 *
 * export default [
 *   {
 *     files: ['**\/*.{js,jsx,ts,tsx}'],
 *     rules: {
 *       ...complexityRules,
 *       // Your other rules
 *     },
 *   },
 * ];
 */
