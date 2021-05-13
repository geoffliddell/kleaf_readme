library(igraph)


Sys.time() -> begin
a <- 1
b <- 1/8

n <- 10

C <- c(rep(1/a, (n-1)), rep(1/b, (n-1)))

# edges...

Vert <- matrix(c(1:n, n/2, rep(0,n), -0.5), nrow = n+1)
Edges <- data.frame(from = c(1:(n-1), n:2), to = c(2:n, rep(n+1, n-1) ), weight = C) # , weights = rep(1,(2*N_x*N_y - (N_x+N_y))))     


the_graph <- graph_from_data_frame(Edges, directed = FALSE)
# lo <- layout.norm(as.matrix(Vert))
# plot(the_graph, layout = lo, directed = FALSE, edge.arrow.size=0)


# solving
L <- laplacian_matrix(the_graph)
L[n+1,n+1] <- L[n+1,n+1] + 0.01

# Boundary conditions: 
# - current @ node 1 = +10
# - voltage @ node 11:19 = 0 => perturb the laplacian at all these points??
q <- matrix(rep(0, nrow(Vert)), ncol = 1)
q[1,] <- +10
q[(n+1),] <- -10

p <- SparseM::solve(L,q)

# series currents...
p_diffs <- p[c(-n, -(n+1)),] - p[c(-1,-(n+1)),]


Sys.time() -> finish
print(difftime(begin, finish, units = c("secs")))


# print(p_diffs)
# returns same values as RSpice implementation, so seems to be working fine!




