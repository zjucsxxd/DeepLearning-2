#' @title Initialize a Restricted Bolzman Machine
#' @description Creates a Restricted Bolzman Machine (RBM), precisely a \code{RestrictedBolzmannMachine} object, with the given specifications. 
#' It is typically stacked in a \code{\link{DeepBeliefNet}}.
#' @param input,output \code{\link{Layer}} objects
#' @param weights optional starting weights. If \code{NULL}, weights will be initialized to 0
#' @return an object of class \code{RestrictedBolzmannMachine} containing the following elements:
#' \itemize{
#' \item{input,output}{\code{\link{Layer}}s}
#' \item{weights, weights.breaks}{as input}
#' \item{pretrained}{boolean switch to mark the state of the layer. \code{FALSE} just after initialization.}
#' }
#' @section Copying/Cloning:
#' For performance purposes, the weights are stored in an environment. This means that when you copy the RestrictedBolzmannMachine with an assignment, you do not copy the weights
#' and any modification you make to the new object will be propagated to the original one, and reciprocally.
#' Use \code{\link{clone}} to control this and make a copy of the weights whenever you need it. Note that all the functions defined in the package do this by default.
#' @seealso \code{\link{DeepBeliefNet}}, which makes use of RestrictedBolzmannMachine objects, \code{\link{Layer}}.
#' @examples
#' rbm <- rbm(Layer(784, "continuous"), Layer(1000, "binary"))
#' print(rbm)
#' methods(class="RestrictedBolzmannMachine")
#' @export
RestrictedBolzmannMachine <- function(input, output, weights = NULL) {
	if (!is(input, "Layer") || !is(output, "Layer")) {
		stop("input and output must be Layer objects.")
	}
	weights.env <- new.env(size=2)
	weights.breaks <- computeRbmBreaks(input, output)
	assign("breaks", weights.breaks, pos=weights.env) # Also store all the breaks there
	if (is.null(weights)) {
		assign("weights", numeric(tail(weights.breaks, n=1)), pos=weights.env) # Set all weights to 0
	}
	else if (length(weights) == tail(weights.breaks, n=1) && is.numeric(weights) && is.vector(weights)) {
		assign("weights", weights, pos=weights.env)
	}
	else {
		stop("Invalid weights supplied. Please provide a vector of numeric weights of compatible size (input + output + input * output).")
	}
	return(RestrictedBolzmannMachineFromWeightsEnv(input, output, weights.env, weights.breaks))
}

# Private constructor - re-use weights.env from DBN
RestrictedBolzmannMachineFromWeightsEnv <- function(input, output, weights.env, weights.breaks) {
	rbm <- list(
		input = input,
		output = output,
		weights.env = weights.env,
		weights.breaks = weights.breaks,
		# Status
		pretrained = FALSE
	)
	class(rbm) <- "RestrictedBolzmannMachine"
	return(rbm)
}

# Private function that computes the weight breaks for a RBM from the input and output layers
computeRbmBreaks <- function(input, output) {
	as.integer(cumsum(c(0, input$size, input$size * output$size, output$size)))
}


getWeightsFromEnv <- function(weights.env, which = c("all", "b", "w", "c", "bw", "wc"), breaks = weights.env$breaks, weights = weights.env$weights) {
	which <- tolower(which)
	which <- match.arg(which)
	if (which == "all")
		return(weights[(breaks[1] + 1):breaks[4]])
	if (which == "bw")
		return(weights[(breaks[1] + 1):breaks[3]])
	if (which == "wc")
		return(weights[(breaks[2] + 1):breaks[4]])
	if (which == "b")
		return(weights[(breaks[1] + 1):breaks[2]])
	if (which == "w")
		return(weights[(breaks[2] + 1):breaks[3]])
	if (which == "c")
		return(weights[(breaks[3] + 1):breaks[4]])
	stop("Should have returned earlier in getWeightsFromEnv")
}
