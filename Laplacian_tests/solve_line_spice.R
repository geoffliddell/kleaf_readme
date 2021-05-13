library(stringr)
library(RSpice)
# png("rm_demo_graph.png", width = 480, height = 300)
# par(mar = c(5,5,1,1))
# for(b in lseq(1,300, length.out = 10)){
Sys.time() -> begin

I <- 10

a <- 1
b <- 8

n <- 10



node1series <- 1:(n-1)
node2series <- 2:n

node1par <- 2:n
node2par <- n+1

# resistor netlist
resistors<- data.frame(element = paste(rep("R",2*(n-1)), 1:(2*(n-1)), sep = ""),
                       node1   = c(node1series,node1par),
                       node2   = c(node2series,rep(node2par,(n-1))),
                       value   = c(rep(a,(n-1)), rep(b,(n-1))) )

# voltage source definition
voltage_source <- data.frame( element = "I1",
                              node1   = n+1,
                              node2   = 1,
                              value   = I)

# make the whole
network <- rbind(voltage_source, resistors)
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


Sys.time() -> finish
print(difftime(begin, finish, units = c("secs")))

# par(new = TRUE)
# plot(current, pch = "", cex.lab = 2, xaxt='n', yaxt='n', ylab = "current", xlab = "node distance")
plot(current, pch = "", cex.lab = 2) #xaxt='n', yaxt='n', ylab = "current", xlab = "node distance")
lines(current)


# }
# dev.off()
