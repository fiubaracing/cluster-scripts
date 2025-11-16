#!/usr/bin/env python
# -*- coding: utf-8 -*-

import sys
import math

def find_product_factors(N):
    """
    Time complexity: O(N)

    Given a number N, finds three factors (n1, n2, n3) such that:
    1. n1 * n2 * n3 = N
    2. n1 >= n2 >= n3
    3. The smallest possible n1 is prioritized (to match 12 -> 3 2 2)
    """
    
    # Base cases
    if N == 0:
        return (0, 0, 0)
    if N == 1:
        return (1, 1, 1)

    # 1. Find n1.
    # n1 must be >= the cube root of N.
    # We iterate n1 UPWARDS from the cube root.
    # (Adding +2 to the upper range for safety with primes and rounding)
    n1_start = int(N**(1/3.0))
    if n1_start == 0: # Ensure n1_start is at least 1
        n1_start = 1

    for n1 in range(n1_start, N + 2):
        
        # If n1 is a factor of N
        if N % n1 == 0:
            # We have the first remaining product
            rem = N // n1
            
            # 2. Find n2.
            # n2 must be <= n1.
            # n2 must be >= the square root of 'rem' (since n2 >= n3)
            
            # We iterate n2 DOWNWARDS from min(n1, rem)
            n2_start = min(n1, rem)
            n2_end = int(rem**(1/2.0))
            
            # (Adding -1 to the end of the range to include n2_end)
            for n2 in range(n2_start, n2_end - 1, -1):
                
                # If n2 is 0, skip (only happens if rem=0)
                if n2 == 0:
                    continue
                
                # If n2 is a factor of the remainder
                if rem % n2 == 0:
                    n3 = rem // n2
                    
                    # 3. Check the final constraint
                    # n1 >= n2 (guaranteed by n2_start)
                    # n2 >= n3 (needs verification)
                    if n2 >= n3:
                        # Found. Since we iterate n1 upwards,
                        # this is the solution with the smallest n1.
                        return (n1, n2, n3)
                        
    # Fallback (should not be reached if N > 0)
    return (N, 1, 1)

def main():
    # 1. Check if an argument was passed
    if len(sys.argv) != 2:
        print(f"Usage: python {sys.argv[0]} <number>")
        sys.exit(1)
        
    # 2. Try to convert the argument to an integer
    try:
        number = int(sys.argv[1])
    except ValueError:
        print("Error: The argument must be an integer.")
        sys.exit(1)
        
    # 3. Validate that the number is not negative (the n1>=n2>=n3 logic
    #    gets complicated with negatives)
    if number < 0:
        print("Error: The script only handles positive numbers or zero.")
        sys.exit(1)

    # 4. Find the factors
    n1, n2, n3 = find_product_factors(number)
    
    # 5. Print the result in the requested format
    print(f"({n1} {n2} {n3})")

if __name__ == "__main__":
    main()