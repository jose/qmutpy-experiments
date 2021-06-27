# Description of time values computed and reported by [MutPy](https://github.com/mutpy/mutpy)

Note: all time values reported in this document are represented in seconds.

## Before mutation testing takes place

Before performing mutation testing, MutPy

1. [Executes all test cases](https://github.com/mutpy/mutpy/blob/5c8b3ca0d365083a4da8333f7fce8783114371fa/mutpy/controller.py#L77)
and collects (1) the set of test modules, (2) time to execute all tests, and (3)
number of test in the test suite.  Note: if any test case fails in this process,
a [`TestsFailAtOriginal` exception is thrown](https://github.com/mutpy/mutpy/blob/5c8b3ca0d365083a4da8333f7fce8783114371fa/mutpy/controller.py#L97).
The time to perform this step is reported by MutPy as `time` under the group
`tests`.  In here we name it as `time_to_run_tests_on_non_mutated_code`.

2. [Creates an AST of the module/target under test](https://github.com/mutpy/mutpy/blob/5c8b3ca0d365083a4da8333f7fce8783114371fa/mutpy/controller.py#L109).
The time to perform this step is reported by MutPy as `create_target_ast`.  To
ease understanding of all MutPy's time values and in the attempt to better
describe this time value, in here, we rename it to `time_to_create_targets_ast`.

3. [Mutate the module/target under test and generate mutated ASTs](https://github.com/mutpy/mutpy/blob/5c8b3ca0d365083a4da8333f7fce8783114371fa/mutpy/controller.py#L113).
The time to perform this step is *not* reported by MutPy but it could be
computed.  We will describe how to later in this document.

## Per mutant

For [each mutated AST](https://github.com/mutpy/mutpy/blob/5c8b3ca0d365083a4da8333f7fce8783114371fa/mutpy/controller.py#L113), MutPy

1. [Creates a mutated module](https://github.com/mutpy/mutpy/blob/5c8b3ca0d365083a4da8333f7fce8783114371fa/mutpy/controller.py#L120)
i.e., a module with the exact same name as the non-mutated one but populated
with a mutated AST.

2. [Runs tests on a mutated module](https://github.com/mutpy/mutpy/blob/5c8b3ca0d365083a4da8333f7fce8783114371fa/mutpy/controller.py#L122).
This step is composed by two other steps:
  - [Create a test suite object](https://github.com/mutpy/mutpy/blob/5c8b3ca0d365083a4da8333f7fce8783114371fa/mutpy/test_runners/base.py#L169)
  - [Runs module's test suite](https://github.com/mutpy/mutpy/blob/5c8b3ca0d365083a4da8333f7fce8783114371fa/mutpy/test_runners/base.py#L173)

In MutPy, each step is reported in a single time value for all mutated modules.
The time to perform step (1) for all mutated modules is reported by MutPy as
`create_mutant_module` and the time to perform step (2) is reported as
`run_tests_with_mutant`.  In here, we rename these time values to
`time_to_create_mutated_modules` and `time_to_run_tests_on_mutated_modules`,
respectively.  Formally, `time_to_create_mutated_modules` is computed as

![](https://latex.codecogs.com/svg.latex?\Large&space;\text{time-to-create-mutated-modules}=\sum_{m~\in~M}{\text{time-to-create-mutated-module-m}})

and `time_to_run_tests_on_mutated_modules` is computed as

![](https://latex.codecogs.com/svg.latex?\Large&space;\text{time-to-run-tests-on-mutated-modules}=\sum_{m~\in~M}{\text{time-to-run-tests-on-mutated-module-m}})

where `m` represents a `mutated module` and `M` the set of all `mutated modules`.

## Total

At the end of mutation analysis, MutPy reports a single `total_time` which
represents the sum of all time values computed and reported by MutPy, and some
additional overhead of MutPy's infrastructure.

## Example

Lets suppose a module under test `X` with 341 lines of code and a test suite
with 21 tests which take `time_to_run_tests_on_non_mutated_code`
598.7711293697357 seconds to run on the original module's code.  To create an
AST of the module under test, MutPy takes `time_to_create_targets_ast`
0.06933999061584473 seconds to create an AST representation of the original
module's code.  To create a code representation of a mutated ASTs, MutPy takes
`time_to_create_mutated_modules` 0.011466264724731445 seconds.

Now lest suppose the following mutation testing result:

| Mutant ID | Status   | # Tests executed | Time (seconds)    |
|----------:|:---------|-----------------:|------------------:|
| 1         | survived | 21               | 552.0021417140961 |
| 2         | killed   | 14               | 482.7444038391113 |

For this example, MutPy then reports a `time_to_run_tests_on_mutated_modules` of
1034.7493934631348 seconds which is basically

```
    552.0021417140961
    482.7444038391113
 + -------------------
   1034.7465455532074 (~ 1034.7493934631348)
```

Furthermore, MutPy also reports the time to mutate a module (`mutate_module`)
1037.2904443740845 seconds.  This value could be computed by the following
equation:

```
  mutate_module = time_to_create_targets_ast +
                  time_to_generate_mutated_asts +
                  time_to_create_mutated_modules +
                  time_to_run_tests_on_mutated_modules
```

Note that the `time_to_create_mutated_modules` is unknown as it is not reported
individually by MutPy.  However, it can be computed from the values reported by
MutPy

```
  1037.2904443740845 =    0.06933999061584473 +
                          ?.????????????????? +
                          0.011466264724731445 +
                       1034.7493934631348
```

therefore, `time_to_create_mutated_modules` is 2.4602446556093600 seconds.  That
is, MutPy takes 2.46 seconds to create the two mutants for module under test `X`
which means on average it takes 1.23 seconds to inject a mutant in a non-mutated
AST.

For this example, MutPy also reports a `total_time` of 1638.744356393814 seconds
which could have been estimated by

```
   1037.2904443740845
    598.7711293697357
      0.06933999061584473
      0.011466264724731445
 + ------------------------
 ~ 1636.1423799991600000
```

- `time_to_run_tests_on_non_mutated_code`: depends on the number of tests >>> Table 2
- `time_to_create_targets_ast`: depends on the size of the target under test
- `time_to_generate_mutated_asts`: depends on the mutation operator and must be divided by the \# mutants so that one could know the mean time to create a mutant of operator X  >>> way to compare time between operators
- `time_to_create_mutated_modules`: depends on the number of mutants
- `time_to_run_tests_on_mutated_modules`: depends on the number of tests and on the number of mutants
