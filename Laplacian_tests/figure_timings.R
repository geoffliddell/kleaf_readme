# figure... plot solveing time for different lengths of line...
graphics.off()
source("prep/importFunctions.R")
len <- 15
Nt <- round(lseq(from = 10, to = 25000, length.out =len))


I <- 10

a <- 1
b <- 50

tmp <- rep(NA, len)
t <- data.frame(t_R = tmp, t_n = tmp, r_R = tmp, r_n = tmp, diff = tmp)

i <- 0
for (n in Nt) 
  {
  i <- i+1
  
  Sys.time() -> begin1
  
  ##############################################################################
  # solve with RSpice
  ##############################################################################
  
  node1series <- 1:(n-1)
  node2series <- 2:n
  
  node1par <- 2:n
  node2par <- n+1
  
  # resistor netlist
  resistors<- data.frame(element = paste(rep("R",2*(n-1)), 1:(2*(n-1)), sep = ""),
                         node1   = c(node1series,node1par),
                         node2   = c(node2series,rep(node2par,(n-1))),
                         value   = c(rep(a,(n-1)), rep(b,(n-1))) )
  
  # current source definition
  current_source <- data.frame( element = "I1",
                                node1   = n+1,
                                node2   = 1,
                                value   = I)
  
  # make the whole
  network <- rbind(current_source, resistors)
  network <- paste0(network$element," ",network$node1," ",network$node2, " ", network$value)
  
  # format for RSpice
  netlist<-as.vector(c("spp name", 
                       ".options savecurrents",
                       network, 
                       ".op",
                       ".end")) # adding op to do a dc operating point analysis 
  
  
  circ <- circuitLoad(netlist)
  
  
  runSpice()
  
  whole <- capture.output(spiceCommand("print all"))
  
  
  currents <- str_split_fixed(str_split_fixed(whole, "@", 2)[,2], " = ", 2)
  current_val <- as.numeric(currents[,2])
  current_id <- currents[!is.na(current_val),1]
  current_val <- current_val[!is.na(current_val)]
  
  current <- current_val[2:n]
  
  voltage1 <- capture.output(spiceCommand("print v(1)"))
  v1<- str_split_fixed(voltage1, "= ", 2)
  v1<- as.numeric(v1[1,2])
  
  voltage2 <- capture.output(spiceCommand(paste0("print v(", n+1, ")")))
  v2<- str_split_fixed(voltage2, "= ", 2)
  v2<- as.numeric(v2[1,2])
  
  t$r_R[i] <- (v1 - v2)/I
  
  
  Sys.time() -> finish1
  
  ##############################################################################
  # solve with RSpice
  ##############################################################################
  
  Sys.time() -> begin2
  
  
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
  
  # resistance
  t$r_n[i] <- (p[1,])/I
  
  Sys.time() -> finish2
  
  # total difference between the results
  diff <- sum(abs(p_diffs - current))
  
  
  # add to results
  t$t_R[i] <- difftime(finish1, begin1)
  t$t_n[i] <- difftime(finish2, begin2)
  t$diff[i] <- diff
  
}



N <- matrix(rep(Nt, 2), ncol = 2)
time <- as.matrix(t[, c(1,2)])
matplot(N,time, xlab = "number of nodes", ylab = "time (s)", pch = 20, col = 'black')
lines(N[,1],time[,1], col = 'red')
lines(N[,2],time[,2], col = 'green')

plot(Nt, t$diff)

