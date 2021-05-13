# kleaf_readme

# Simulating damages to leaf hydraulic network

## Contents

1. Testing using the Laplacian to solve resistor mesh toy problems
2. Description of applying damage to the k_leaf model using RSpice
- Overall process
- Choosing damage locations
- Description of how edges were removed network
- Bugs remaining
- Rshunt
- Visualising the currents
- Leakage at the cut boundary

## Overall Process

Damages represented by circles. line-segment-in-circle function is in "functions/stackedVectorFunctions.R" . Summary:


>1.  Import vein network (nodes and edges) + estimated model parameters from "simul_abc.R"
>2.  Define damage centre and radius
>
>3.  Start `AmendNetwork`:
>>	- `circleLine_indicator`: returns indicator whether an edge is inside/outside/intersecting the circle)
>>	- `circleLine_intersection`: returns modified edges (if edge is inside it is removed and if it intersects, the intersection point is calculated)
>>	- Create new node_IDs for any cut ends produced
>4. End `AmendNetwork` (return damagedNetwork)
>
>5. Start `model_Kleaf` (input: damagedNetwork)
>>	- Form netlist for spice circuit simulation **note: added ".options rshunt = 1e10", ".options savecurrents"** (discussed later)
>>	- `runspice()` executes the simulation, followed by `spiceCommand('print all')` which returns all currents and voltages form ngspice
>6. End model_Kleaf (return `output[[1]]` = Kleaf and `output[[2]][[1]]` = Currents)
>
>7. Plot the graph with edge colour corresponding to Currents
>
>8. If damage is 'successive':
>>	- Rename the nodes to form a continuous sequence again (possibly not the best way of doing this!)
>>	- set `damagedNetwork[[nodes]]` and `damagedNetwork[[edges]]` as the input to next iteration and goto (2.)
>9.  Else goto (2.)
>10.  End


## (2.) Defining damage centre and radius (generating samples)

In the scripts ending "\_representative", the radius was chosen to be negligible (e.g. 5 pixels), and locations were chosen manually. To simplify calculating the co-ordinates they were 
chosen to be at midvein nodes from the graph, e.g. *Fig 1-1*.

![Figure 1-1](https://github.com/geoffliddell/k_leaf/blob/main/docs_damage/picking_representative_IDs.png) 

*Figure 1-1*

Alternatively, could sample across a grid, or at random. For the grid, this was done with `sample_grid()` described in "functions/sample_grid.R" and for random damage locations
this was done with the following code:

```
# random sample
set.seed(radius_idx)
sample_centres <- coordinates(spsample(Polygon(concaveman(n_vec)), xpmt$N_centres, type = "random"))
```

This could be done with \[x,y] = \[runif(n, miny,maxy), runif(n, minx, maxx)] then applying point.in.polygon() to discard points outside the leaf boundary, but the spsample function
also has the option of sampling along the leaf boundary easily by replacing "Polygon(concaveman(n_vec))" with "Line(concaveman(n_vec))", which might also be of interest.

## (3.) AmendNetwork

\[Note: after some confusion over how to correctly use dataframes, this was done after converting the dataframes to matrices! In the future may change this to reduce clutter 
 as well as avoid problems with carrying node_IDs through consistently. (see 'Renaming node_IDs').

### `circleLine_indicator`

Location of edges with respect to the circle of damage is identified by a.) distance of the two endpoints from the circle centre and b.) the discriminant of the solution for the 
intersection of an infinite line with a circle and c.) the dot product between the vector from the first endpoint to the centre (***dr***) and the unit vector along the line segment 
(***t***). 5 cases are distinguished, but the case where the the segment is a tangent is ignored for simplicity (as in *Fig 1-2*) and a "tangent tolerance" is introduced, so that 
nodes are not generated too close to each other.

1. Both endpoints are inside the radius  -->  the segment is removed
2. One endpoint is inside and the other is outside  -->  one endpoint is moved to the intersection and given a new node_ID
3. Both endpoints are outside [and] discriminant <= 0  -->  segment is not affected
4. Both endpoints are outside [and] discriminant <= 0 [and] (***t*** < 0 [or] ***t*** > ***dr***) -->  segment is not affected
5. Both endpoints are outside [and] discriminant > 0 [and] 0 < ***t*** < ***dr***]  --> segment intersect the circle twice. Edge is split into 2 and 2 new endpoints are created


![Figure 1-2](https://github.com/geoffliddell/k_leaf/blob/main/docs_damage/CircleLineIntersection_700.gif)

*Figure 1-2: demonstrating the cases that can be distinguished by the discriminant. left shows discriminant < 0; in the 
centre discriminant = 0; on the right discriminant > 0. discriminant = 0 case is lumped with discriminant > 0.[^2]*

### `circleLine_intersection`

\[Insert vector algebra here!]

### Renaming node_IDs

It was necessary to remove gaps in the sequence of IDs that occurred because of missing nodes as model_Kleaf needs a continuous sequence to avoid the case where nrow(nodes) might end up larger than max(nodes$node_ID). Would need to change this if it became necessary to identify exact edges that are damaged when doing 'successive' damages. 

## Bugs!

1. For more detailed networks (e.g. "CR" or "VL") there are some edges which produce errors inside function "getMesophyll_amended": when the voronoi polygon's are being calculated, a polygon may be missing, which seems to be caused by a duplicate edge in the leaf graph. Still investigating how this could occur.

2. Doing multiple damages (with no leakage at the cut) produces an increase in overall conductance when the damages are overlapping, which is not expected.

##  (5.) Changes to `model_Kleaf` function

Some options were added including "rshunt" and "savecurrents".

### rshunt

This was inlcuded as a workaround for the problem of edges becoming isolated after the damage was applied. This was needed because of the syntax required by *ngspice* used for the circuit 
simulation, which will not allow a circuit in the form in *Fig. 1-3 b)* which will result in an error, this behaviour is described in several places, for example[^1]. There were two possible 
fixes that could be made: either by discarding the isolated edges, or making the circuit of a compatible but equivalent form. The first option would require manipulating objects which
have a large number of attributes, which might result in an unpredictable output if the methods are not understand perfectly \[Note: read also lack of confidence in using the 
methods/functions in packages 'igraph' and 'rgeos'! as seen in `getMesophyll_amended.R`).] 


![Figure 1-3](https://github.com/geoffliddell/k_leaf/blob/main/docs_damage/Rshunt_aid.png)

*Figure 1-3: Demonstrating how rshunt joins isolated edges back to the circuit. a) shows a simplified circuit representing the leaf, horizontal
resistors are xylem resistances and vertical resistors represent outside of xylem resistance (mesophyll, stomata, atmosphere). b) A damage could be applied that isolates one of the resistors, 
so that the circuit cannot be interpreted by ngspice. c) the red resistors represent 'rshunt'. Since they have large resistance, they have little effect on the currents throught the
network, but the isolated resistor is now connected, with zero current flowing through. d) A situation where this might occur, with the circle representing a damage.*


For the second option there is a simple approximation that can be used. SPICE has a built in option "rshunt" (a shunt resistor is simply one that provides a path for current from one 
point to another in a circuit). The option adds a resistor at every node in the circuit to 'ground' i.e. a common point with zero volt potential. These are given a very high resistance 
compared to the rest of the circuit so that effectively zero current to pass through. In the simulations run, this was chosen as the default `rshunt = 1e10` since the mesophyll resistances
measured are quite small (*table 1*), details are in /Low_Rmeso directory. If it happened that the mesophyll resistances were of order close to that of rshunt then this may cause a problem.

| Species   | range(Rvein)               | range(Rmeso)                |
| ----------|---------------             |---------------              |
| SS        | 2.66245e-12 , 0.0002999929 |  2.736996e-12 , 2.952234e-08|
| BB        |2.585838e-05 , 6.586091     |  3.517764e-06 , 0.02194931  |


### savecurrents

The currents were visualised by setting the color proportional to current, but keeping the edge widths proportional to measured width. **A problem with some edges not showing on the graphs was due to
current values less than zero**, which was fixed by using the absolute value instead. Some currents in the circuit are measured to be very small. In order to check that these were not 
a product of numerical ptoblems, the voltage at the petiole (previously set to 99.5e-6) was changed to 99.5e-1, leaving resistance calculations unaffected. The small currents changed proportionally (0.03% deviation from what was expected in the smallest current) implying there are unlikely to be numerical problems with these values. \[NOTE: I don't think this looks like a problem?]

| Voltage   | range(I_vein)              | Expected                |
| ----------|---------------             |----------               |
| 99.5e-6   | 6.91322e-18, 0.00605167    | -                       |
| 99.5e-1   | 6.9152e-13, 605.167        |  6.91322e-13, 605.167   |

Some simple scenarios to test that the model was working correctly: when the currents were plotted for BB and very small damages were applied to the central major vein, current appeared to be deflected to the parallel major veins as in  *Fig 1-4*.

![Figure 1-4](https://github.com/geoffliddell/k_leaf/blob/main/docs_damage/BB_midvein.png)

*Figure 1-4: The larger orange markers indicate where veins have been cut. An area where the visualisation could be improved is that for most of the leaf the currents are very small and so variations are difficult to see. \[EDIT: Taking logs improved things. Next need to work out how to keep the colour bins from the original graph in all the other ones.]*




## Leakage at the cut boundary

Used existing 'mesophyll resistors' to include leakage at the cut edge. Since mesophyll resistances are calculated for every midvein node, there was no need to calculate them again, but since there was a surface-area/volume threshold on the veins below which the mesophyll resistors were discarded, an OR statement was added so that if an edge has a 'cut_end' then the mesophyll resistor is also inlcuded. Also introduced a variable 'rho_cut' so that the mesophyll resistance at the cut edge can be varied. (rho being symbol for resistivity **This method would not capture the extra leakage if no veins are cut**.

<img src="https://render.githubusercontent.com/render/math?math=R_{cut} = \rho_{cut} R_{meso}">

As 'rho_cut' gets very large there is effectively no leakage at the boundary and overall leaf conductance tends to a value below that of the original leaf. At low 'rho_cut' all the current is pulled through the damaged region and results in overall leaf resistance lower than the original leaf, with a transition region. An example for the leaf "BB", with a damage near the petiole is shown in *Fig. 1-5*. 

![Figure 1-4](https://github.com/geoffliddell/k_leaf/blob/main/docs_damage/rho_cuts_test.png)

*Figure 1-5: mesophyll resistance left as is (see section on 'rshunt'). varying water leakage at the boundary, with a damage shown in the bottom right of figure 1-4. The leaf conductance with no damage applied was 62.8 mmol s^-1 MPa^-1 \[NOTE: needs a title!]*




## Bibliography

[^1]: Dennis Crunkilton, Alejandro Gamero Divasto, Tony R. Kuphaldt, 1996-present. "Lessons in Electric Circuits Vol. 5." url: https://www.allaboutcircuits.com/textbook/reference/chpt-7/spice-quirks/

[^2]:  Weisstein, Eric W. "Circle-Line Intersection." From MathWorld--A Wolfram Web Resource. https://mathworld.wolfram.com/Circle-LineIntersection.html

