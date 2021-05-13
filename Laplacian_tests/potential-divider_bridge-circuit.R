library(igraph)

# ------------------------------------------------------------------------------
# simple potential divider
# ------------------------------------------------------------------------------

to <- c(1,2)
from <- c(2,1)
weight <-c(1,0.5)

Edges <- data.frame(to = to, from = from, weight = weight)
the_graph <- graph_from_data_frame(Edges, directed = FALSE)
L <- laplacian_matrix(the_graph, weights = weight)
L[2,2] <- L[2,2] +0.1

q <- matrix(c(1,-1), ncol = 1)

p <- solve(L, q)

(p[to,] - p[from,])*weight

# ------------------------------------------------------------------------------
# bridge circuit
# ------------------------------------------------------------------------------

from <- c(1,1,2,2,3)
to <- c(2,3,3,4,4)
weight <-c(1, 0.5, 1, 0.5, 1)

# inc <- matrix(c(-1, -1, 0, 0, 0,
#                 1, 0, -1, -1, 0,
#                 0, 1, 1, 0, -1,
#                 0, 0, 0, 1, 1), ncol = 5, byrow = TRUE)


Verts <- data.frame(label = c(1,2,3,4))
Edges <- data.frame(to = to, from = from, weight = weight)

inc <- matrix(rep(0,nrow(Edges)*nrow(Verts)), ncol = nrow(Verts))
for(i in 1:nrow(Edges)){
  inc[i,Edges$from[i]] <- -1
  inc[i,Edges$to[i]] <- 1
}


the_graph <- graph_from_data_frame(Edges, vertices = Verts, directed = FALSE)
L <- laplacian_matrix(the_graph, weights = weight)
L[4,4] <- L[4,4] + 0.1
what <- as.matrix(L)


L2 <- t(inc) %*% diag(weight) %*% inc
L2[4,4] <- L2[4,4] + 0.1


q <- matrix(c(1, 0, 0, -1), ncol = 1)


p <- solve(L, q)
p2 <- solve(L2, q)

p[1,] - p[4,]
p2[1,] - p2[4,]

potential_diffs <- p[Edges$from,] - p[Edges$to,]
currents <- potential_diffs * Edges$weight

potential_diffs2 <- p2[Edges$from,] - p2[Edges$to,]
currents2 <- potential_diffs2 * Edges$weight



