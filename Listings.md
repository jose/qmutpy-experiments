# Code Listings

This file contains examples of QMutPy's mutation operators to showcase
their functionalities. It also contains the code listings of
coverage and assertion improvements done to 3 QISKit algorithms.

## Mutation Operators

Examples of mutations using all 5 novel mutation operators: QGD, QGI, QGR, QMD and QMI.
Quantum program implementing Shor's algorithm used as example (https://github.com/Qiskit/qiskit-aqua/blob/stable/0.9/qiskit/aqua/algorithms/factorizers/shor.py).

### QGD (Quantum Gate Deletion)

```
153 -    circuit.x(qubits[0])  
153 +    pass  
```

### QGI (Quantum Gate Insertion)

```
153 -    circuit.x(qubits[0])  
153 +    __qmutpy_qgi_func__(circuit, qubits[0])  
424 +    def __qmutpy_qgi_func__(circuit, qubit)  
425 +        circuit.x(qubit)  
426 +        circuit.y(qubit)  
```

### QGR (Quantum Gate Replacement)

```
153 -    circuit.x(qubits[0])  
153 +    circuit.h(qubits[0])  
```

### QMD (Quantum Measurement Deletion)
```
258      up_cqreg = ClassicalRegister(2 * self._n, name='m')  
259      circuit.add_register(up_cqreg)  
260 -    circuit.measure(self._up_qreg, up_cqreg)  
260 +    pass  
```

### QMI (Quantum Measurement Insertion)

```
153 -    circuit.x(qubits[0])  
153 +    __qmutpy_qmi_func__(circuit, qubits[0])  
424 +    def __qmutpy_qmi_func__(circuit, qubit)  
425 +        circuit.x(qubit)  
426 +        measurement_cr = ClassicalRegister(circuit.num_qubits)  
427 +        circuit.add_register(measurement_cr)  
428 +        circuit.measure(qubit, measurement_cr)  
```

## Coverage Improvements

### HLL quantum program

Source file: https://github.com/Qiskit/qiskit-aqua/blob/stable/0.9/qiskit/aqua/algorithms/linear_solvers/hhl.py#L232

```
194    def construct_circuit(self, measurement: bool = False) -> QuantumCircuit:  
           ...  
229        if measurement:  
230            c = ClassicalRegister(1)  
231            qc.add_register(c)  
232 -          qc.measure(s, c)  
232 +          pass  
233            self._success_bit = c  
```

Test suite: https://github.com/Qiskit/qiskit-aqua/blob/stable/0.9/test/aqua/test_hhl.py#L110

```
66    @data([0, 1], [1, 0], [1, 0.1], [1, 1], [1, 10])  
67    def test_hhl_diagonal(self, vector):  
           ...  
109        self.log.debug('fidelity HHL to algebraic: %s', fidelity)  
110        self.log.debug('probability of result:     %s', hhl_result.probability_result)  
111 +      qc = algo.construct_circuit(True)   
112 +      result = execute(qc, backend = BasicAer.get_backend('qasm_simulator'), shots = 1000).result()   
113 +      counts = result.get_counts()   
114 +      self.assertTrue(len(counts) == 2)   
```

### VQC quantum program

Source file: https://github.com/Qiskit/qiskit-aqua/blob/stable/0.9/qiskit/aqua/algorithms/classifiers/vqc.py#L544

```
527    def get_optimal_vector(self):   
           ...    
539        else:    
540            c = ClassicalRegister(qc.width(), name='c')   
541            q = find_regs_by_name(qc, 'q')    
542            qc.add_register(c)   
543            qc.barrier(q)   
544 -          qc.measure(q, c)    
544 +          pass    
545            ret = self._quantum_instance.execute(qc)    
546            self._ret['min_vector'] = ret.get_counts(qc)    
```

Test file: https://github.com/Qiskit/qiskit-aqua/blob/stable/0.9/test/aqua/test_vqc.py#L157

```
140    def test_minibatching_gradient_free(self):    
           ...
156        self.log.debug(result['testing_accuracy'])    
157        self.assertAlmostEqual(result['testing_accuracy'], 0.3333333333333333)    
158 +      vector = vqc.get_optimal_vector()    
159 +      self.assertTrue(len(vector) == 4)    
```

## Assertion Improvements

### Shor quantum program

Test file: https://github.com/Qiskit/qiskit-aqua/blob/stable/0.9/test/aqua/test_shor.py#L32
```
32        def test_shor_factoring(self, n_v, backend, factors):    
             ...        
35           result_dict = shor.run(QuantumInstance(BasicAer.get_backend(backend), shots=1000))    
36           self.assertListEqual(result_dict['factors'][0], factors)    
37           self.assertTrue(result_dict["total_counts"] >= result_dict["successful_counts"])   
38 +         self.assertTrue(result_dict["total_counts"] >= 55)    
39 +         self.assertTrue(result_dict["total_counts"] <= 75)   
40 +         self.assertTrue(result_dict["successful_counts"] >= 10)    
41 +         self.assertTrue(result_dict["successful_counts"] <= 25)    
```
