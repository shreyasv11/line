LP algorithm for approximating the stationary distribution for SRBM

Main function: Alg.m

Computes an approximation to the stationary distribution of an SRBM with data (M,G,R), where M is the drift vector, G is the covariance matrix, and
R is the reflection matrix. 

For this, the algorithm generates an approximating grid with n points on each coordinate, and uses polinomials of degree up to m to approximate the
functional space of test functions.

 imput:  - n (state space approximation parameter, number of
           points on the approximating grid for each coordinate)
         - m (functional space approximation parameter, degree of
           polynomials on set of basis functions)
         - d (dimension of the SRBM)
         - G (Covariance matrix for SRBM)
         - R (Reflextion matrix for SRBM)
         - M (Drift vector for SRBM)
         - mu (state space approximation parameter, vector that
           determines the spacing on the approximating grid, check
           ExpGrid.m)

For mu one may try using the value mu=-2*inv(R)*M. Also notice that the current implementation uses loose bounds for imposing tightness conditions.
Next version will use the bounds on the paper.
 
 output - P (set of points on the approximating grid)
        - pd (interior stationary distribution for SRBM)
        - vd (boundary stationary distribution for SRBM)
        - u (optimal objective function for approximating LP)
        - exitflag (optimization status)
        - K (bounds used for imposing tightness)

One may also try running Rungraph.m

This routine calls Alg.m to solve for the stationary distribution, then computes moments estimations, and graphs the marginal densities for each coordinate.

EXAMPLE:

type the following on the MATLAB command line:

R = [1 0 ; -1 1];
G = [1 0 ; 0 1];
M = [-1 0]; 

then execute the following command:

[EM P pd pv] = Rungraph(50,5,G,M,R,1);

you'll get fisrt moment estimations on EM, and graphs for the marginal densities.



