library(igraph)

a <- 1
b <- 1

n <- 10

R <- c(rep(a, (n-1)), rep(b, (n-1)))



# edges...
Vert <- matrix(c(1:n, n:2, rep(0,n), rep(-0.5,(n-1))), nrow = 2*n-1)
Edges <- data.frame(from = c(1:(n-1), n:2), to = c(2:n, (n+1):(2*n-1)), weights = R) # , weights = rep(1,(2*N_x*N_y - (N_x+N_y))))     


the_graph <- graph_from_data_frame(Edges, directed = FALSE)
lo <- layout.norm(as.matrix(Vert))
plot(the_graph, layout = lo, directed = FALSE, edge.arrow.size=0)


# solving
L <- laplacian_matrix(the_graph)
for(i in (n+1):(2*n-1)){
  L[i,i] <- L[i,i] + 0.1
}

# Boundary conditions: 
# - current @ node 1 = +10
# - voltage @ node 11:19 = 0 => perturb the laplacian at all these points??
p <- matrix(rep(-1, nrow(Vert)), ncol = 1)
p[1,] <- +10
p[(n+1):(2*n-1),] <- -1

q <- SparseM::solve(L,p)


# p <- matrix(rep(0, nrow(Vert)), ncol = 1)
# p[12,] <- 1
# p[68,] <- 0
# q <- solve(L,p)

print(R)

