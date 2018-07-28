# LINE
LINE: Performance and Reliability Analysis Engine.

Current version: 2.0.0-BETA1 (BSD-3 License)

URL: https://github.com/line-solver/line

LINE is a tool for performance and reliability analysis of complex systems based on queueing theory and stochastic modeling. Systems may either represent software applications, business processes, computer networks, or else. LINE transforms a high-level system model into one or more stochastic models, typically extended queueing networks, that are subsequently analyzed using either numerical algorithms or simulation. Using LINE, it is possible to analyze high-level model descriptions using a variety of solvers, ranging from simulation-based solvers like JMT and LQSIM, to CTMC, fluid and approximate mean-value analysis (AMVA) based solvers.

To get started, clone the repository or download the latest release from the [Releases](https://github.com/line-solver/line/releases) page. Unzip the file in the chosen installation folder.

Start MATLAB and change the active directory to the installation folder. Then add all LINE folders to the path
```
addpath(genpath(pwd))
```
Finally, run the LINE demonstrators using
```
allExamples
```
Guidance on how to use the engine is provided in the [LINE Manual](https://github.com/line-solver/line/raw/master/doc/LINE.pdf).
