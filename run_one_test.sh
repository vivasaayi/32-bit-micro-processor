make -C tools
python3 c_test_runner.py . --test 1_basic_test --enhanced
python3 c_test_runner.py . --test 2_string_test --enhanced
python3 c_test_runner.py . --test 3_algorithm_demo --enhanced
python3 c_test_runner.py . --test 4_basic_algorithms --enhanced
# python3 c_test_runner.py . --test 5_comprehensive_dsa_test --enhanced

for f in test_programs/c/compiler_assembler_tests/*.c; do
  name=$(basename "$f" .c)
  python3 c_test_runner.py test_programs/c/compiler_assembler_tests --test "$name" --enhanced
done
